cmake_minimum_required(VERSION 3.12)
project(minidump VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Compiler options
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic")
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g -O0")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3 -DNDEBUG")
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W4")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /O2 /DNDEBUG")
endif()

# Enable testing
enable_testing()

# Create the minidump library
add_library(minidump STATIC
    include/minidump/minidump.hpp
    src/minidump.cpp
)

target_include_directories(minidump PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

# Create the example program
add_executable(parse_dump
    examples/parse_dump.cpp
)

target_link_libraries(parse_dump PRIVATE minidump)

# Create debug program
add_executable(debug_dump
    examples/debug_dump.cpp
)

target_link_libraries(debug_dump PRIVATE minidump)

# Create struct debug program
add_executable(struct_debug
    examples/struct_debug.cpp
)

target_link_libraries(struct_debug PRIVATE minidump)

# Define test data paths
set(TEST_DATA_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../dumps")
set(TEST_DMP_FILE "${TEST_DATA_DIR}/StringEncryptionFun_x64.dmp")

# Add tests that will verify against Python output
add_test(NAME test_parse_dump 
         COMMAND parse_dump "${TEST_DMP_FILE}")

# Test that compares C++ output with Python output
add_test(NAME compare_with_python
         COMMAND ${CMAKE_COMMAND} -E env
         WORKING_DIRECTORY=${CMAKE_CURRENT_SOURCE_DIR}
         bash -c "cd .. && uv run python -m minidump --all ./dumps/StringEncryptionFun_x64.dmp > minidump/python_output.txt && cd minidump && ./parse_dump ../dumps/StringEncryptionFun_x64.dmp > cpp_output.txt && diff python_output.txt cpp_output.txt")

# Custom target for running comparison tests
add_custom_target(compare
    COMMAND cd ${CMAKE_CURRENT_SOURCE_DIR}/.. && uv run python -m minidump --all ./dumps/StringEncryptionFun_x64.dmp > minidump/python_output.txt
    COMMAND cd ${CMAKE_CURRENT_SOURCE_DIR} && $<TARGET_FILE:parse_dump> ../dumps/StringEncryptionFun_x64.dmp > cpp_output.txt
    COMMAND diff python_output.txt cpp_output.txt || echo "Differences found - checking details..."
    DEPENDS parse_dump
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Comparing C++ output with Python output"
)

# Installation
install(TARGETS minidump parse_dump
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)

install(DIRECTORY include/
    DESTINATION include
    FILES_MATCHING PATTERN "*.hpp"
)