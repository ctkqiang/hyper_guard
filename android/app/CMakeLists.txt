cmake_minimum_required(VERSION 3.22.1)
project("hyperguard_sandbox")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(
    hyperguard_sandbox
    SHARED
    src/main/cpp/sandbox_core.cpp
    src/main/cpp/fake_data_provider.cpp
    src/main/cpp/behavior_monitor.cpp
    src/main/cpp/jni_bridge.cpp
)

target_include_directories(
    hyperguard_sandbox
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp
)

target_link_libraries(
    hyperguard_sandbox
    android
    log
)
