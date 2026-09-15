# Configure the IDL source directory before adding dependent subdirectories.
set(DLS_MESSAGE_DEFAULT_FOLDER "${CMAKE_CURRENT_SOURCE_DIR}/transport_interfaces/transports/fastdds/dls2_msgs")
set(DLS_MESSAGE_FOLDER "${DLS_MESSAGE_DEFAULT_FOLDER}"
  CACHE PATH "Path to the dls2_msgs folder"
)
# Older build caches can still point to the former dls2_msgs location.
if(NOT IS_DIRECTORY "${DLS_MESSAGE_FOLDER}/idls")
  message(WARNING "DLS_MESSAGE_FOLDER '${DLS_MESSAGE_FOLDER}' has no idls directory; using '${DLS_MESSAGE_DEFAULT_FOLDER}'.")
  set(DLS_MESSAGE_FOLDER "${DLS_MESSAGE_DEFAULT_FOLDER}" CACHE PATH "Path to the dls2_msgs folder" FORCE)
endif()
