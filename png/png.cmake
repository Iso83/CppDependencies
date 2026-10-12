include_guard(GLOBAL)
include(FetchContent)
include("${CMAKE_CURRENT_LIST_DIR}/../zlib/zlib.cmake")

set(CPPDEPENDENCIES_PNG_VERSION "1.6.59")

function(cppdependencies_png OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides the requested static or shared libpng target.
    # Source builds appear under third_party/png in the IDE.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the selected library target.
    #
    # Options:
    #   STATIC - Link the static library.
    #   SHARED - Link the shared library (default).
    # =========================================================

    cmake_parse_arguments(PARSE_ARGV 1 ARG "STATIC;SHARED" "" "")
    
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "cppdependencies_png: unsupported arguments: ${ARG_UNPARSED_ARGUMENTS}"
        )
    endif()

    if(ARG_STATIC AND ARG_SHARED)
        message(FATAL_ERROR 
            "cppdependencies_png: choose either STATIC or SHARED"
        )
    endif()

    if(ARG_STATIC)
        set(_linkage STATIC)
        set(_target png_static)
    else()
        set(_linkage SHARED)
        set(_target png_shared)
    endif()

    if(CMAKE_PREFIX_PATH AND NOT TARGET PNG::PNG)
        find_package(PNG ${CPPDEPENDENCIES_PNG_VERSION} CONFIG QUIET)
    endif()
    
    foreach(_candidate IN ITEMS ${_target} PNG::${_target} PNG::PNG)
        if(TARGET ${_candidate})
            get_target_property(_type ${_candidate} TYPE)
            if(_type STREQUAL "${_linkage}_LIBRARY")
                set(${OUT_TARGET} ${_candidate} PARENT_SCOPE)
                return()
            endif()
        endif()
    endforeach()

    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    cppdependencies_zlib(CPPDEPENDENCIES_PNG_ZLIB_TARGET ${_linkage})
    get_target_property(_imported ${CPPDEPENDENCIES_PNG_ZLIB_TARGET} IMPORTED)
    if(_imported)
        get_target_property(ZLIB_INCLUDE_DIRS ${CPPDEPENDENCIES_PNG_ZLIB_TARGET}
            INTERFACE_INCLUDE_DIRECTORIES
        )
    else()
        # libpng's configure-header generator also needs the selected zlib
        # headers; linking a target alone only supplies them to compilation.
        FetchContent_GetProperties(zlib SOURCE_DIR _zlib_source BINARY_DIR _zlib_binary)
        set(ZLIB_INCLUDE_DIRS "${_zlib_source};${_zlib_binary}")
        set_property(TARGET ${CPPDEPENDENCIES_PNG_ZLIB_TARGET}
            PROPERTY POSITION_INDEPENDENT_CODE ON
        )
    endif()

    FetchContent_Declare(png
        URL "https://github.com/pnggroup/libpng/archive/refs/tags/v${CPPDEPENDENCIES_PNG_VERSION}.tar.gz"
        URL_HASH SHA256=2540302a1844ad2b2b501977abecfa850f265f97b78f065a712ab4074a89f5b5
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        SOURCE_SUBDIR cppdependencies-download-only
    )
    FetchContent_MakeAvailable(png)
    FetchContent_GetProperties(png SOURCE_DIR _source BINARY_DIR _binary)

    # Use the selected CppDependencies target instead of searching for another
    # zlib on the host. Only the downloaded CMake file changes, not C sources.
    set(_path "${_source}/CMakeLists.txt")
    file(READ "${_path}" _original)
    
    string(REPLACE "find_package(ZLIB REQUIRED)" "set(ZLIB_FOUND TRUE)"
        _content "${_original}"
    )

    string(REPLACE "set(PNG_LINK_LIBRARIES ZLIB::ZLIB)"
        "set(PNG_LINK_LIBRARIES \${CPPDEPENDENCIES_PNG_ZLIB_TARGET})"
        _content "${_content}"
    )

    if(NOT _content STREQUAL _original)
        file(WRITE "${_path}" "${_content}")
    endif()

    # Normal options are local to this function. Both projects stay visible;
    # only the target linked by the application needs to be built.
    set(PNG_SHARED ON)
    set(PNG_STATIC ON)
    set(PNG_TESTS OFF)
    set(PNG_TOOLS OFF)
    set(SKIP_INSTALL_ALL ON)
    add_subdirectory("${_source}" "${_binary}" EXCLUDE_FROM_ALL)

    foreach(_library IN ITEMS png_shared png_static)
        if(NOT TARGET PNG::${_library})
            add_library(PNG::${_library} ALIAS ${_library})
        endif()
        cppcmake_dependency_set_folder(${_library} "png")
    endforeach()

    foreach(_generator IN ITEMS png_genfiles png_genprebuilt)
        if(TARGET ${_generator})
            cppcmake_dependency_set_folder(${_generator} "png")
        endif()
    endforeach()

    if(NOT TARGET PNG::PNG)
        add_library(PNG::PNG ALIAS ${_target})
    endif()

    message(STATUS 
        "CppDependencies png: source ${_linkage} target '${_target}'"
    )
    set(${OUT_TARGET} ${_target} PARENT_SCOPE)
endfunction()
