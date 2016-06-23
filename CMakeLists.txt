cmake_minimum_required(VERSION 2.8)
project(caela)

# Add executables
add_executable(dchip2cn src/dchip2cn.cpp)
add_executable(penn2seg src/penn2seg.cpp)

set(convert_EXECS dchip2cn penn2seg)

# Installation
install(TARGETS ${convert_EXECS} DESTINATION bin)
install(DIRECTORY bin DESTINATION . USE_SOURCE_PERMISSIONS) 

