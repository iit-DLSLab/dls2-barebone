# Regenerate ROS2 messages from IDL definitions on every CMake configure.
message(STATUS "Generating ROS2 messages from IDL files...")
set(DLS2_ROS2_INTERFACE_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/dls2_ros2_interface/ros2_ws/src")
set(DLS2_ROS2_INTERFACE_DIR "${DLS2_ROS2_INTERFACE_SRC_DIR}/dls2_interface")
find_package(Python3 REQUIRED COMPONENTS Interpreter)
file(GLOB DLS_IDL_FILES CONFIGURE_DEPENDS "${DLS_MESSAGE_FOLDER}/idls/*.idl")
if(NOT DLS_IDL_FILES)
  message(FATAL_ERROR "No IDL files found in '${DLS_MESSAGE_FOLDER}/idls'. Existing ROS2 messages were preserved.")
endif()
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
  ${DLS_IDL_FILES} "${DLS2_ROS2_INTERFACE_DIR}/scripts/idl_to_msg.py")

# Generate in the build tree first so a conversion failure preserves existing messages.
set(DLS_ROS2_MSG_STAGE "${CMAKE_CURRENT_BINARY_DIR}/generated_ros2_messages")
file(REMOVE_RECURSE "${DLS_ROS2_MSG_STAGE}")
file(MAKE_DIRECTORY "${DLS_ROS2_MSG_STAGE}")
foreach(idl_file IN LISTS DLS_IDL_FILES)
  execute_process(
    COMMAND "${Python3_EXECUTABLE}" "${DLS2_ROS2_INTERFACE_DIR}/scripts/idl_to_msg.py"
      "${idl_file}" --strict -o "${DLS_ROS2_MSG_STAGE}"
    WORKING_DIRECTORY "${DLS2_ROS2_INTERFACE_DIR}"
    RESULT_VARIABLE DLS_IDL_RESULT
    OUTPUT_VARIABLE DLS_IDL_OUTPUT
    ERROR_VARIABLE DLS_IDL_ERROR
  )
  if(NOT "${DLS_IDL_RESULT}" STREQUAL "0")
    message(FATAL_ERROR "ROS2 message generation failed for '${idl_file}':\n${DLS_IDL_OUTPUT}\n${DLS_IDL_ERROR}\nExisting ROS2 messages were preserved.")
  endif()
endforeach()

file(GLOB DLS_GENERATED_MSG_FILES "${DLS_ROS2_MSG_STAGE}/dls2_interface/msg/*.msg")
if(NOT DLS_GENERATED_MSG_FILES)
  message(FATAL_ERROR "No dls2_interface messages were generated. Existing ROS2 messages were preserved.")
endif()
file(COPY ${DLS_GENERATED_MSG_FILES} DESTINATION "${DLS2_ROS2_INTERFACE_DIR}/msg")

# Remove obsolete messages only after all conversions and the copy have succeeded.
file(GLOB DLS_MSG_FILES "${DLS2_ROS2_INTERFACE_DIR}/msg/*.msg")
foreach(msg_file IN LISTS DLS_MSG_FILES)
  get_filename_component(msg_name "${msg_file}" NAME)
  if(NOT EXISTS "${DLS_ROS2_MSG_STAGE}/dls2_interface/msg/${msg_name}")
    file(REMOVE "${msg_file}")
  endif()
endforeach()
list(LENGTH DLS_GENERATED_MSG_FILES DLS_GENERATED_MSG_COUNT)
message(STATUS "Generated ${DLS_GENERATED_MSG_COUNT} ROS2 messages in ${DLS2_ROS2_INTERFACE_DIR}/msg")
