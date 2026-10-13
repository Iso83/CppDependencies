include_guard(GLOBAL)
include(FetchContent)

set(CPPDEPENDENCIES_OPENCV_VERSION "5.0.0")

function(cppdependencies_opencv OUT_TARGETS)
    # =========================================================
    # Summary
    #
    # Provides OpenCV from existing targets, a package or pinned source.
    # Optional codec targets are selected/provided by the caller; this
    # resolver never fetches codec libraries on the caller's behalf.
    #
    # Parameters:
    #   [out] OUT_TARGETS - Receives the OpenCV target list.
    #
    # Options:
    #   STATIC / SHARED - Required OpenCV linkage (choose one).
    #
    # Arguments:
    #   COMPONENTS <names...> - Optional OpenCV components.
    #   ZLIB_TARGET <target> - Optional existing zlib library target.
    #   PNG_TARGET <target> - Optional existing PNG library target.
    #   JPEG_TARGET <target> - Optional existing JPEG library target.
    #   TIFF_TARGET <target> - Optional existing TIFF library target.
    #
    # Omitted codecs follow upstream's normal discovery/build behaviour.
    # Supplied codecs replace upstream discovery for source builds.
    # Installed packages retain their compiled codec profile.
    # Components without the COMPONENTS keyword remain supported.
    # =========================================================

    cmake_parse_arguments(PARSE_ARGV 1 ARG "STATIC;SHARED"
        "ZLIB_TARGET;PNG_TARGET;JPEG_TARGET;TIFF_TARGET" "COMPONENTS"
    )
    if(ARG_KEYWORDS_MISSING_VALUES OR (ARG_STATIC AND ARG_SHARED) OR
       (NOT ARG_STATIC AND NOT ARG_SHARED))
        message(FATAL_ERROR "cppdependencies_opencv: choose STATIC or SHARED and provide values for named arguments")
    endif()
    set(_components ${ARG_COMPONENTS} ${ARG_UNPARSED_ARGUMENTS})

    set(_codec_targets)
    set(_codec_headers)
    foreach(_codec IN ITEMS ZLIB PNG JPEG TIFF)
        set(_target "${ARG_${_codec}_TARGET}")
        if(NOT _target)
            continue()
        endif()
        if(NOT TARGET "${_target}")
            message(FATAL_ERROR
                "cppdependencies_opencv: ${_codec}_TARGET must name an existing target"
            )
        endif()
        get_target_property(_type ${_target} TYPE)
        if(NOT _type MATCHES "^(STATIC_LIBRARY|SHARED_LIBRARY|UNKNOWN_LIBRARY)$")
            message(FATAL_ERROR
                "cppdependencies_opencv: ${_codec}_TARGET must be a library target"
            )
        endif()

        get_target_property(_includes ${_target} INTERFACE_INCLUDE_DIRECTORIES)
        set(_headers)
        foreach(_include IN LISTS _includes)
            if(_include MATCHES "^\\$<BUILD_INTERFACE:(.*)>$")
                list(APPEND _headers "${CMAKE_MATCH_1}")
            elseif(NOT _include MATCHES "^\\$<" AND NOT _include MATCHES "-NOTFOUND$")
                list(APPEND _headers "${_include}")
            endif()
        endforeach()
        if(NOT _headers)
            message(FATAL_ERROR
                "cppdependencies_opencv: ${_codec}_TARGET has no usable header directories"
            )
        endif()
        list(GET _headers 0 _header)
        set(${_codec}_INCLUDE_DIR "${_header}" CACHE PATH "Selected codec headers" FORCE)
        set(${_codec}_INCLUDE_DIRS "${_headers}")

        # Select the import library on Windows, not the DLL. Generator
        # expressions preserve the selected target's Debug/Release mapping.
        set(${_codec}_LIBRARY "$<TARGET_LINKER_FILE:${_target}>"
            CACHE STRING "Selected codec link library" FORCE
        )
        set(BUILD_${_codec} OFF CACHE BOOL "Use the caller-selected codec" FORCE)
        list(APPEND _codec_targets ${_target})
        list(APPEND _codec_headers ${_headers})
    endforeach()
    if(ARG_PNG_TARGET)
        set(PNG_PNG_INCLUDE_DIR "${PNG_INCLUDE_DIR}" CACHE PATH "Selected PNG headers" FORCE)
    endif()
    list(REMOVE_DUPLICATES _codec_targets)
    list(REMOVE_DUPLICATES _codec_headers)


    if(ARG_STATIC)
        set(_linkage STATIC)
    else()
        set(_linkage SHARED)
    endif()

    set(_targets)
    set(_existing TRUE)
    foreach(_component IN LISTS _components)
        if(TARGET opencv_${_component})
            list(APPEND _targets opencv_${_component})
        else()
            set(_existing FALSE)
        endif()
    endforeach()
    if(NOT _components OR NOT _existing)
        if(COMMAND cppdependencies_package_opencv)
            cppdependencies_package_opencv(${_linkage})
        endif()
        if(_components)
            find_package(OpenCV ${CPPDEPENDENCIES_OPENCV_VERSION} CONFIG QUIET COMPONENTS ${_components})
        else()
            find_package(OpenCV ${CPPDEPENDENCIES_OPENCV_VERSION} CONFIG QUIET)
        endif()
        if(OpenCV_FOUND)
            set(_targets ${OpenCV_LIBS})
        else()
            FetchContent_Declare(opencv
                URL "https://github.com/opencv/opencv/archive/refs/tags/${CPPDEPENDENCIES_OPENCV_VERSION}.tar.gz"
                URL_HASH SHA256=b0528f5a1d379d59d4701cb28c36e22214cc51cf64594e5b56f2d3e6c0233095
            )
            # COMPONENTS also limits the source build, so callers need not
            # repeat the same list in BUILD_LIST. Upstream treats this string
            # as a cache setting; restore the caller's entry afterwards.
            if(_components)
                set(_had_build_list FALSE)
                if(DEFINED CACHE{BUILD_LIST})
                    set(_had_build_list TRUE)
                    get_property(_saved_build_list CACHE BUILD_LIST PROPERTY VALUE)
                endif()
                list(JOIN _components "," _build_list)
                set(BUILD_LIST "${_build_list}" CACHE STRING "Requested OpenCV modules" FORCE)
                set(BUILD_LIST "${_build_list}")
            endif()
            # OpenCV 5's nested IPP HAL is not composable as a subproject.
            # Leave an explicit caller setting intact; default to disabling it.
            if(NOT DEFINED WITH_IPP)
                set(WITH_IPP OFF)
            endif()
            # Normal options stay within this function; do not rewrite the
            # caller's BUILD_TESTING or generic build-option cache entries.
            set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)
            set(BUILD_SHARED_LIBS ${ARG_SHARED})
            set(BUILD_TESTS OFF)
            set(BUILD_PERF_TESTS OFF)
            set(BUILD_EXAMPLES OFF)
            set(BUILD_DOCS OFF)
            set(BUILD_PACKAGE OFF)
            set(BUILD_JAVA OFF)
            set(BUILD_opencv_apps OFF)
            set(BUILD_opencv_python3 OFF)
            set(BUILD_opencv_js OFF)
            cppcmake_dependency_make_available(opencv)
            set(_targets ${OPENCV_MODULES_PUBLIC})
            if(_components)
                if(_had_build_list)
                    set(BUILD_LIST "${_saved_build_list}" CACHE STRING "OpenCV module selection" FORCE)
                else()
                    unset(BUILD_LIST CACHE)
                endif()
            endif()
        endif()
        if(_components)
            set(_targets)
            foreach(_component IN LISTS _components)
                if(NOT TARGET opencv_${_component})
                    message(FATAL_ERROR 
                        "cppdependencies_opencv: missing component '${_component}'"
                    )
                endif()
                list(APPEND _targets opencv_${_component})
            endforeach()
        endif()
    endif()

    # Source targets need build ordering and generated/public headers.
    foreach(_target IN LISTS _targets)
        get_target_property(_imported ${_target} IMPORTED)
        if(NOT _imported)
            get_target_property(_source ${_target} SOURCE_DIR)
            if(_codec_targets)
                add_dependencies(${_target} ${_codec_targets})
                target_include_directories(${_target} PRIVATE ${_codec_headers})
            endif()
            target_include_directories(${_target} INTERFACE
                "$<BUILD_INTERFACE:${_source}/include>"
                "$<BUILD_INTERFACE:${CMAKE_BINARY_DIR}>"
            )
        endif()
    endforeach()
    
    set(${OUT_TARGETS} "${_targets}" PARENT_SCOPE)
endfunction()
