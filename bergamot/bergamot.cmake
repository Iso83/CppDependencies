include_guard(GLOBAL)

include(FetchContent)

function(_cppdependencies_bergamot_msvc TARGET_NAME SCOPE)
    if(NOT MSVC)
        return()
    endif()

    get_target_property(aliased_target ${TARGET_NAME} ALIASED_TARGET)
    if(aliased_target)
        set(TARGET_NAME ${aliased_target})
    endif()

    # Marian's thread pool still uses result_of; keep the project at C++20.
    target_compile_definitions(${TARGET_NAME} ${SCOPE} _HAS_DEPRECATED_RESULT_OF=1)
    
    # Old fmt references stdext iterators removed in MSVC 14.5x. Adapt only
    # fmt's pointer helper, without disabling STL iterator checks or editing it.
    target_compile_options(${TARGET_NAME} ${SCOPE}
        "$<$<COMPILE_LANGUAGE:CXX>:/FI${CMAKE_CURRENT_FUNCTION_LIST_DIR}/compat/BergamotMsvc.h>"
    )
endfunction()

# Apply a pinned source adaptation once; never silently accept upstream drift.
function(_cppdependencies_bergamot_replace FILE_PATH ORIGINAL REPLACEMENT)
    file(READ "${FILE_PATH}" content)
    string(REPLACE "\r\n" "\n" content "${content}")
    string(FIND "${content}" "${REPLACEMENT}" replacement_position)
    if(NOT replacement_position LESS 0)
        return()
    endif()

    string(FIND "${content}" "${ORIGINAL}" original_position)
    if(original_position LESS 0)
        message(FATAL_ERROR
            "CppDependencies Bergamot: unexpected source in ${FILE_PATH}"
        )
    endif()

    string(REPLACE "${ORIGINAL}" "${REPLACEMENT}" content "${content}")
    file(WRITE "${FILE_PATH}" "${content}")
endfunction()

