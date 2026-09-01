include_guard(GLOBAL)

include(FetchContent)

function(cppdependencies_talib OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides the TA-Lib dependency target.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the TA-Lib target name.
    #
    # Options:
    #   STATIC - Use the static TA-Lib library.
    #            Default is the shared library.
    # =========================================================

    cmake_parse_arguments(ARG "STATIC" "" "" ${ARGN})

    if(ARG_STATIC)
        set(_target TA-Lib-Static)
    else()
        set(_target TA-Lib)
    endif()

    if(TARGET ${_target})
        set(${OUT_TARGET} ${_target} PARENT_SCOPE)
        return()
    endif()

    find_package(TA-Lib CONFIG QUIET)

    if(NOT TARGET ${_target})
        FetchContent_Declare(
            talib
            URL "https://github.com/TA-Lib/ta-lib/archive/refs/tags/v0.7.1.tar.gz"
            URL_HASH SHA256=40e7a6978052fe5245771e430e6a4c4553b40038f8ac5a985a1540c4c1fa6ace
        )

        if(WIN32)
            if(CMAKE_SIZEOF_VOID_P EQUAL 8)
                set(ENV{Platform} "x64")
            else()
                set(ENV{Platform} "x86")
            endif()
        endif()

        set(BUILD_DEV_TOOLS OFF CACHE BOOL "Build TA-Lib development tools" FORCE)

        cppcmake_dependency_make_available(talib)

        if(NOT TARGET TA-Lib)
            add_library(TA-Lib ALIAS ta-lib)
        endif()

        if(NOT TARGET TA-Lib-Static)
            add_library(TA-Lib-Static ALIAS ta-lib-static)
        endif()

        cppcmake_dependency_set_folder(ta-lib "ta-lib")
        cppcmake_dependency_set_folder(ta-lib-static "ta-lib")
    endif()

    set(${OUT_TARGET} ${_target} PARENT_SCOPE)
endfunction()

function(cppdependencies_talib_copy_runtime TARGET)
    # =========================================================
    # Summary
    #
    # Copies the TA-Lib shared library next to the target.
    #
    # Parameters:
    #   TARGET - Target that requires the TA-Lib runtime.
    # =========================================================

    if(NOT TARGET ${TARGET})
        message(FATAL_ERROR
            "cppdependencies_talib_copy_runtime: "
            "target '${TARGET}' does not exist."
        )
    endif()

    if(NOT TARGET TA-Lib)
        message(FATAL_ERROR
            "cppdependencies_talib_copy_runtime: "
            "TA-Lib shared target is not available."
        )
    endif()

    add_custom_command(
        TARGET ${TARGET}
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:TA-Lib>"
            "$<TARGET_FILE_DIR:${TARGET}>"
        COMMENT "Copying TA-Lib runtime for ${TARGET}"
        VERBATIM
    )
endfunction()