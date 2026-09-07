include_guard(GLOBAL)

include(FetchContent)

set(CPPDEPENDENCIES_OPENCV_VERSION "5.0.0")

function(cppdependencies_opencv OUT_TARGETS)
    # =========================================================
    # Summary
    #
    # Provides the OpenCV dependency.
    #
    # Parameters:
    #   [out] OUT_TARGETS - Receives the OpenCV target list.
    #   [in]  ARGN        - Optional OpenCV components.
    # =========================================================

    if(ARGN)
        find_package(
            OpenCV ${CPPDEPENDENCIES_OPENCV_VERSION}
            CONFIG
            QUIET
            COMPONENTS ${ARGN}
        )
    else()
        find_package(
            OpenCV ${CPPDEPENDENCIES_OPENCV_VERSION}
            CONFIG
            QUIET
        )
    endif()

    if(NOT OpenCV_FOUND)
        FetchContent_Declare(
            opencv
            URL https://github.com/opencv/opencv/archive/refs/tags/${CPPDEPENDENCIES_OPENCV_VERSION}.tar.gz
            URL_HASH SHA256=b0528f5a1d379d59d4701cb28c36e22214cc51cf64594e5b56f2d3e6c0233095
        )

        # OpenCV uses several generic cache variables. Preserve the caller's
        # values so fetching OpenCV does not change the configuration of the
        # consuming project or dependencies configured afterwards.
        foreach(_option IN ITEMS
            BUILD_SHARED_LIBS
            BUILD_TESTS
            BUILD_PERF_TESTS
            BUILD_EXAMPLES
            BUILD_DOCS
            BUILD_PACKAGE
            BUILD_JAVA
        )
            if(DEFINED CACHE{${_option}})
                set(_opencv_saved_${_option}_defined TRUE)

                get_property(_opencv_saved_${_option}
                    CACHE ${_option}
                    PROPERTY VALUE
                )
            else()
                set(_opencv_saved_${_option}_defined FALSE)
            endif()
        endforeach()

        set(BUILD_SHARED_LIBS ON CACHE BOOL "" FORCE)
        set(BUILD_TESTS OFF CACHE BOOL "" FORCE)
        set(BUILD_PERF_TESTS OFF CACHE BOOL "" FORCE)
        set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
        set(BUILD_DOCS OFF CACHE BOOL "" FORCE)
        set(BUILD_PACKAGE OFF CACHE BOOL "" FORCE)
        set(BUILD_JAVA OFF CACHE BOOL "" FORCE)

        # OpenCV-specific options can remain pinned because they cannot affect
        # unrelated dependencies after OpenCV has been configured.
        set(BUILD_opencv_apps OFF CACHE BOOL "" FORCE)
        set(BUILD_opencv_python3 OFF CACHE BOOL "" FORCE)
        set(BUILD_opencv_js OFF CACHE BOOL "" FORCE)

        cppcmake_dependency_make_available(opencv)

        foreach(_option IN ITEMS
            BUILD_SHARED_LIBS
            BUILD_TESTS
            BUILD_PERF_TESTS
            BUILD_EXAMPLES
            BUILD_DOCS
            BUILD_PACKAGE
            BUILD_JAVA
        )
            if(_opencv_saved_${_option}_defined)
                set(
                    ${_option}
                    "${_opencv_saved_${_option}}"
                    CACHE BOOL ""
                    FORCE
                )
            else()
                unset(${_option} CACHE)
            endif()
        endforeach()

        if(ARGN)
            set(_opencv_targets)

            foreach(_component IN LISTS ARGN)
                set(_target "opencv_${_component}")

                if(NOT TARGET ${_target})
                    message(
                        FATAL_ERROR
                        "OpenCV component '${_component}' did not create target '${_target}'"
                    )
                endif()

                list(APPEND _opencv_targets ${_target})
            endforeach()

            set(${OUT_TARGETS} "${_opencv_targets}" PARENT_SCOPE)
            return()
        endif()

        set(${OUT_TARGETS} "${OpenCVModules_TARGETS}" PARENT_SCOPE)
        return()
    endif()

    set(${OUT_TARGETS} "${OpenCV_LIBS}" PARENT_SCOPE)
endfunction()
