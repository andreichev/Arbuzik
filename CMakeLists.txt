cmake_minimum_required(VERSION 3.29)
project(Arbuzik)

set(CMAKE_CXX_STANDARD 20)
set(BIN_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin)
set(APP_NAME Arbuzik)

if("$ENV{VULKAN_SDK}" STREQUAL "")
message(FATAL_ERROR "Vulkan installation not found. Check that VULKAN_SDK environment variable is set correctly")
endif ()

message("VULKAN SDK: $ENV{VULKAN_SDK}")

file(GLOB ASSETS "${CMAKE_CURRENT_SOURCE_DIR}/Resources/*")
list(FILTER ASSETS EXCLUDE REGEX "\\.DS_Store")

add_executable(Arbuzik MACOSX_BUNDLE main.m AppDelegate.m ${ASSETS})

set_target_properties(Arbuzik PROPERTIES
        RESOURCE "${ASSETS}"
)

source_group("Resources" FILES "${ASSETS}")

set_source_files_properties(${ASSETS} PROPERTIES
        VS_DEPLOYMENT_LOCATION "."
        MACOSX_PACKAGE_LOCATION "Resources"
)

foreach (RESOURCE_FOLDER IN ITEMS ${ASSETS})
    # Copy assets to target folder
    file(COPY ${RESOURCE_FOLDER} DESTINATION "${BIN_DIRECTORY}/${APP_NAME}.app/Contents/Resources")
endforeach ()

# set output directories for all builds (Debug, Release, etc.)
foreach( OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES} )
    string( TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG )
    set_target_properties(Arbuzik
            PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${BIN_DIRECTORY}
    )
endforeach( OUTPUTCONFIG CMAKE_CONFIGURATION_TYPES )

set_target_properties(Arbuzik
        PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY ${BIN_DIRECTORY}
)

set_target_properties(Arbuzik
        PROPERTIES
        VS_DEBUGGER_WORKING_DIRECTORY ${BIN_DIRECTORY}
)

target_link_options(Arbuzik PRIVATE -ObjC)

set(LIBVULKAN_ALIAS "$ENV{VULKAN_SDK}/lib/libvulkan.1.dylib")
set(MOLTENVK_LIB "$ENV{VULKAN_SDK}/lib/libMoltenVK.dylib")

if(NOT EXISTS ${LIBVULKAN_ALIAS})
    message(FATAL_ERROR "ERROR: FILE ${LIBVULKAN_ALIAS} NOT FOUND")
endif ()

if(NOT EXISTS ${MOLTENVK_LIB})
    message(FATAL_ERROR "ERROR: FILE ${MOLTENVK_LIB} NOT FOUND")
endif ()

# get_filename_component(REAL_LIBVULKAN ${LIBVULKAN_ALIAS} REALPATH)

set(TARGET_FRAMEWORKS_DIR "${BIN_DIRECTORY}/${APP_NAME}.app/Contents/Frameworks")

target_compile_definitions(Arbuzik PRIVATE VK_ENABLE_BETA_EXTENSIONS)
target_link_libraries(Arbuzik ${LIBVULKAN_ALIAS})
target_include_directories(Arbuzik PRIVATE $ENV{VULKAN_SDK}/include)

add_custom_command(
        TARGET Arbuzik PRE_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory ${TARGET_FRAMEWORKS_DIR}
        COMMENT "Creating Frameworks directory"
        VERBATIM
)
add_custom_command(
        TARGET Arbuzik POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy ${LIBVULKAN_ALIAS} ${TARGET_FRAMEWORKS_DIR}
        COMMAND ${CMAKE_COMMAND} -E copy ${MOLTENVK_LIB} ${TARGET_FRAMEWORKS_DIR}
        COMMENT "Copying Vulkan libraries to Frameworks directory"
)

add_custom_command(
        TARGET Arbuzik POST_BUILD
        COMMAND install_name_tool -add_rpath "@executable_path/../Frameworks/" "${BIN_DIRECTORY}/${APP_NAME}.app/Contents/MacOS/${APP_NAME}"
        COMMENT "Set correct @rpath to an executable"
)

target_link_libraries(Arbuzik "-framework Cocoa"
        "-framework IOKit"
        "-framework CoreFoundation"
        "-framework QuartzCore")