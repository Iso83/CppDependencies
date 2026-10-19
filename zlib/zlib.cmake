include_guard(GLOBAL)

include(FetchContent)

set(CPPDEPENDENCIES_ZLIB_VERSION "1.3.2")

function(cppdependencies_zlib OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides the requested static or shared zlib dependency.
    # Source builds follow CMAKE_MSVC_RUNTIME_LIBRARY.
    # Installed packages must already use a compatible runtime.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the dependency target.
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
        message(FATAL_ERROR
            "cppdependencies_zlib: choose either STATIC or SHARED"
        )
    endif()

    if(ARG_STATIC)
        set(_linkage STATIC)
        set(_target zlibstatic)
        set(_candidates
            zlibstatic
            ZLIB::ZLIBSTATIC
            ZLIB::zlibstatic
            ZLIB::ZLIB
        )
    else()
        set(_linkage SHARED)
        set(_target zlib)
        set(_candidates
            zlib
            ZLIB::zlib
            ZLIB::ZLIB
        )
    endif()

    if(CMAKE_PREFIX_PATH AND NOT TARGET ZLIB::ZLIB)
        set(ZLIB_DIR "ZLIB_DIR-NOTFOUND")
        find_package(ZLIB ${CPPDEPENDENCIES_ZLIB_VERSION} CONFIG QUIET
            PATHS ${CMAKE_PREFIX_PATH}
            NO_DEFAULT_PATH
        )
    endif()

    foreach(_candidate IN LISTS _candidates)
        if(NOT TARGET ${_candidate})
            continue()
        endif()

        get_target_property(_type ${_candidate} TYPE)

        # A generic UNKNOWN_LIBRARY target does not establish linkage.
        if(NOT _type STREQUAL "${_linkage}_LIBRARY")
            if(NOT _type STREQUAL "UNKNOWN_LIBRARY"
               OR _candidate STREQUAL "ZLIB::ZLIB")
                continue()
            endif()
        endif()

        get_target_property(_imported ${_candidate} IMPORTED)

        if(_imported)
            # MSVC_RUNTIME_LIBRARY cannot change a prebuilt library.
            message(STATUS
                "CppDependencies zlib: installed ${_linkage} target '${_candidate}'"
            )
        else()
            # Target properties must be applied to the actual target,
            # not to an alias.
            get_target_property(_actual_target ${_candidate} ALIASED_TARGET)
            if(NOT _actual_target)
                set(_actual_target ${_candidate})
            endif()

            if(MSVC AND DEFINED CMAKE_MSVC_RUNTIME_LIBRARY)
                set_property(TARGET ${_actual_target}
                    PROPERTY MSVC_RUNTIME_LIBRARY
                        "${CMAKE_MSVC_RUNTIME_LIBRARY}"
                )
            endif()

            cppcmake_dependency_set_folder(${_actual_target} "zlib")

            message(STATUS
                "CppDependencies zlib: source ${_linkage} target '${_candidate}'"
            )
        endif()

        set(${OUT_TARGET} "${_candidate}" PARENT_SCOPE)
        return()
    endforeach()

    # No suitable existing target: build the requested dependency.
    FetchContent_Declare(
        zlib
        URL "https://github.com/madler/zlib/releases/download/v${CPPDEPENDENCIES_ZLIB_VERSION}/zlib-${CPPDEPENDENCIES_ZLIB_VERSION}.tar.gz"
        URL_HASH SHA256=bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    )

    set(_saved_zlib_build_testing_defined FALSE)
    if(DEFINED CACHE{ZLIB_BUILD_TESTING})
        set(_saved_zlib_build_testing_defined TRUE)
        get_property(_saved_zlib_build_testing
            CACHE ZLIB_BUILD_TESTING PROPERTY VALUE
        )
    endif()

    # Disable upstream tests without changing BUILD_TESTING.
    set(ZLIB_BUILD_TESTING OFF CACHE BOOL "" FORCE)

    cppcmake_dependency_make_available(zlib)

    if(_saved_zlib_build_testing_defined)
        set(ZLIB_BUILD_TESTING
            "${_saved_zlib_build_testing}" CACHE BOOL "" FORCE
        )
    else()
        unset(ZLIB_BUILD_TESTING CACHE)
    endif()

    FetchContent_GetProperties(zlib
        SOURCE_DIR zlib_SOURCE_DIR
        BINARY_DIR zlib_BINARY_DIR
    )

    if(NOT TARGET ${_target})
        message(FATAL_ERROR
            "cppdependencies_zlib: source build did not create '${_target}'"
        )
    endif()

    foreach(_library IN ITEMS zlib zlibstatic)
        if(NOT TARGET ${_library})
            continue()
        endif()

        # Follow the project's CRT choice; STATIC/SHARED is independent.
        if(MSVC AND DEFINED CMAKE_MSVC_RUNTIME_LIBRARY)
            set_property(TARGET ${_library}
                PROPERTY MSVC_RUNTIME_LIBRARY
                    "${CMAKE_MSVC_RUNTIME_LIBRARY}"
            )
        endif()

        if(NOT TARGET ZLIB::${_library})
            add_library(ZLIB::${_library} ALIAS ${_library})
        endif()

        cppcmake_dependency_set_folder(${_library} "zlib")
    endforeach()

    if(TARGET zlibstatic AND NOT TARGET ZLIB::ZLIBSTATIC)
        add_library(ZLIB::ZLIBSTATIC ALIAS zlibstatic)
    endif()

    if(NOT TARGET ZLIB::ZLIB)
        add_library(ZLIB::ZLIB ALIAS ${_target})
    endif()

    message(STATUS
        "CppDependencies zlib: source ${_linkage} target '${_target}' (${zlib_SOURCE_DIR})"
    )

    set(${OUT_TARGET} "${_target}" PARENT_SCOPE)
endfunction()