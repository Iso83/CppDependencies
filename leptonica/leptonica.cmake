include_guard(GLOBAL)

include(FetchContent)

include("${CMAKE_CURRENT_LIST_DIR}/../jpeg/jpeg.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/../png/png.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/../tiff/tiff.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/../zlib/zlib.cmake")

set(CPPDEPENDENCIES_LEPTONICA_VERSION "1.87.0")

function(cppdependencies_leptonica OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides Leptonica with PNG, TIFF, JPEG and zlib support.
    # Reuses a matching package (NAS), otherwise fetches pinned source.
    # Codec targets remain in the link graph for CppCMake DLL deployment.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the selected Leptonica target.
    #
    # Options:
    #   STATIC - Link the static library.
    #   SHARED - Link the shared library (default).
    # =========================================================

    cmake_parse_arguments(PARSE_ARGV 1 ARG "STATIC;SHARED" "" "")

    if(ARG_UNPARSED_ARGUMENTS OR ARG_KEYWORDS_MISSING_VALUES OR (ARG_STATIC AND ARG_SHARED))
        message(FATAL_ERROR 
            "cppdependencies_leptonica: choose STATIC or SHARED"
        )
    endif()

    if(ARG_STATIC)
        set(_linkage STATIC)
        set(BUILD_SHARED_LIBS OFF)
    else()
        set(_linkage SHARED)
        set(BUILD_SHARED_LIBS ON)
    endif()

    cppdependencies_zlib(_zlib ${_linkage})
    cppdependencies_png(_png ${_linkage})
    cppdependencies_jpeg(_jpeg ${_linkage})
    cppdependencies_tiff(_tiff ${_linkage})

    if(COMMAND cppdependencies_package_leptonica)
        cppdependencies_package_leptonica(${_linkage})
    endif()
    if(NOT TARGET leptonica AND NOT TARGET Leptonica::leptonica)
        string(TOLOWER "${_linkage}" _directory)
        find_package(Leptonica ${CPPDEPENDENCIES_LEPTONICA_VERSION} CONFIG QUIET
            PATH_SUFFIXES "${_directory}/lib/cmake/leptonica"
        )
    endif()

    foreach(_candidate IN ITEMS leptonica Leptonica::leptonica)
        if(TARGET ${_candidate})
            get_target_property(_type ${_candidate} TYPE)
            if(NOT _type STREQUAL "${_linkage}_LIBRARY")
                message(FATAL_ERROR 
                    "cppdependencies_leptonica: ${_candidate} has incompatible linkage"
                )
            endif()
            get_target_property(_real ${_candidate} ALIASED_TARGET)
            if(NOT _real)
                set(_real ${_candidate})
            endif()

            # Upstream shared packages hide PRIVATE codec dependencies. Keep
            # them visible to TARGET_RUNTIME_DLLS without searching DLL paths.
            get_target_property(_configured ${_real} CPPDEPENDENCIES_CODECS)
            if(NOT _configured)
                target_link_libraries(${_real} INTERFACE ${_zlib} ${_png} ${_jpeg} ${_tiff})
                set_property(TARGET ${_real} PROPERTY CPPDEPENDENCIES_CODECS TRUE)
            endif()
            get_target_property(_imported ${_real} IMPORTED)
            if(_imported)
                message(STATUS 
                    "CppDependencies leptonica: installed ${_linkage} target '${_candidate}'"
                )
            else()
                message(STATUS 
                    "CppDependencies leptonica: existing ${_linkage} target '${_candidate}'"
                )
            endif()
            
            set(${OUT_TARGET} ${_candidate} PARENT_SCOPE)
            return()
        endif()
    endforeach()

    FetchContent_Declare(leptonica
        GIT_REPOSITORY https://github.com/DanBloomberg/leptonica.git
        GIT_TAG 13275a278eb55b5746e33f95fbf5a2c8f604b3ab
        SOURCE_SUBDIR cppdependencies-download-only
    )
    FetchContent_MakeAvailable(leptonica)
    FetchContent_GetProperties(leptonica SOURCE_DIR _source BINARY_DIR _binary)

    # Upstream searches the host instead of using the selected codec targets,
    # and uses top-level paths in src/. Adapt downloaded CMake only.
    set(_path "${_source}/CMakeLists.txt")
    file(READ "${_path}" _original)
    set(_content "${_original}")
    foreach(_codec IN ITEMS ZLIB PNG JPEG TIFF)
        string(REGEX REPLACE
            "find_and_handle_library\\(${_codec} [^)]*\\)"
            "set(${_codec}_FOUND TRUE)" _content "${_content}"
        )
    endforeach()
    if(NOT _content STREQUAL _original)
        file(WRITE "${_path}" "${_content}")
    endif()

    set(_path "${_source}/src/CMakeLists.txt")
    file(READ "${_path}" _original)
    string(REPLACE "CMAKE_BINARY_DIR" "PROJECT_BINARY_DIR" _content "${_original}")
    # Build-tree export cannot include codec targets from separate export sets.
    string(REPLACE
        "export(TARGETS leptonica FILE \${PROJECT_BINARY_DIR}/LeptonicaTargets.cmake)"
        "# Build-tree consumers use the existing target." _content "${_content}"
    )
    string(REPLACE "  EXPORT LeptonicaTargets"
        "  \${_leptonica_export_argument}" _content "${_content}")
    string(FIND "${_content}" "if(_leptonica_export_argument)" _guard)
    if(_guard LESS 0)
        string(REPLACE "install(EXPORT LeptonicaTargets DESTINATION \${leptonica_INSTALL_CMAKE_DIR})"
            "if(_leptonica_export_argument)\ninstall(EXPORT LeptonicaTargets DESTINATION \${leptonica_INSTALL_CMAKE_DIR})\nendif()"
            _content "${_content}"
        )
    endif()
    if(NOT _content STREQUAL _original)
        file(WRITE "${_path}" "${_content}")
    endif()

    # The installed export references codec targets, so its config must load
    # their packages before loading LeptonicaTargets.cmake as well.
    set(_path "${_source}/cmake/templates/LeptonicaConfig.cmake.in")
    file(READ "${_path}" _original)
    string(FIND "${_original}" "find_dependency(libjpeg-turbo CONFIG)" _guard)
    if(_guard LESS 0)
        string(REPLACE "include(CMakeFindDependencyMacro)"
            "include(CMakeFindDependencyMacro)\nfind_dependency(ZLIB CONFIG)\nfind_dependency(PNG CONFIG)\nfind_dependency(libjpeg-turbo CONFIG)\nfind_dependency(TIFF CONFIG)"
            _content "${_original}"
        )
        file(WRITE "${_path}" "${_content}")
    endif()

    # Installable exports remain enabled for the BuildFarm route with imported
    # codecs. A composed source build uses live targets, not an install package.
    set(_leptonica_export_argument EXPORT LeptonicaTargets)
    foreach(_codec IN ITEMS ${_zlib} ${_png} ${_jpeg} ${_tiff})
        get_target_property(_imported ${_codec} IMPORTED)
        if(NOT _imported)
            set(_leptonica_export_argument "")
        endif()
    endforeach()
    set(ZLIB_LIBRARIES ${_zlib})
    set(PNG_LIBRARIES ${_png})
    set(JPEG_LIBRARIES ${_jpeg})
    set(TIFF_LIBRARIES ${_tiff})
    set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    set(BUILD_PROG OFF)
    set(SW_BUILD OFF)
    set(STRICT_CONF ON)
    set(SYM_LINK OFF)
    set(ENABLE_ZLIB ON)
    set(ENABLE_PNG ON)
    set(ENABLE_JPEG ON)
    set(ENABLE_TIFF ON)
    set(ENABLE_GIF OFF)
    set(ENABLE_WEBP OFF)
    set(ENABLE_OPENJPEG OFF)
    add_subdirectory("${_source}" "${_binary}" EXCLUDE_FROM_ALL)

    target_include_directories(leptonica PUBLIC
        "$<BUILD_INTERFACE:${_source}/src>"
        "$<BUILD_INTERFACE:${_binary}/src>"
        "$<INSTALL_INTERFACE:include/leptonica>"
    )
    target_link_libraries(leptonica INTERFACE ${_zlib} ${_png} ${_jpeg} ${_tiff})
    set_property(TARGET leptonica PROPERTY CPPDEPENDENCIES_CODECS TRUE)
    cppcmake_dependency_set_folder(leptonica "leptonica")
    
    message(STATUS 
        "CppDependencies leptonica: source ${_linkage} (${CPPDEPENDENCIES_LEPTONICA_VERSION})"
    )
    set(${OUT_TARGET} leptonica PARENT_SCOPE)
endfunction()
