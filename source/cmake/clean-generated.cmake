set(generated "${CMAKE_CURRENT_BINARY_DIR}/x264.rc"
              "${CMAKE_CURRENT_BINARY_DIR}/x264.pc"
              "${CMAKE_CURRENT_BINARY_DIR}/x264.def"
              "${CMAKE_CURRENT_BINARY_DIR}/x264_config.h")

foreach(file ${generated})
  if(EXISTS ${file})
     file(REMOVE ${file})
  endif()
endforeach(file)
