cmake_minimum_required(VERSION 3.16.2)
project(dls2-barebone)

# Default to Release mode
if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

set(DLS_MESSAGE_FOLDER ${CMAKE_SOURCE_DIR}/dls2/modules/messages)
add_subdirectory(dls2)
add_subdirectory(robotlib)
add_subdirectory(gluecode)
add_subdirectory(visualizers/rviz_interface)