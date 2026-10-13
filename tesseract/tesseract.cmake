include_guard(GLOBAL)

include(FetchContent)
include("${CMAKE_CURRENT_LIST_DIR}/../leptonica/leptonica.cmake")

set(CPPDEPENDENCIES_TESSERACT_VERSION "5.5.3")
# Model revisions are independent of Tesseract's engine version.
set(CPPDEPENDENCIES_TESSDATA_REVISION "e12c65a915945e4c28e237a9b52bc4a8f39a0cec")
set(CPPDEPENDENCIES_TESSDATA_DIR "" CACHE PATH "Optional directory containing pinned tessdata")

function(cppdependencies_tesseract OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides Tesseract and its Leptonica dependency via package or source.
    # Optionally resolves the pinned Dutch tessdata_best model as well.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the selected Tesseract target.
    #
    # Options:
    #   STATIC / SHARED - Requested linkage; SHARED is the default.
    #
    # Arguments:
    #   TESSDATA_DIR <out> - Receives the validated model directory.
    #   TESSDATA_PATH <path> - Optional existing model directory (e.g. NAS).
    # =========================================================

    cmake_parse_arguments(PARSE_ARGV 1 ARG "STATIC;SHARED" "TESSDATA_DIR;TESSDATA_PATH" "")
    if(ARG_UNPARSED_ARGUMENTS OR ARG_KEYWORDS_MISSING_VALUES OR (ARG_STATIC AND ARG_SHARED))
        message(FATAL_ERROR 
            "cppdependencies_tesseract: invalid arguments"
        )
    endif()

    if(ARG_STATIC)
        set(_linkage STATIC)
        set(BUILD_SHARED_LIBS OFF)
    else()
        set(_linkage SHARED)
        set(BUILD_SHARED_LIBS ON)
    endif()

    cppdependencies_leptonica(_leptonica ${_linkage})

    if(COMMAND cppdependencies_package_tesseract)
        cppdependencies_package_tesseract(${_linkage})
    endif()

    if(NOT TARGET libtesseract AND NOT TARGET Tesseract::libtesseract)
        string(TOLOWER "${_linkage}" _directory)
        find_package(Tesseract ${CPPDEPENDENCIES_TESSERACT_VERSION} CONFIG QUIET
            PATH_SUFFIXES "${_directory}/lib/cmake/tesseract"
        )
    endif()

    foreach(_candidate IN ITEMS libtesseract Tesseract::libtesseract)
        if(TARGET ${_candidate})
            get_target_property(_type ${_candidate} TYPE)
            if(NOT _type STREQUAL "${_linkage}_LIBRARY")
                message(FATAL_ERROR 
                    "cppdependencies_tesseract: ${_candidate} has incompatible linkage"
                )
            endif()
            set(_target ${_candidate})
            break()
        endif()
    endforeach()

    if(NOT _target)
        FetchContent_Declare(tesseract
            GIT_REPOSITORY https://github.com/tesseract-ocr/tesseract.git
            GIT_TAG db0ec62f81b0737fbbe184d8fea40af5738f8eef
            SOURCE_SUBDIR cppdependencies-download-only
        )
        FetchContent_MakeAvailable(tesseract)
        FetchContent_GetProperties(tesseract SOURCE_DIR _source BINARY_DIR _binary)
        set(_path "${_source}/CMakeLists.txt")
        file(READ "${_path}" _original)
        string(REPLACE "find_package(Leptonica \${MINIMUM_LEPTONICA_VERSION} CONFIG)"
            "# Leptonica is resolved by CppDependencies." _content "${_original}")
        string(REPLACE
            "  export(\n    TARGETS libtesseract\n    FILE \${CMAKE_CURRENT_BINARY_DIR}/TesseractTargets.cmake\n    NAMESPACE Tesseract::)"
            "" _content "${_content}")
        string(REPLACE "  EXPORT TesseractTargets\n"
            "  \${_tesseract_export_argument}\n" _content "${_content}")
        string(REPLACE
            "install(\n  \${_tesseract_export_argument}\n  NAMESPACE Tesseract::\n  DESTINATION \${CMAKE_INSTALL_LIBDIR}/cmake/tesseract)"
            "if(_tesseract_export_argument)\ninstall(EXPORT TesseractTargets NAMESPACE Tesseract:: DESTINATION \${CMAKE_INSTALL_LIBDIR}/cmake/tesseract)\nendif()"
            _content "${_content}")
        if(NOT _content STREQUAL _original)
            file(WRITE "${_path}" "${_content}")
        endif()

        set(Leptonica_FOUND TRUE)
        set(Leptonica_VERSION ${CPPDEPENDENCIES_LEPTONICA_VERSION})
        set(Leptonica_LIBRARIES ${_leptonica})
        get_target_property(Leptonica_INCLUDE_DIRS ${_leptonica} INTERFACE_INCLUDE_DIRECTORIES)
        get_target_property(_imported ${_leptonica} IMPORTED)
        set(_tesseract_export_argument "")
        if(_imported)
            set(_tesseract_export_argument EXPORT TesseractTargets)
        endif()
        set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)
        set(CMAKE_POSITION_INDEPENDENT_CODE ON)
        set(BUILD_TRAINING_TOOLS OFF)
        set(BUILD_TESTS OFF)
        set(DISABLED_LEGACY_ENGINE OFF)
        set(GRAPHICS_DISABLED ON)
        set(DISABLE_ARCHIVE ON)
        set(DISABLE_CURL ON)
        set(DISABLE_TIFF ON)
        add_subdirectory("${_source}" "${_binary}" EXCLUDE_FROM_ALL)
        target_include_directories(libtesseract PUBLIC
            "$<BUILD_INTERFACE:${_binary}/include>"
            "$<INSTALL_INTERFACE:include>"
        )
        cppcmake_dependency_set_folder(libtesseract "tesseract")
        cppcmake_dependency_set_folder(tesseract "tesseract")
        set(_target libtesseract)
    endif()

    if(ARG_TESSDATA_DIR)
        if(NOT ARG_TESSDATA_PATH)
            set(ARG_TESSDATA_PATH "${CPPDEPENDENCIES_TESSDATA_DIR}")
        endif()
        if(NOT ARG_TESSDATA_PATH AND Tesseract_DIR)
            set(_installed_data "${Tesseract_DIR}/../../../share/tessdata")
            if(EXISTS "${_installed_data}/nld.traineddata")
                set(ARG_TESSDATA_PATH "${_installed_data}")
            endif()
        endif()
        cppdependencies_tesseract_tessdata(_data "${ARG_TESSDATA_PATH}")
        set(${ARG_TESSDATA_DIR} "${_data}" PARENT_SCOPE)
    endif()
    get_target_property(_imported ${_target} IMPORTED)
    if(_imported)
        message(STATUS 
            "CppDependencies tesseract: installed ${_linkage} target '${_target}'"
        )
    else()
        message(STATUS 
            "CppDependencies tesseract: source ${_linkage} (${CPPDEPENDENCIES_TESSERACT_VERSION})"
        )
    endif()
    set(${OUT_TARGET} ${_target} PARENT_SCOPE)
