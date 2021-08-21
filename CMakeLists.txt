cmake_minimum_required (VERSION 3.0)
PROJECT(opencv_testing)
find_package(OpenCV REQUIRED)
include_directories(${OpenCV_INCLUDE_DIRS})

# set standards at the project level
set(CMAKE_CXX_STANDARD 17)

add_executable(executable src/main.cc)
target_link_libraries(executable ${OpenCV_LIBS})
message(${OpenCV_LIBS})
# put the binary in the build folder
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/build)

