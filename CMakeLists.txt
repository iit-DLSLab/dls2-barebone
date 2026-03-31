cmake_minimum_required(VERSION 3.16.2)
project(dls2-barebone)

# list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

# ==============================================================================
# Super Project Configuration
# ==============================================================================
# set(CPACK_DEB_COMPONENT_INSTALL ON)

# Default to Release mode
if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

# include(dls_include_paths)    # directories of global libraries
# include(mark_advanced)

# macro(conditional_deploy TARGET_NAME)
# 	set(DLS_DEPLOY_${TARGET_NAME} OFF
# 		CACHE BOOL "Whether to package ${TARGET_NAME}"
# 	)

# 	if(DLS_DEPLOY_${TARGET_NAME})
# 		add_subdirectory(${TARGET_NAME})
# 	endif()
# endmacro()

# ==============================================================================
# Main Framework
# ==============================================================================
set(DLS_MESSAGE_FOLDER ${CMAKE_SOURCE_DIR}/dls2/modules/messages)
add_subdirectory(dls2)
add_subdirectory(robotlib)
add_subdirectory(gluecode)