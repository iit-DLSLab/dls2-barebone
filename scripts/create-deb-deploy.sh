#!/usr/bin/env bash

if [ -z "${BASH_VERSION:-}" ]; then
  echo "ERROR: run this script with bash"
  exit 1
fi

set -euo pipefail

# -----------------------------------------------------------------------------
# Build + package script (deployment CI on runner host)
# Produces: dls2_<version>_amd64.deb at repo root.
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ART_DIR="${ROOT_DIR}/deb_pipeline_artifacts"
BUILD_LOG="${ART_DIR}/build.log"

VERSION="${VERSION_OVERRIDE:-0.0.0-local}"
DEB_CONTROL_VERSION="$(echo "${VERSION}" | sed -E 's/^[^0-9]*//')"
if [[ -z "${DEB_CONTROL_VERSION}" ]]; then
  echo "ERROR: VERSION '${VERSION}' cannot be converted to a Debian control version"
  exit 1
fi

PACKAGE_NAME="${PACKAGE_NAME:-dls2}"
MAINTAINER="${DEB_MAINTAINER:-Michele Pestarino <michele.pestarino@iit.it>}"
PACKAGE_DESCRIPTION="${DEB_DESCRIPTION:-DLS2 runtime package}"
DEB_DEPENDS="${DEB_DEPENDS:-python3, python3-psutil, libyaml-cpp0.8, libtinyxml2-10, libgtk-3-0, libcairo2, libglib2.0-0, libboost-filesystem1.83.0, libconsole-bridge1.0, libcap2-bin}"

DEB_NAME="${PACKAGE_NAME}_${VERSION}_amd64.deb"
DEB_PATH="${ROOT_DIR}/${DEB_NAME}"
JOBS="${JOBS:-4}"
LIVE_BUILD_OUTPUT="${LIVE_BUILD_OUTPUT:-0}"
BUILD_VERBOSE="${BUILD_VERBOSE:-0}"
CLEAN_BUILD="${CLEAN_BUILD:-0}"
CMAKE_ARGS="${CMAKE_ARGS:-}"
BUILD_ARGS="${BUILD_ARGS:--j${JOBS}}"

DEPLOY_FLAGS=(
  DLS_DEPLOY_gazebo_sim
  DLS_DEPLOY_pid_controller
  DLS_DEPLOY_periodic_generator
  DLS_DEPLOY_foot_traj_generator
  DLS_DEPLOY_gait_timer
  DLS_DEPLOY_terrain_estimator
  DLS_DEPLOY_trunk_controller
  DLS_DEPLOY_dls_keyboard
  DLS_DEPLOY_dls_gamepad
)

CMAKE_DEPLOY_ARGS=()
for flag in "${DEPLOY_FLAGS[@]}"; do
  value="${!flag:-ON}"
  CMAKE_DEPLOY_ARGS+=("-D${flag}=${value}")
done

mkdir -p "${ART_DIR}"
rm -f "${DEB_PATH}" "${ART_DIR}/pkg_files.txt" "${BUILD_LOG}"

