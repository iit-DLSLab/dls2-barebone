cmake_minimum_required(VERSION 3.15)   

project(rviz_interface)

add_compile_options("-std=c++2a")

find_package(fastcdr 2 REQUIRED)
find_package(fastdds 3 REQUIRED)
find_package(dls_messages REQUIRED)

if(DEFINED DLS_MESSAGE_FOLDER)
	list(APPEND CMAKE_MODULE_PATH "${DLS_MESSAGE_FOLDER}/cmake")
else()
	list(APPEND CMAKE_MODULE_PATH "/usr/include/dls_messages/cmake")
endif()
include(generate_msg_library)

# Set RELEASE as the default build type
if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

# use RPATH for the build tree
set(CMAKE_SKIP_BUILD_RPATH FALSE)

# the install RPATH is not used when building
set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)

# add to RPATH automatically determined paths for the install tree
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# ================================== Library config ==========================
macro(conditional_deploy_plugin TARGET_NAME VALUE)
	set(${PROJECT_NAME}_${TARGET_NAME} ${VALUE}
		CACHE BOOL "Whether to package ${TARGET_NAME}"
	)

	if(${PROJECT_NAME}_${TARGET_NAME})
		add_subdirectory(${TARGET_NAME})
	endif()
endmacro()
# ============================================================

# Create plugin library
add_library(${PROJECT_NAME} SHARED
	src/rviz_interface.cpp
	src/rviz_mapping.cpp
)
target_include_directories(${PROJECT_NAME}
	PUBLIC
		include
		# add other include directories here
)
target_link_libraries(${PROJECT_NAME}
	PUBLIC
		periodic_app_plugin
		dls_com
		dls_messages
		robotlib
)
target_link_directories(${PROJECT_NAME}
	PRIVATE
		${DLS_INSTALL_PERIODIC_APP_PLUGIN_DIR}/${PROJECT_NAME}
)

## add custom messages
# list(APPEND CMAKE_MODULE_PATH "/usr/include/dls_messages/cmake") # when using the installed dls2 project
# list(APPEND CMAKE_MODULE_PATH  "${DLS_MESSAGE_FOLDER}/cmake") # when compiling together with the dls2 project
# include(dls_message)		# message generation function
# dls_add_message(message ${PROJECT_NAME}) 	# generate message

# ================================== Install =================================

install(
	DIRECTORY   include/
	DESTINATION /usr/include/dls2
	COMPONENT   ${PROJECT_NAME}_dev
)

install(
	FILES		config/scheduler.yaml
	DESTINATION /usr/include/dls2/schedulers/
	COMPONENT   ${PROJECT_NAME}
	RENAME  	${PROJECT_NAME}.yaml
)

install(
	TARGETS             ${PROJECT_NAME}
	LIBRARY DESTINATION ${DLS_INSTALL_PERIODIC_APP_PLUGIN_DIR}
	COMPONENT           ${PROJECT_NAME}
)


# ================================= Packaging =================================
set(CPACK_PACKAGE_VERSION_MAJOR             ${PROJECT_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR             ${PROJECT_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH             ${PROJECT_VERSION_PATCH})
set(CPACK_DEBIAN_PACKAGE_VERSION            ${PROJECT_VERSION})
set(CPACK_PACKAGE_VENDOR                    "dlslab")
set(CPACK_PACKAGE_CONTACT                   "dlslab")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER         "dlslab")
set(CPACK_VERBATIM_VARIABLES                ON)
set(CPACK_GENERATOR                         "DEB")
set(CPACK_DEB_COMPONENT_INSTALL             ON)
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS          ON)

string(TOUPPER ${PROJECT_NAME} COMPONENT_NAME)

set(CPACK_DEBIAN_${COMPONENT_NAME}_PACKAGE_NAME          "dls-${PROJECT_NAME}" CACHE INTERNAL "")
set(CPACK_DEBIAN_${COMPONENT_NAME}_FILE_NAME             "dls-${PROJECT_NAME}-${PROJECT_VERSION}.deb" CACHE INTERNAL "")  
set(CPACK_DEBIAN_${COMPONENT_NAME}_PACKAGE_DEPENDS       "dls2-runtime" CACHE INTERNAL "") # add here package dependencies

set(CPACK_DEBIAN_${COMPONENT_NAME}_DEV_PACKAGE_NAME      "dls-${PROJECT_NAME}-dev" CACHE INTERNAL "")
set(CPACK_DEBIAN_${COMPONENT_NAME}_DEV_FILE_NAME         "dls-${PROJECT_NAME}-dev-${PROJECT_VERSION}.deb" CACHE INTERNAL "")  
set(CPACK_DEBIAN_${COMPONENT_NAME}_DEV_PACKAGE_DEPENDS   "dls2-dev, dls-${PROJECT_NAME}" CACHE INTERNAL "") # add here package dependencies

get_cmake_property(CPACK_COMPONENTS_ALL COMPONENTS)
list(REMOVE_ITEM CPACK_COMPONENTS_ALL "Unspecified")

include(CPack)
