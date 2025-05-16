cmake_minimum_required(VERSION 3.5)

project(AudioVLC_Test LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(BUILD_RPATH AudioVLC.xcframework/macos-arm64_x86_64)
add_definitions(-DBUILD_RPATH=\"${BUILD_RPATH}\")
set(CMAKE_BUILD_RPATH  @executable_path/${BUILD_RPATH})
set(CMAKE_MACOSX_RPATH 1)



set(CMAKE_FIND_DEBUG_MODE on)
find_library(LIBVLC vlc
    REQUIRED
    NO_DEFAULT_PATH
    PATHS
    ${CMAKE_CURRENT_SOURCE_DIR}/../AudioVLC.xcframework/macos-arm64_x86_64/AudioVLC.framework
)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../AudioVLC.xcframework/macos-arm64_x86_64/AudioVLC.framework/Headers)

message("************************************")
message("** LIBVLC_LIBRARY:    ${LIBVLC}")
message("** CMAKE_BUILD_RPATH: ${CMAKE_BUILD_RPATH}")
message("************************************")


add_executable(${PROJECT_NAME} main.cpp)
target_link_libraries(${PROJECT_NAME} ${LIBVLC})
install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION .)