function(cppdependencies_bergamot OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides (native CPU) Bergamot dependency target.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the selected library target name.
    #
    # Options:
    #   STATIC - Link the static library.
    #   SHARED - Link the shared library/DLL (default).
    # =========================================================

    cmake_parse_arguments(PARSE_ARGV 1 ARG "STATIC;SHARED" "" "")

    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "cppdependencies_bergamot: unsupported arguments: ${ARG_UNPARSED_ARGUMENTS}"
        )
    endif()

    if(ARG_STATIC AND ARG_SHARED)
        message(FATAL_ERROR
            "cppdependencies_bergamot: choose either STATIC or SHARED"
        )
    endif()

    if(ARG_STATIC)
        set(linkage STATIC)
        set(suffix static)
    else()
        set(linkage SHARED)
        set(suffix shared)
    endif()

    set(adapter cppdependencies_bergamot_${suffix})
    set(result_target CppDependencies::bergamot_${suffix})
    if(TARGET ${result_target})
        set(${OUT_TARGET} ${result_target} PARENT_SCOPE)
        return()
    endif()

    set(backend "")
    set(candidates
        bergamot-translator-${suffix}
        bergamot::bergamot-translator-${suffix}
        bergamot-translator::bergamot-translator-${suffix}
        bergamot-translator
        bergamot::bergamot-translator
        bergamot-translator::bergamot-translator
    )
    foreach(pass IN ITEMS existing package)
        if(pass STREQUAL "package")
            find_package(bergamot-translator CONFIG QUIET)
        endif()

        foreach(candidate IN LISTS candidates)
            if(NOT TARGET ${candidate})
                continue()
            endif()
            get_target_property(type ${candidate} TYPE)
            # Neither an INTERFACE nor UNKNOWN target proves the linkage.
            if(type STREQUAL "${linkage}_LIBRARY")
                set(backend ${candidate})
                break()
            endif()
        endforeach()

        if(backend)
            break()
        endif()
    endforeach()

    if(backend)
        add_library(${adapter} INTERFACE)
        target_link_libraries(${adapter} INTERFACE ${backend})
        _cppdependencies_bergamot_msvc(${adapter} INTERFACE)
        add_library(${result_target} ALIAS ${adapter})
        message(STATUS
            "CppDependencies Bergamot: ${linkage} target '${backend}'"
        )
        set(${OUT_TARGET} ${result_target} PARENT_SCOPE)
        return()
    endif()

    if(bergamot-translator_FOUND OR TARGET bergamot-translator)
        message(FATAL_ERROR
            "cppdependencies_bergamot: existing package/source target does not provide ${linkage}. "
            "Select a matching package or use a fresh build with the requested linkage."
        )
    endif()

    # Upstream fixes the main library to STATIC. Adapt its fetched CMake
    # declaration; BUILD_SHARED_LIBS alone cannot select a shared Bergamot.
    set(CPPDEPENDENCIES_BERGAMOT_LINKAGE ${linkage})
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)

    # The pinned upstream dependencies predate CMake 4's policy floor.
    set(CMAKE_POLICY_VERSION_MINIMUM 3.5)
    set(COMPILE_WASM OFF CACHE BOOL "Native CPU build")
    set(USE_WASM_COMPATIBLE_SOURCE ON CACHE BOOL "Minimal native inference sources")
    set(COMPILE_WITHOUT_EXCEPTIONS OFF CACHE BOOL "Report model failures as exceptions")
    set(COMPILE_CUDA OFF CACHE BOOL "CPU inference")
    set(USE_MKL OFF CACHE BOOL "Use bundled CPU kernels")
    set(USE_DOXYGEN OFF CACHE BOOL "No upstream documentation build")
    set(COMPILE_PYTHON OFF CACHE BOOL "No Python bindings")
    set(COMPILE_TESTS OFF CACHE BOOL "No upstream test programs")
    set(COMPILE_UNIT_TESTS OFF CACHE BOOL "No upstream unit tests")
    
    # Scope this to dependency configuration; root CTest remains enabled.
    set(BUILD_TESTING OFF)
    set(COMPILE_MAIN_EIGEN ON CACHE BOOL "Only Eigen headers; no dependency tools or docs")
    set(COMPILE_LIBRARY_ONLY ON CACHE BOOL "No upstream tools")
    set(SSPLIT_COMPILE_LIBRARY_ONLY ON CACHE BOOL "No splitter tools")
    set(SSPLIT_USE_INTERNAL_PCRE2 OFF CACHE BOOL "Resolve PCRE2 through CMake")
    set(BUILD_ARCH x86-64 CACHE STRING "Portable x64 CPU baseline")

    find_library(PCRE2_LIBRARIES NAMES pcre2-8 pcre2-8-static)
    find_path(PCRE2_INCLUDE_DIRS pcre2.h)
    if(NOT PCRE2_LIBRARIES OR NOT PCRE2_INCLUDE_DIRS)
        set(PCRE2_BUILD_TESTS OFF CACHE BOOL "No PCRE2 tests")
        set(PCRE2_BUILD_PCRE2GREP OFF CACHE BOOL "No PCRE2 tools")
        set(PCRE2_BUILD_PCRE2_8 ON CACHE BOOL "8-bit splitter API")
        set(PCRE2_BUILD_PCRE2_16 OFF CACHE BOOL "No 16-bit API")
        set(PCRE2_BUILD_PCRE2_32 OFF CACHE BOOL "No 32-bit API")
        set(BUILD_SHARED_LIBS OFF)
        FetchContent_Declare(
            pcre2
            GIT_REPOSITORY https://github.com/PCRE2Project/pcre2.git
            GIT_TAG pcre2-10.39
            GIT_SHALLOW TRUE
        )
        cppcmake_dependency_make_available(pcre2)
        set(PCRE2_LIBRARIES pcre2-8-static)
        set(PCRE2_INCLUDE_DIRS "${pcre2_BINARY_DIR}")
    endif()

    FetchContent_Declare(
        bergamot
        GIT_REPOSITORY https://github.com/browsermt/bergamot-translator.git
        GIT_TAG 9271618ebbdc5d21ac4dc4df9e72beb7ce644774
        SOURCE_SUBDIR cppdependencies-download-only
    )
    cppcmake_dependency_make_available(bergamot)
    FetchContent_GetProperties(bergamot
        SOURCE_DIR source_dir
        BINARY_DIR binary_dir
    )

    set(target_file "${source_dir}/src/translator/CMakeLists.txt")
    file(READ "${target_file}" original)
    set(declaration "add_library(bergamot-translator STATIC")
    set(adapted "add_library(bergamot-translator \${CPPDEPENDENCIES_BERGAMOT_LINKAGE}")
    string(FIND "${original}" "${declaration}" original_position)
    string(FIND "${original}" "${adapted}" adapted_position)
    if(original_position LESS 0 AND adapted_position LESS 0)
        message(FATAL_ERROR
            "cppdependencies_bergamot: unexpected upstream target declaration"
        )
    endif()

    string(REPLACE "${declaration}" "${adapted}" content "${original}")
    if(NOT content STREQUAL original)
        file(WRITE "${target_file}" "${content}")
    endif()

    # Keep service destruction and logger registration/cleanup in the library.
    # An inline destructor in a Windows consumer can otherwise use its own
    # header-only spdlog registry, leaving the DLL's logger registered.
    _cppdependencies_bergamot_replace("${source_dir}/src/translator/service.h"
        "  BlockingService(const BlockingService::Config &config);"
        "  BlockingService(const BlockingService::Config &config);\n  ~BlockingService();"
    )
    _cppdependencies_bergamot_replace("${source_dir}/src/translator/logging.h"
        [=[  Logger(const Config &config) : marianLoggers_(createLoggers()) {
    // We are manually creating loggers, because this is usually created in marian as a side-effect of
    // config-parsing.
    for (auto &logger : marianLoggers_) {
      setLoggingLevel(*logger, config.level);
    }
  }]=]
        "  Logger(const Config &config);"
    )
    _cppdependencies_bergamot_replace("${source_dir}/src/translator/logging.h"
        [=[  ~Logger() {
    // We need to manually destroy the loggers, as marian doesn't do
    // that but will complain when a new marian::Config tries to
    // initialise loggers with the same name.
    for (auto &logger : marianLoggers_) {
      if (logger) {
        spdlog::drop(logger->name());
      }
    }
  }]=]
        "  ~Logger();"
    )

    # The pinned spdlog uses constructor template-ids rejected in C++20.
    # Normalize just these declarations; do not change logging behavior.
    set(registry_header "${source_dir}/3rd_party/marian-dev/src/3rd_party/spdlog/details/registry.h")
    _cppdependencies_bergamot_replace("${registry_header}"
        "    registry_t<Mutex>() {}"
        "    registry_t() {}"
    )
    _cppdependencies_bergamot_replace("${registry_header}"
        "    registry_t<Mutex>(const registry_t<Mutex>&) = delete;"
        "    registry_t(const registry_t<Mutex>&) = delete;"
    )

    cppcmake_dependency_add_subdirectory("${source_dir}" "${binary_dir}" EXCLUDE_FROM_ALL)
    target_sources(bergamot-translator PRIVATE
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/compat/BergamotService.cpp"
    )

    get_target_property(type bergamot-translator TYPE)
    if(NOT type STREQUAL "${linkage}_LIBRARY")
        message(FATAL_ERROR
            "cppdependencies_bergamot: source build did not provide ${linkage}"
        )
    endif()

    if(linkage STREQUAL "SHARED")
        set_target_properties(bergamot-translator PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON)
    endif()

    _cppdependencies_bergamot_msvc(marian PRIVATE)
    _cppdependencies_bergamot_msvc(bergamot-translator PUBLIC)
    cppcmake_dependency_set_folder(bergamot-translator "bergamot")
    add_library(${result_target} ALIAS bergamot-translator)
    set(${OUT_TARGET} ${result_target} PARENT_SCOPE)
endfunction()
