include_guard(GLOBAL)
include(FetchContent)
include("${CMAKE_CURRENT_LIST_DIR}/../jpeg/jpeg.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/../zlib/zlib.cmake")

set(CPPDEPENDENCIES_TIFF_VERSION "4.7.0")

function(cppdependencies_tiff OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides the requested static or shared libtiff target.
    # Source builds appear under third_party/tiff in the IDE.
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
            "cppdependencies_tiff: unsupported arguments: ${ARG_UNPARSED_ARGUMENTS}"
        )
    endif()

    if(ARG_STATIC AND ARG_SHARED)
        message(FATAL_ERROR 
            "cppdependencies_tiff: choose either STATIC or SHARED"
        )
    endif()

    if(ARG_STATIC)
        set(_linkage STATIC)
    else()
        set(_linkage SHARED)
    endif()

    # Upstream defines one tiff target. A source build has one linkage per
    # configuration; changing STATIC/SHARED requires reconfiguring that build.
    if(TARGET tiff)
        get_target_property(_type tiff TYPE)
        if(NOT _type STREQUAL "${_linkage}_LIBRARY")
            message(FATAL_ERROR 
                "cppdependencies_tiff: tiff already uses another linkage"
            )
        endif()

        set(${OUT_TARGET} tiff PARENT_SCOPE)
        return()
    endif()

    if(CMAKE_PREFIX_PATH AND NOT TARGET TIFF::tiff)
        # The NAS prefix contains separate static/shared package directories.
        # Ignore a cached TIFF_DIR so changing linkage selects the matching one.
        string(TOLOWER "${_linkage}" _package_directory)
        set(TIFF_DIR "TIFF_DIR-NOTFOUND")
        find_package(TIFF ${CPPDEPENDENCIES_TIFF_VERSION} CONFIG QUIET
            PATH_SUFFIXES "${_package_directory}/lib/cmake/TIFF"
        )
    endif()
    
    foreach(_candidate IN ITEMS TIFF::tiff TIFF::TIFF)
        if(TARGET ${_candidate})
            get_target_property(_type ${_candidate} TYPE)
            if(_type STREQUAL "${_linkage}_LIBRARY")
                set(${OUT_TARGET} ${_candidate} PARENT_SCOPE)
                return()
            endif()
        endif()
    endforeach()

    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    cppdependencies_zlib(CPPDEPENDENCIES_TIFF_ZLIB_TARGET ${_linkage})
    # CMake 4 GNUInstallDirs can leave the cached documentation path empty.
    # libjpeg-turbo requires a non-empty value; keep this override local.
    if(NOT CMAKE_INSTALL_DOCDIR)
        set(CMAKE_INSTALL_DOCDIR "share/doc")
    endif()
    if(NOT CMAKE_INSTALL_MANDIR)
        set(CMAKE_INSTALL_MANDIR "share/man")
    endif()
    cppdependencies_jpeg(CPPDEPENDENCIES_TIFF_JPEG_TARGET ${_linkage})
    get_target_property(_imported ${CPPDEPENDENCIES_TIFF_ZLIB_TARGET} IMPORTED)
    
    if(NOT _imported)
        set_property(TARGET ${CPPDEPENDENCIES_TIFF_ZLIB_TARGET}
            PROPERTY POSITION_INDEPENDENT_CODE ON
        )
    endif()

    FetchContent_Declare(tiff
        URL "https://download.osgeo.org/libtiff/tiff-${CPPDEPENDENCIES_TIFF_VERSION}.tar.gz"
        URL_HASH SHA256=67160e3457365ab96c5b3286a0903aa6e78bdc44c4bc737d2e486bcecb6ba976
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        SOURCE_SUBDIR cppdependencies-download-only
    )
    FetchContent_MakeAvailable(tiff)
    FetchContent_GetProperties(tiff SOURCE_DIR _source BINARY_DIR _binary)

    # Upstream normally searches the host for zlib/JPEG. Reuse the targets
    # selected above. These changes affect downloaded CMake files only and
    # remain idempotent when the project is configured again.
    foreach(_file IN ITEMS cmake/DeflateCodec.cmake cmake/JPEGCodec.cmake libtiff/CMakeLists.txt)
        set(_path "${_source}/${_file}")
        file(READ "${_path}" _original)
        set(_content "${_original}")
        if(_file STREQUAL "cmake/DeflateCodec.cmake")
            string(REPLACE "find_package(ZLIB)" "set(ZLIB_FOUND TRUE)" _content "${_content}")
        elseif(_file STREQUAL "cmake/JPEGCodec.cmake")
            string(REPLACE "find_package(JPEG)" "set(JPEG_FOUND TRUE)" _content "${_content}")
        else()
            string(REPLACE "PRIVATE ZLIB::ZLIB" "PRIVATE \${CPPDEPENDENCIES_TIFF_ZLIB_TARGET}"
                _content "${_content}"
            )
            string(REPLACE "PRIVATE JPEG::JPEG" "PRIVATE \${CPPDEPENDENCIES_TIFF_JPEG_TARGET}"
                _content "${_content}"
            )
        endif()
        if(NOT _content STREQUAL _original)
            file(WRITE "${_path}" "${_content}")
        endif()
    endforeach()

    # Respect local normal variables despite upstream's older CMake policy.
    # Disable standalone programs and optional external codecs; keep built-in
    # codecs plus Deflate and JPEG enabled for the application's roundtrip tests.
    set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)
    if(_linkage STREQUAL "SHARED")
        set(BUILD_SHARED_LIBS ON)
    else()
        set(BUILD_SHARED_LIBS OFF)
    endif()
    set(tiff-tools OFF)
    set(tiff-tests OFF)
    set(tiff-contrib OFF)
    set(tiff-docs OFF)
    set(tiff-install OFF)
    set(cxx OFF)
    set(zlib ON)
    set(jpeg ON)
    # The required libjpeg-turbo >= 3.2 already supplies the 8/12-bit API.
    # Preseed the probe: try_compile cannot link a not-yet-built source target.
    set(HAVE_JPEGTURBO_DUAL_MODE_8_12 TRUE)
    set(jpeg12 OFF)
    set(old-jpeg OFF)
    set(webp OFF)
    set(zstd OFF)
    set(lzma OFF)
    set(libdeflate OFF)
    set(lerc OFF)
    set(jbig OFF)
    add_subdirectory("${_source}" "${_binary}" EXCLUDE_FROM_ALL)

    if(NOT TARGET TIFF::TIFF)
        add_library(TIFF::TIFF ALIAS tiff)
    endif()
    foreach(_library IN ITEMS tiff tiff_port tiff_mkg3states tiff_faxtable)
        if(TARGET ${_library})
            cppcmake_dependency_set_folder(${_library} "tiff")
        endif()
    endforeach()
    
    message(STATUS "CppDependencies tiff: source ${_linkage} target 'tiff'")
    set(${OUT_TARGET} tiff PARENT_SCOPE)
endfunction()
