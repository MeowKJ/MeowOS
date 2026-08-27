cmake_minimum_required(VERSION 3.10)
project(meow_runtime_tests LANGUAGES CXX)

add_executable(meow-runtime-test
    ../../tools/test-runtime.cpp
    ../../src/runtime/task_scheduler.cpp
    ../../src/runtime/app_session.cpp
    ../../src/runtime/app_session_supervisor.cpp
    ../../src/runtime/runtime_snapshot.cpp
    ../../src/hal/hal_interfaces.cpp)
target_include_directories(meow-runtime-test PRIVATE ../../src)
set_target_properties(meow-runtime-test PROPERTIES CXX_STANDARD 11 CXX_STANDARD_REQUIRED YES)
if (CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(meow-runtime-test PRIVATE -Wall -Wextra -Werror -pthread)
    target_link_options(meow-runtime-test PRIVATE -pthread)
endif()
enable_testing()
add_test(NAME runtime_contracts COMMAND meow-runtime-test)
