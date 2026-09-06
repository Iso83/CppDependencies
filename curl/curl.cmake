include_guard(GLOBAL)

include(FetchContent)

function(cppdependencies_curl OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides the curl dependency target.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the curl target name.
    # =========================================================

    if(TARGET CURL::libcurl)
        set(${OUT_TARGET} CURL::libcurl PARENT_SCOPE)
        return()
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

    # Yahoo Finance is HTTPS-only. curl does not select a Windows TLS backend
    # automatically in every FetchContent configuration, so use the native
    # Windows certificate store explicitly.
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

    set(${OUT_TARGET} CURL::libcurl PARENT_SCOPE)
endfunction()