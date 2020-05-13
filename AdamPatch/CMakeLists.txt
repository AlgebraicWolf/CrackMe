cmake_minimum_required(VERSION 3.17)
project(AdamPatch)

set(CMAKE_CXX_STANDARD 14)

add_executable(AdamPatch main.cpp)

target_link_libraries(AdamPatch ncurses)