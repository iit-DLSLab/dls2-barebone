cmake_minimum_required(VERSION 3.16.2)
project(dls2-barebone)

# Default to Release mode
if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

set(DLS_MESSAGE_FOLDER ${CMAKE_CURRENT_SOURCE_DIR}/dls2/modules/messages)
add_subdirectory(dls2)
add_subdirectory(robotlib)
add_subdirectory(gluecode)
add_subdirectory(visualizers/rviz_interface)

# generate ROS2 messages from IDL files each time CMake is run, to ensure they are always up to date with the IDL definitions
message(STATUS "Generating ROS2 messages from IDL files...")
set (DLS2_ROS2_INTERFACE_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/dls2_ros2_interface/ros2_ws/src)
set (DLS2_ROS2_INTERFACE_DIR ${DLS2_ROS2_INTERFACE_SRC_DIR}/dls2_interface)
file(GLOB DLS_IDL_FILES CONFIGURE_DEPENDS "${DLS_MESSAGE_FOLDER}/idls/*.idl")
foreach(idl_file IN LISTS DLS_IDL_FILES)
  execute_process(
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${DLS2_ROS2_INTERFACE_DIR}/scripts ${DLS2_ROS2_INTERFACE_DIR}/scripts/idl_to_msg.py ${idl_file} -o ${DLS2_ROS2_INTERFACE_SRC_DIR}/
    WORKING_DIRECTORY ${DLS2_ROS2_INTERFACE_DIR}
    RESULT_VARIABLE result
  )
endforeach()