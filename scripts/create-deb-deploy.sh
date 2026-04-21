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

usage() {
  cat <<'EOF'
Usage: create-deb-deploy.sh [--with-headers | --without-headers]

Options:
  --with-headers     Keep installed header files in the generated .deb.
  --without-headers  Exclude installed *.h, *.hpp, and *.tpp files from the .deb.
  -h, --help         Show this help message.

Environment:
  INCLUDE_HEADERS=1|0   Default header inclusion mode when no CLI flag is passed.
  REUSE_BUILD=auto|1|0  Reuse an existing build directory when possible. Defaults to auto.
EOF
}

INCLUDE_HEADERS="${INCLUDE_HEADERS:-1}"
REUSE_BUILD="${REUSE_BUILD:-auto}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-headers)
      INCLUDE_HEADERS="1"
      shift
      ;;
    --without-headers)
      INCLUDE_HEADERS="0"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument '$1'"
      usage
      exit 1
      ;;
  esac
done

case "${INCLUDE_HEADERS}" in
  0|1)
    ;;
  *)
    echo "ERROR: INCLUDE_HEADERS must be 0 or 1, got '${INCLUDE_HEADERS}'"
    exit 1
    ;;
esac

case "${REUSE_BUILD}" in
  auto|0|1)
    ;;
  *)
    echo "ERROR: REUSE_BUILD must be auto, 0, or 1, got '${REUSE_BUILD}'"
    exit 1
    ;;
esac

VERSION="${VERSION_OVERRIDE:-0.0.0-local}"
DEB_CONTROL_VERSION="$(echo "${VERSION}" | sed -E 's/^[^0-9]*//')"
if [[ -z "${DEB_CONTROL_VERSION}" ]]; then
  echo "ERROR: VERSION '${VERSION}' cannot be converted to a Debian control version"
  exit 1
fi

PACKAGE_NAME="${PACKAGE_NAME:-dls2}"
MAINTAINER="${DEB_MAINTAINER:-Michele Pestarino <michele.pestarino@iit.it>}"
PACKAGE_DESCRIPTION="${DEB_DESCRIPTION:-DLS2 runtime package}"
DEB_DEPENDS="${DEB_DEPENDS:-python3, python3-psutil, libyaml-cpp0.8, libtinyxml2-10, libgtk-3-0t64 | libgtk-3-0, libcairo2, libglib2.0-0t64 | libglib2.0-0, libboost-filesystem1.83.0, libconsole-bridge1.0, libcap2-bin}"

DEB_NAME="${PACKAGE_NAME}_${VERSION}_amd64.deb"
DEB_PATH="${ROOT_DIR}/${DEB_NAME}"
JOBS="${JOBS:-4}"
LIVE_BUILD_OUTPUT="${LIVE_BUILD_OUTPUT:-0}"
BUILD_VERBOSE="${BUILD_VERBOSE:-0}"
CLEAN_BUILD="${CLEAN_BUILD:-0}"
CMAKE_ARGS="${CMAKE_ARGS:-}"
BUILD_ARGS="${BUILD_ARGS:--j${JOBS}}"

mkdir -p "${ART_DIR}"
rm -f "${DEB_PATH}" "${ART_DIR}/pkg_files.txt" "${BUILD_LOG}"

for required_dir in dls2 robotlib gluecode; do
  if [[ ! -f "${ROOT_DIR}/${required_dir}/CMakeLists.txt" ]]; then
    echo "ERROR: missing ${required_dir}/CMakeLists.txt under ${ROOT_DIR}."
    echo "Hint: submodules are not checked out on this runner."
    exit 1
  fi
done

