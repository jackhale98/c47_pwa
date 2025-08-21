cmake_minimum_required(VERSION 3.22.1)
project("c47calculator")

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# C43 core implementation files
add_library(c47-native SHARED
    # Main JNI integration bridge  
    c47-integration-bridge.cpp
    
    # C47 core mobile implementation
    c47-core-mobile.c
    
    # Legacy mobile API wrapper (for compatibility)
    c47-mobile-api.c
)

# Include directories
target_include_directories(c47-native PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/c47-core/headers
)

# Find required libraries
find_library(log-lib log)
find_library(android-lib android)

# Link libraries
target_link_libraries(c47-native
    ${log-lib}
    ${android-lib}
    m  # Math library
)

# Compiler flags optimized for mobile
target_compile_options(c47-native PRIVATE
    -Wall
    -Wextra
    -O2
    -ffast-math
    -fvisibility=hidden
    -ffunction-sections
    -fdata-sections
    # Android-specific flags
    -DANDROID
    -DMOBILE_BUILD
    -DC47_MOBILE_CORE
)

# C++ specific flags
target_compile_options(c47-native PRIVATE
    $<$<COMPILE_LANGUAGE:CXX>:-fno-rtti>
    $<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions>
)

# Linker flags for size optimization
set_target_properties(c47-native PROPERTIES
    LINK_FLAGS "-Wl,--gc-sections -Wl,--strip-all"
    CXX_VISIBILITY_PRESET hidden
    C_VISIBILITY_PRESET hidden
)

# Version info
set_target_properties(c47-native PROPERTIES
    VERSION 1.0.0
    SOVERSION 1
)