include_guard(GLOBAL)

include(FetchContent)

set(CPPDEPENDENCIES_ZLIB_VERSION "1.3.2")

function(cppdependencies_zlib OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides the requested static or shared zlib dependency target.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the public dependency target.
    #
    # Options:
    #   STATIC - Link the static library.
    #   SHARED - Link the shared library (default).
    # =========================================================

    cmake_parse_arguments(PARSE_ARGV 1 ARG "STATIC;SHARED" "" "")

    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "cppdependencies_zlib: unsupported arguments: ${ARG_UNPARSED_ARGUMENTS}"
        )
    endif()

    if(ARG_STATIC AND ARG_SHARED)
        message(FATAL_ERROR "cppdependencies_zlib: choose either STATIC or SHARED")
    endif()

    if(ARG_STATIC)
        set(_linkage STATIC)
        set(_target zlibstatic)
    else()
        set(_linkage SHARED)
        set(_target zlib)
    endif()

    if(CMAKE_PREFIX_PATH AND NOT TARGET ZLIB::ZLIB)
        set(ZLIB_DIR "ZLIB_DIR-NOTFOUND")
        find_package(ZLIB ${CPPDEPENDENCIES_ZLIB_VERSION} CONFIG QUIET
            PATHS ${CMAKE_PREFIX_PATH}
            NO_DEFAULT_PATH
        )
    endif()

    foreach(_candidate IN ITEMS ${_target} ZLIB::${_target} ZLIB::ZLIB)
        if(NOT TARGET ${_candidate})
            continue()
        endif()

        get_target_property(_type ${_candidate} TYPE)

        # A generic UNKNOWN_LIBRARY target does not establish its linkage.
        if(_type STREQUAL "${_linkage}_LIBRARY" OR
           (_type STREQUAL "UNKNOWN_LIBRARY" AND
            NOT _candidate STREQUAL "ZLIB::ZLIB"))
            get_target_property(_imported ${_candidate} IMPORTED)
            if(_imported)
                message(STATUS "CppDependencies zlib: installed ${_linkage} target '${_candidate}'")
            else()
                if(TARGET zlib)
                    cppcmake_dependency_set_folder(zlib "zlib")
                endif()
                if(TARGET zlibstatic)
                    cppcmake_dependency_set_folder(zlibstatic "zlib")
                endif()
                message(STATUS "CppDependencies zlib: source ${_linkage} target '${_candidate}'")
            endif()
            set(${OUT_TARGET} ${_candidate} PARENT_SCOPE)
            return()
        endif()
    endforeach()

    # A package without the requested linkage does not block the source fallback.
    # Do not redefine its generic ZLIB::ZLIB target.
    FetchContent_Declare(
        zlib
        URL "https://github.com/madler/zlib/releases/download/v${CPPDEPENDENCIES_ZLIB_VERSION}/zlib-${CPPDEPENDENCIES_ZLIB_VERSION}.tar.gz"
        URL_HASH SHA256=bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    )

    set(_saved_zlib_build_testing_defined FALSE)
    if(DEFINED CACHE{ZLIB_BUILD_TESTING})
        set(_saved_zlib_build_testing_defined TRUE)
        get_property(_saved_zlib_build_testing CACHE ZLIB_BUILD_TESTING PROPERTY VALUE)
    endif()

    set(ZLIB_BUILD_TESTING OFF CACHE BOOL "" FORCE)
    # Disable upstream tests without changing the application's BUILD_TESTING.
    cppcmake_dependency_make_available(zlib)
    FetchContent_GetProperties(zlib
        SOURCE_DIR zlib_SOURCE_DIR
        BINARY_DIR zlib_BINARY_DIR
    )

    if(NOT TARGET ${_target})
        message(FATAL_ERROR "cppdependencies_zlib: source build did not create '${_target}'")
    endif()

    # Imported package aliases can coexist with source targets. Never replace
    # them, and return the actual source target so IDE references point to it.
    foreach(_library IN ITEMS zlib zlibstatic)
        if(NOT TARGET ZLIB::${_library})
            add_library(ZLIB::${_library} ALIAS ${_library})
        endif()
        cppcmake_dependency_set_folder(${_library} "zlib")
    endforeach()
    if(NOT TARGET ZLIB::ZLIB)
        add_library(ZLIB::ZLIB ALIAS ${_target})
    endif()

    if(_saved_zlib_build_testing_defined)
        set(ZLIB_BUILD_TESTING "${_saved_zlib_build_testing}" CACHE BOOL "" FORCE)
    else()
        unset(ZLIB_BUILD_TESTING CACHE)
    endif()

    message(STATUS
        "CppDependencies zlib: source ${_linkage} target '${_target}' (${zlib_SOURCE_DIR})"
    )
    set(${OUT_TARGET} ${_target} PARENT_SCOPE)
endfunction()