run_pipeline() {
  local build_dir="${ROOT_DIR}/build"
  local stage_dir="${ROOT_DIR}/.deb_stage"
  local reuse_existing_build="0"

  if [[ "${CLEAN_BUILD}" == "1" ]]; then
    rm -rf "${build_dir}"
  fi
  rm -rf "${stage_dir}"

  # shellcheck disable=SC2206
  local cmake_user_args=(${CMAKE_ARGS})
  # shellcheck disable=SC2206
  local build_user_args=(${BUILD_ARGS})

  if [[ "${CLEAN_BUILD}" != "1" && -f "${build_dir}/CMakeCache.txt" ]]; then
    case "${REUSE_BUILD}" in
      auto|1)
        reuse_existing_build="1"
        ;;
      0)
        ;;
    esac
  fi

  if [[ "${REUSE_BUILD}" == "1" && "${reuse_existing_build}" != "1" ]]; then
    echo "ERROR: REUSE_BUILD=1 was requested, but no reusable build cache was found in ${build_dir}."
    echo "Hint: provide a prebuilt build/ artifact or set REUSE_BUILD=auto or 0."
    return 1
  fi

  if [[ "${reuse_existing_build}" == "1" ]]; then
    echo "[build] reusing existing build directory: ${build_dir}"
  else
    echo "[build] configuring and compiling in: ${build_dir}"
    cmake -S "${ROOT_DIR}" -B "${build_dir}" -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/ \
      "${cmake_user_args[@]}"

    if [[ "${BUILD_VERBOSE}" == "1" ]]; then
      cmake --build "${build_dir}" -- "${build_user_args[@]}" --verbose
    else
      cmake --build "${build_dir}" -- "${build_user_args[@]}"
    fi
  fi

  DESTDIR="${stage_dir}" cmake --install "${build_dir}"

  if [[ "${INCLUDE_HEADERS}" == "0" && -d "${stage_dir}/usr/include" ]]; then
    find "${stage_dir}/usr/include" -type f \
      \( -name '*.h' -o -name '*.hpp' -o -name '*.tpp' \) \
      -delete
    find "${stage_dir}/usr/include" -depth -type d -empty -delete
  fi

  strip "${stage_dir}/usr/bin/dls2/dynamic_legged_systems_framework" || true
  strip "${stage_dir}/usr/bin/dls2/child_process_launcher" || true
  strip "${stage_dir}/usr/lib/librobotlib.so" || true

  if [[ -f "${stage_dir}/usr/bin/dls" ]]; then
    awk '
      NR == 1 {
        print
        print "export LD_LIBRARY_PATH=\"/opt/ros/jazzy/lib/x86_64-linux-gnu:/usr/local/lib:/usr/lib:/usr/lib/dls2:/usr/lib/dls2/motion_generators:/usr/lib/dls2/controllers:/usr/lib/dls2/estimators:/usr/lib/dls2/messages:${LD_LIBRARY_PATH:-}\""
        print "export DLS_SERVERS_PATH=\"${DLS_SERVERS_PATH:-/usr/include/dls2/util/messaging/servers.yaml}\""
        print "export DLS_SAFETY_LAYER_PATH=\"${DLS_SAFETY_LAYER_PATH:-/usr/include/dls2/supervisor/data/safety_layer.yaml}\""
        print "export DLS_SCHEDULER_PATH=\"${DLS_SCHEDULER_PATH:-/usr/include/dls2/schedulers}\""
        print "export GZ_SIM_RESOURCE_PATH=\"${GZ_SIM_RESOURCE_PATH:-/usr/local/share/dls-gazebo/worlds}\""
        next
      }
      /fastdds shm clean/ {
        print "command -v fastdds >/dev/null 2>&1 && fastdds shm clean > /dev/null 2>/dev/null || true"
        next
      }
      /dynamic_legged_systems_framework / {
        sub(/^[[:space:]]*/, "")
        print "exec " $0
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
  if [ -f /usr/bin/dls2/dynamic_legged_systems_framework ]; then
    setcap cap_sys_nice=eip /usr/bin/dls2/dynamic_legged_systems_framework || true
  fi
  if [ -f /usr/bin/dls2/child_process_launcher ]; then
    setcap cap_sys_nice=eip /usr/bin/dls2/child_process_launcher || true
  fi
fi

if command -v ldconfig >/dev/null 2>&1; then
  ldconfig || true
fi

exit 0
EOPOSTINST
  chmod 0755 "${stage_dir}/DEBIAN/postinst"

  if ! find "${stage_dir}" -mindepth 1 \
    ! -path "${stage_dir}/DEBIAN" \
    ! -path "${stage_dir}/DEBIAN/*" \
    ! -path "${stage_dir}/etc" \
    ! -path "${stage_dir}/etc/profile.d" \
    ! -path "${stage_dir}/etc/profile.d/dls2.sh" \
    -print -quit | grep -q .; then
    echo "ERROR: staged package payload is empty."
    echo "Hint: cmake configure/build/install likely failed earlier, or the build cache points to a different source tree."
    return 1
  fi

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
echo "[build] include headers: ${INCLUDE_HEADERS}"
echo "[build] reuse build: ${REUSE_BUILD}"
if [[ "${LIVE_BUILD_OUTPUT}" == "1" ]]; then
  if run_pipeline > >(tee "${BUILD_LOG}") 2>&1; then
    rc=0
  else
    rc=$?
  fi
else
  if run_pipeline > "${BUILD_LOG}" 2>&1; then
    rc=0
  else
    rc=$?
  fi
fi

if [[ ${rc} -ne 0 ]]; then
  echo "ERROR: build/package failed. See ${BUILD_LOG}"
  tail -n 120 "${BUILD_LOG}" || true
  exit ${rc}
fi

if [[ ! -f "${DEB_PATH}" ]]; then
  echo "ERROR: .deb not created at ${DEB_PATH}"
  echo "See ${BUILD_LOG}"
  tail -n 120 "${BUILD_LOG}" || true
  exit 1
fi

echo "[build] OK: ${DEB_PATH}"
echo "${DEB_PATH}"
