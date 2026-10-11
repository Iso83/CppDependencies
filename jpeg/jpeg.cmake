include_guard(GLOBAL)

include(FetchContent)

set(CPPDEPENDENCIES_JPEG_VERSION "3.2.0")

function(cppdependencies_jpeg OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides the libjpeg-turbo dependency target.  
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the selected library target name.
    #
    # Options:
    #   STATIC - Link the static library.
    #   SHARED - Link the shared library/DLL (default).
    # =========================================================

    cmake_parse_arguments(PARSE_ARGV 1 ARG "STATIC;SHARED" "" "")

    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "cppdependencies_jpeg: unsupported arguments: ${ARG_UNPARSED_ARGUMENTS}"
        )
    endif()

    if(ARG_STATIC AND ARG_SHARED)
        message(FATAL_ERROR
            "cppdependencies_jpeg: choose either STATIC or SHARED"
        )
    endif()

    if(ARG_STATIC)
        set(_jpeg_target libjpeg-turbo::jpeg-static)
    else()
        set(_jpeg_target libjpeg-turbo::jpeg)
    endif()

    if(TARGET ${_jpeg_target})
        set(${OUT_TARGET} ${_jpeg_target} PARENT_SCOPE)
        return()
    endif()

    find_package(libjpeg-turbo ${CPPDEPENDENCIES_JPEG_VERSION} CONFIG QUIET)

    if(TARGET ${_jpeg_target})
        set(${OUT_TARGET} ${_jpeg_target} PARENT_SCOPE)
        return()
    endif()

    if(libjpeg-turbo_FOUND)
        message(FATAL_ERROR
            "cppdependencies_jpeg: the installed package does not provide "
            "the requested target '${_jpeg_target}'"
        )
    endif()

    # Download at configure time without running upstream's CMake yet.
    FetchContent_Declare(
        jpeg
        URL "https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/${CPPDEPENDENCIES_JPEG_VERSION}/libjpeg-turbo-${CPPDEPENDENCIES_JPEG_VERSION}.tar.gz"
        URL_HASH SHA256=6f30092cef9fb839779646608f4ee14ae3cbac989c47fa05e841b0841f09878e
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        SOURCE_SUBDIR cppdependencies-download-only
    )
    FetchContent_MakeAvailable(jpeg)
    FetchContent_GetProperties(jpeg
        SOURCE_DIR _jpeg_source
        BINARY_DIR _jpeg_binary
    )

    # Upstream assumes it owns the top-level project. Adapt only the downloaded
    # CMake files to use libjpeg-turbo's own project paths/name. This also makes
    # its subproject guard pass after project(libjpeg-turbo C).
    # The C/C++ sources are unchanged; repeated configuration is idempotent.
    foreach(_file IN ITEMS
        CMakeLists.txt
        sharedlib/CMakeLists.txt
        simd/CMakeLists.txt
        cmakescripts/BuildPackages.cmake
        release/Config.cmake.in
        src/jconfigint.h.in
        win/jpeg.rc.in
    )
        set(_path "${_jpeg_source}/${_file}")
        file(READ "${_path}" _original)
        string(REPLACE "CMAKE_SOURCE_DIR" "PROJECT_SOURCE_DIR" _content "${_original}")
        string(REPLACE "CMAKE_BINARY_DIR" "PROJECT_BINARY_DIR" _content "${_content}")
        string(REPLACE "CMAKE_PROJECT_NAME" "PROJECT_NAME" _content "${_content}")
        if(NOT _content STREQUAL _original)
            file(WRITE "${_path}" "${_content}")
        endif()
    endforeach()

    # Normal variables stay local to this function (no forced cache changes).
    # Show both libraries in the solution; EXCLUDE_FROM_ALL below ensures that
    # only libraries actually linked by the application need to be built.
    set(ENABLE_STATIC ON)
    set(ENABLE_SHARED ON)
    set(WITH_TOOLS OFF)
    set(WITH_TESTS OFF)
    set(WITH_TURBOJPEG OFF)
    set(WITH_CRT_DLL ON)
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    # Prevent upstream from replacing the parent project's install prefix.
    set(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT FALSE)

    add_subdirectory("${_jpeg_source}" "${_jpeg_binary}" EXCLUDE_FROM_ALL)

    # Both library targets need the source headers and generated jconfig.h.
    foreach(_target IN ITEMS jpeg-static jpeg)
        target_include_directories(${_target} PUBLIC
            "$<BUILD_INTERFACE:${_jpeg_source}/src>"
            "$<BUILD_INTERFACE:${_jpeg_binary}>"
        )
        add_library(libjpeg-turbo::${_target} ALIAS ${_target})
        cppcmake_dependency_set_folder(${_target} "jpeg")
    endforeach()

    set(${OUT_TARGET} ${_jpeg_target} PARENT_SCOPE)
endfunction()