run_pipeline() {
  local build_dir="${ROOT_DIR}/build"
  local stage_dir="${ROOT_DIR}/.deb_stage"

  cleanup_stage() {
    rm -rf "${stage_dir}" "${ROOT_DIR}/stage"
  }
  trap cleanup_stage EXIT

  if [[ "${CLEAN_BUILD}" == "1" ]]; then
    rm -rf "${build_dir}"
  fi
  rm -rf "${stage_dir}"

  # shellcheck disable=SC2206
  local cmake_user_args=(${CMAKE_ARGS})
  # shellcheck disable=SC2206
  local build_user_args=(${BUILD_ARGS})

  cmake -S "${ROOT_DIR}" -B "${build_dir}" -DCMAKE_BUILD_TYPE=Release \
    "${CMAKE_DEPLOY_ARGS[@]}" \
    "${cmake_user_args[@]}"

  if [[ "${BUILD_VERBOSE}" == "1" ]]; then
    cmake --build "${build_dir}" -- "${build_user_args[@]}" --verbose
  else
    cmake --build "${build_dir}" -- "${build_user_args[@]}"
  fi

  # Expected setcap warnings during staged install are tolerated.
  DESTDIR="${stage_dir}" cmake --install "${build_dir}" || true

  # Ensure robot description assets are packaged when available.
  if [[ -d "${ROOT_DIR}/robots/aliengo/aliengo-description" ]]; then
    mkdir -p "${stage_dir}/usr/include/aliengo_description"
    for dir in gazebo launch meshes robcogen robots rviz urdfs yarf foxglove default_postures kinematics; do
      if [[ -d "${ROOT_DIR}/robots/aliengo/aliengo-description/${dir}" ]]; then
        cp -a "${ROOT_DIR}/robots/aliengo/aliengo-description/${dir}" "${stage_dir}/usr/include/aliengo_description/"
      fi
    done
  fi

  strip "${stage_dir}/usr/bin/dls2/dynamic_legged_systems_framework" || true
  strip "${stage_dir}/usr/bin/dls2/child_process_launcher" || true
  strip "${stage_dir}/usr/lib/librobotlib.so" || true

  copy_into_stage() {
    local src="$1"
    local dst="${stage_dir}${src}"
    [[ -f "${src}" ]] || return 0
    mkdir -p "$(dirname "${dst}")"
    if [[ -L "${src}" ]]; then
      cp -a --no-dereference "${src}" "${dst}"
      local resolved
      resolved="$(readlink -f "${src}" || true)"
      if [[ -n "${resolved}" && "${resolved}" != "${src}" && -f "${resolved}" ]]; then
        copy_into_stage "${resolved}"
      fi
    else
      cp -a "${src}" "${dst}"
    fi
  }

  copy_ldd_closure() {
    local target="$1"
    [[ -e "${target}" ]] || return 0
    (ldd "${target}" 2>/dev/null || true) \
      | awk '
          /=> \// {print $3}
          /^\// {print $1}
        ' \
      | sort -u \
      | while IFS= read -r lib; do
          [[ -f "${lib}" ]] || continue
          case "$(basename "${lib}")" in
            libfastdds.so*|libfastcdr.so*|libfastdds_statistics_backend.so*|libpinocchio*.so*|libcoal.so*)
              continue
              ;;
            liburdfdom_model.so*|liburdfdom_model_state.so*|liburdfdom_sensor.so*|liburdfdom_world.so*)
              continue
              ;;
            libgz-math*.so*|libgz-utils*.so*)
              continue
              ;;
          esac
          case "${lib}" in
            /usr/local/lib/*)
              copy_into_stage "${lib}"
              ;;
            *)
              # Avoid bundling core distro libs from /lib and /usr/lib.
              ;;
          esac
        done
  }

  for p in /usr/local/lib/liburdfdom*.so*; do
    for f in $p; do
      [[ -e "${f}" ]] || continue
      copy_into_stage "${f}"
    done
  done

  if [[ -d "${stage_dir}/usr/lib/dls2" ]]; then
    while IFS= read -r sofile; do
      copy_ldd_closure "${sofile}"
    done < <(find "${stage_dir}/usr/lib/dls2" -type f -name '*.so*' | sort -u)
  fi
  if [[ -d "${stage_dir}/usr/bin/dls2" ]]; then
    while IFS= read -r exe; do
      copy_ldd_closure "${exe}"
    done < <(find "${stage_dir}/usr/bin/dls2" -type f -perm -111 | sort -u)
  fi
  if [[ -x "${stage_dir}/usr/bin/dls" ]]; then
    copy_ldd_closure "${stage_dir}/usr/bin/dls"
  fi

  # Patch launcher script:
  # - prioritize packaged runtime paths
  # - make FastDDS cleanup best-effort
  if [[ -f "${stage_dir}/usr/bin/dls" ]]; then
    awk '
      NR == 1 {
        print
        print "export LD_LIBRARY_PATH=\"/opt/ros/jazzy/lib/x86_64-linux-gnu:/usr/local/lib:/usr/lib:${LD_LIBRARY_PATH:-}\""
        next
      }
      /fastdds shm clean/ {
        print "command -v fastdds >/dev/null 2>&1 && fastdds shm clean > /dev/null 2>/dev/null || true"
        print
        next
      }
      { print }
    ' "${stage_dir}/usr/bin/dls" > "${stage_dir}/usr/bin/dls.tmp"
    mv "${stage_dir}/usr/bin/dls.tmp" "${stage_dir}/usr/bin/dls"
    chmod +x "${stage_dir}/usr/bin/dls"
  fi

  mkdir -p "${stage_dir}/etc/profile.d" "${stage_dir}/DEBIAN"
  cat > "${stage_dir}/etc/profile.d/dls2.sh" << "EOPROFILE"
#!/bin/sh
export GZ_SIM_RESOURCE_PATH="/usr/local/share/dls-gazebo/worlds"
export DLS_SERVERS_PATH="/usr/include/dls2/util/messaging/servers.yaml"
export DLS_SAFETY_LAYER_PATH="/usr/include/dls2/supervisor/data/safety_layer.yaml"
export DLS_SCHEDULER_PATH="/usr/include/dls2/schedulers"
EOPROFILE
  chmod +x "${stage_dir}/etc/profile.d/dls2.sh"

  cat > "${stage_dir}/DEBIAN/control" << EOCONTROL
Package: ${PACKAGE_NAME}
Version: ${DEB_CONTROL_VERSION}
Section: base
Priority: optional
Architecture: amd64
Maintainer: ${MAINTAINER}
Depends: ${DEB_DEPENDS}
Description: ${PACKAGE_DESCRIPTION}
EOCONTROL

  cat > "${stage_dir}/DEBIAN/postinst" << 'EOPOSTINST'
#!/bin/sh
set -e

if command -v setcap >/dev/null 2>&1; then
  setcap cap_sys_nice=eip /usr/bin/dls2/dynamic_legged_systems_framework || true
  setcap cap_sys_nice=eip /usr/bin/dls2/child_process_launcher || true
fi

if command -v ldconfig >/dev/null 2>&1; then
  ldconfig || true
fi

exit 0
EOPOSTINST
  chmod 0755 "${stage_dir}/DEBIAN/postinst"

  dpkg-deb --build "${stage_dir}" "${DEB_NAME}"

  dpkg-deb -c "${DEB_NAME}" \
    | awk '
        $1 !~ /^d/ {
          for (i = 1; i <= NF; i++) {
            if ($i ~ /^\.\//) {
              print $i
              break
            }
          }
        }
      ' \
    | sed -E 's#^\./#/#; s#/$##; s#//+#/#g' \
    | sort -u > "${ART_DIR}/pkg_files.txt"
}

echo "[build] building and packaging on host in ${ROOT_DIR}"
if [[ "${LIVE_BUILD_OUTPUT}" == "1" ]]; then
  if ! run_pipeline 2>&1 | tee "${BUILD_LOG}"; then
    echo "ERROR: build/package failed. See ${BUILD_LOG}"
    tail -n 120 "${BUILD_LOG}" || true
    exit 1
  fi
else
  if ! run_pipeline > "${BUILD_LOG}" 2>&1; then
    echo "ERROR: build/package failed. See ${BUILD_LOG}"
    tail -n 120 "${BUILD_LOG}" || true
    exit 1
  fi
fi

if [[ ! -f "${DEB_PATH}" ]]; then
  echo "ERROR: .deb not created at ${DEB_PATH}"
  echo "See ${BUILD_LOG}"
  tail -n 120 "${BUILD_LOG}" || true
  exit 1
fi

echo "[build] OK: ${DEB_PATH}"
echo "${DEB_PATH}"
