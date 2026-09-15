cmake_minimum_required(VERSION 3.16.2)
project(dls2-barebone)

# Default to Release mode
if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/dls_message_paths.cmake")

if(NOT CMAKE_INSTALL_RPATH)
  set(CMAKE_INSTALL_RPATH "/opt/dls2/lib;/opt/dls2/hardwares/lib" CACHE STRING "RPATH for installed binaries" FORCE)
endif()

add_subdirectory(transport_interfaces)
add_subdirectory(dls_hal)
add_subdirectory(dls2)
add_subdirectory(robotlib)
add_subdirectory(pinocchio-gluecode)
add_subdirectory(visualizers/rviz_interface)

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/generate_ros2_messages.cmake")

# install setup_ros2_for_dls2.bash
install(FILES dls2_ros2_interface/ros2_ws/src/dls2_interface/scripts/setup_ros2_for_dls2.bash
  DESTINATION /usr/bin/dls2/scripts/
)
