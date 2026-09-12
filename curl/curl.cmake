include_guard(GLOBAL)

include(FetchContent)

set(CPPDEPENDENCIES_CURL_VERSION "8.21.0")

function(cppdependencies_curl OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides the requested static or shared curl dependency target.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the selected curl target name.
    #
    # Options:
    #   STATIC - Link curl statically into the consuming target.
    #   SHARED - Link against the curl shared library/DLL.
    #            This is the default when neither option is specified.
    # =========================================================

    cmake_parse_arguments(PARSE_ARGV 1 ARG "STATIC;SHARED" "" "")

    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "cppdependencies_curl: unsupported arguments: ${ARG_UNPARSED_ARGUMENTS}"
        )
    endif()

    if(ARG_STATIC AND ARG_SHARED)
        message(FATAL_ERROR
            "cppdependencies_curl: choose either STATIC or SHARED"
        )
    endif()

    if(ARG_STATIC)
        set(_curl_target CURL::libcurl_static)
    else()
        set(_curl_target CURL::libcurl_shared)
    endif()

    if(TARGET ${_curl_target})
        set(${OUT_TARGET} ${_curl_target} PARENT_SCOPE)
        return()
    endif()

    find_package(
        CURL ${CPPDEPENDENCIES_CURL_VERSION}
        CONFIG
        QUIET
    )

    if(TARGET ${_curl_target})
        set(${OUT_TARGET} ${_curl_target} PARENT_SCOPE)
        return()
    endif()

    if(TARGET CURL::libcurl)
        message(FATAL_ERROR
            "cppdependencies_curl: the installed CURL package does not "
            "provide the requested target '${_curl_target}'"
        )
    endif()

    if(NOT TARGET ${_curl_target})
        # Keep curl's linkage selection local to this function. In particular,
        # do not let curl create or overwrite BUILD_SHARED_LIBS in the parent
        # project cache: add_library() in the consuming project must retain its
        # own default or explicitly selected linkage.
        if(ARG_STATIC)
            set(BUILD_SHARED_LIBS OFF)
            set(BUILD_STATIC_LIBS ON)
        else()
            set(BUILD_SHARED_LIBS ON)
            set(BUILD_STATIC_LIBS OFF)
        endif()

        set(BUILD_CURL_EXE OFF CACHE BOOL "" FORCE)
        set(CURL_DISABLE_INSTALL ON CACHE BOOL "" FORCE)

        set(BUILD_LIBCURL_DOCS OFF CACHE BOOL "" FORCE)
        set(ENABLE_CURL_MANUAL OFF CACHE BOOL "" FORCE)

        set(CURL_ZLIB OFF CACHE STRING "" FORCE)
        set(CURL_BROTLI OFF CACHE STRING "" FORCE)
        set(CURL_ZSTD OFF CACHE STRING "" FORCE)

        set(CURL_USE_LIBPSL OFF CACHE BOOL "" FORCE)
        set(CURL_USE_LIBIDN2 OFF CACHE BOOL "" FORCE)
        set(USE_NGHTTP2 OFF CACHE BOOL "" FORCE)

        if(WIN32)
            set(CURL_USE_SCHANNEL ON CACHE BOOL "" FORCE)
            set(CURL_USE_OPENSSL OFF CACHE BOOL "" FORCE)
        endif()

        set(CURL_DISABLE_HTTP OFF CACHE BOOL "" FORCE)

        FetchContent_Declare(
            curl
            URL https://github.com/curl/curl/releases/download/curl-8_21_0/curl-8.21.0.tar.xz
            URL_HASH SHA256=aa1b66a70eace83dc624508745646c08ae561de512ab403adffb93ac87fc72e6
        )

        # curl uses these generic cache variables. Preserve the caller's values
        # so fetching curl does not change the configuration of other projects.
        foreach(_option IN ITEMS
            BUILD_EXAMPLES
            BUILD_TESTING
            BUILD_MISC_DOCS
        )
            if(DEFINED CACHE{${_option}})
                set(_curl_saved_${_option}_defined TRUE)

                get_property(_curl_saved_${_option}
                    CACHE ${_option}
                    PROPERTY VALUE
                )
            else()
                set(_curl_saved_${_option}_defined FALSE)
            endif()

            set(${_option} OFF CACHE BOOL "" FORCE)
        endforeach()

        cppcmake_dependency_make_available(curl)

        foreach(_option IN ITEMS
            BUILD_EXAMPLES
            BUILD_TESTING
            BUILD_MISC_DOCS
        )
            if(_curl_saved_${_option}_defined)
                set(
                    ${_option}
                    "${_curl_saved_${_option}}"
                    CACHE BOOL ""
                    FORCE
                )
            else()
                unset(${_option} CACHE)
            endif()
        endforeach()

        cppcmake_dependency_set_folder(libcurl_object "curl")
        cppcmake_dependency_set_folder(libcurl_static "curl")
        cppcmake_dependency_set_folder(libcurl_shared "curl")
    endif()

    if(NOT TARGET ${_curl_target})
        message(FATAL_ERROR
            "cppdependencies_curl: curl did not create the requested "
            "target '${_curl_target}'"
        )
    endif()

    set(${OUT_TARGET} ${_curl_target} PARENT_SCOPE)
endfunction()