endfunction()


function(cppdependencies_tesseract_tessdata OUT_DIR MODEL_PATH)
    # =========================================================
    # Summary
    #
    # Resolves and verifies the pinned Dutch tessdata_best model.
    # Existing directories (including NAS) are read-only. With an empty path,
    # downloads to the build tree and installs alongside the engine package.
    #
    # Parameters:
    #   [out] OUT_DIR - Receives the validated model directory.
    #   [in] MODEL_PATH - Existing directory, or empty for a download.
    # =========================================================
    if(MODEL_PATH)
        get_filename_component(_dir "${MODEL_PATH}" ABSOLUTE)
    else()
        set(_dir "${CMAKE_BINARY_DIR}/tessdata")
        file(MAKE_DIRECTORY "${_dir}")
    endif()
    set(_model "${_dir}/nld.traineddata")
    set(_hash "92e7a1ad4bf8082e268de57c7823316ec024935702c6ed2a1e473b3a071aa733")
    if(NOT EXISTS "${_model}")
        if(MODEL_PATH)
            message(FATAL_ERROR "Tesseract: missing pinned model ${_model}")
        endif()
        file(DOWNLOAD
            "https://raw.githubusercontent.com/tesseract-ocr/tessdata_best/${CPPDEPENDENCIES_TESSDATA_REVISION}/nld.traineddata"
            "${_model}" EXPECTED_HASH "SHA256=${_hash}" TLS_VERIFY ON STATUS _status
        )
        list(GET _status 0 _code)
        if(NOT _code EQUAL 0)
            file(REMOVE "${_model}")
            message(FATAL_ERROR 
                "Tesseract: tessdata download failed: ${_status}"
            )
        endif()
    endif()
    file(SHA256 "${_model}" _actual)
    if(NOT _actual STREQUAL _hash)
        message(FATAL_ERROR 
            "Tesseract: unexpected tessdata hash: ${_model}"
        )
    endif()
    if(NOT MODEL_PATH)
        install(FILES "${_model}" DESTINATION share/tessdata)
    endif()
    set(${OUT_DIR} "${_dir}" PARENT_SCOPE)
endfunction()
