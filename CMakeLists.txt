cmake_minimum_required(VERSION 3.16.2)
project(dls2-barebone)

# Default to Release mode
if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

set(DLS_MESSAGE_FOLDER ${CMAKE_CURRENT_SOURCE_DIR}/transport_interfaces/transports/fastdds/dls2_msgs
  CACHE PATH "Path to the dls2_msgs folder"
)

if(NOT CMAKE_INSTALL_RPATH)
  set(CMAKE_INSTALL_RPATH "/opt/dls2/lib;/opt/dls2/hardwares/lib" CACHE STRING "RPATH for installed binaries" FORCE)
endif()

add_subdirectory(transport_interfaces)
add_subdirectory(dls_hal)
add_subdirectory(dls2)
add_subdirectory(robotlib)
add_subdirectory(pinocchio-gluecode)
add_subdirectory(visualizers/rviz_interface)

# generate ROS2 messages from IDL files each time CMake is run, to ensure they are always up to date with the IDL definitions
message(STATUS "Generating ROS2 messages from IDL files...")
set (DLS2_ROS2_INTERFACE_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/dls2_ros2_interface/ros2_ws/src)
set (DLS2_ROS2_INTERFACE_DIR ${DLS2_ROS2_INTERFACE_SRC_DIR}/dls2_interface)


# remove .msg files from the ROS2 interface src directory to avoid conflicts with the newly generated ones
file(GLOB DLS_MSG_FILES CONFIGURE_DEPENDS "${DLS2_ROS2_INTERFACE_DIR}/msg/*.msg")
foreach(msg_file IN LISTS DLS_MSG_FILES)
  file(REMOVE ${msg_file})
endforeach()

file(GLOB DLS_IDL_FILES CONFIGURE_DEPENDS "${DLS_MESSAGE_FOLDER}/idls/*.idl")
foreach(idl_file IN LISTS DLS_IDL_FILES)
  execute_process(
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${DLS2_ROS2_INTERFACE_DIR}/scripts ${DLS2_ROS2_INTERFACE_DIR}/scripts/idl_to_msg.py ${idl_file} -o ${DLS2_ROS2_INTERFACE_SRC_DIR}/
    WORKING_DIRECTORY ${DLS2_ROS2_INTERFACE_DIR}
    RESULT_VARIABLE result
  )
endforeach()

# install setup_ros2_for_dls2.bash
install(FILES dls2_ros2_interface/ros2_ws/src/dls2_interface/scripts/setup_ros2_for_dls2.bash
  DESTINATION /usr/bin/dls2/scripts/
)