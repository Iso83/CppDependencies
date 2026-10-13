include_guard(GLOBAL)

include(FetchContent)
include("${CMAKE_CURRENT_LIST_DIR}/../jpeg/jpeg.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/../zlib/zlib.cmake")

set(CPPDEPENDENCIES_PDFIUM_VERSION "2026.10.11")
set(CPPDEPENDENCIES_PDFIUM_REVISION "59ea54cce0179db3269c4c58874249597ca3b118")

function(cppdependencies_pdfium OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides PDFium dependency target.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the selected PDFium target.
    #
    # Options:
    #   STATIC - Link the static library.
    #   SHARED - Link the shared library (default).
    #
    # Source profile:
    #   AGG rendering, FreeType, ICU, JPEG, JPX, JBIG2 and Deflate.
    #   JavaScript, XFA, Skia and Rust are excluded.
    #   One source linkage per CMake configuration, like TIFF.
    # =========================================================

    cmake_parse_arguments(PARSE_ARGV 1 ARG "STATIC;SHARED" "" "")

    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "cppdependencies_pdfium: unsupported arguments: ${ARG_UNPARSED_ARGUMENTS}"
        )
    endif()

    if(ARG_STATIC AND ARG_SHARED)
        message(FATAL_ERROR 
            "cppdependencies_pdfium: choose either STATIC or SHARED"
        )
    endif()

    if(ARG_STATIC)
        set(_linkage STATIC)
        set(_package_target PDFium::pdfium_static)
    else()
        set(_linkage SHARED)
        set(_package_target PDFium::pdfium_shared)
    endif()

    if(TARGET pdfium)
        get_target_property(_type pdfium TYPE)
        if(NOT _type STREQUAL "${_linkage}_LIBRARY")
            message(FATAL_ERROR 
                "cppdependencies_pdfium: source target already uses another linkage"
            )
        endif()
        set(${OUT_TARGET} pdfium PARENT_SCOPE)
        return()
    endif()

    if(CMAKE_PREFIX_PATH AND NOT TARGET ${_package_target})
        string(TOLOWER "${_linkage}" _directory)
        set(PDFium_DIR "PDFium_DIR-NOTFOUND")
        find_package(PDFium ${CPPDEPENDENCIES_PDFIUM_VERSION} CONFIG QUIET
            PATH_SUFFIXES "${_directory}/lib/cmake/PDFium"
        )
    endif()

    foreach(_candidate IN ITEMS ${_package_target} PDFium::pdfium)
        if(TARGET ${_candidate})
            get_target_property(_type ${_candidate} TYPE)
            if(_type STREQUAL "${_linkage}_LIBRARY")
                set(${OUT_TARGET} ${_candidate} PARENT_SCOPE)
                return()
            endif()
        endif()
    endforeach()

    # Pin the engine and its Chromium dependencies together. These archives
    # contain source/header/data files; none contains a prebuilt PDFium library.
    FetchContent_Declare(pdfium
        URL "https://pdfium.googlesource.com/pdfium/+archive/${CPPDEPENDENCIES_PDFIUM_REVISION}.tar.gz"
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        SOURCE_SUBDIR cppdependencies-source-only
    )
    FetchContent_Declare(pdfium_build_headers
        URL "https://chromium.googlesource.com/chromium/src/build/+archive/ebdaeefa62db7c40f27cacb0eb034db3a5cdb849.tar.gz"
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        SOURCE_SUBDIR cppdependencies-source-only
    )
    FetchContent_Declare(pdfium_icu
        URL "https://chromium.googlesource.com/chromium/deps/icu/+archive/5aa526207171ecadf31597f0980a7b7ad8872f33.tar.gz"
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        SOURCE_SUBDIR cppdependencies-source-only
    )
    FetchContent_Declare(pdfium_fast_float
        URL "https://chromium.googlesource.com/external/github.com/fastfloat/fast_float/+archive/b0ab987b3dfdde13fa1915f65ef2a5c068d9208c.tar.gz"
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        SOURCE_SUBDIR cppdependencies-source-only
    )
    FetchContent_Declare(pdfium_dragonbox
        URL "https://chromium.googlesource.com/external/github.com/jk-jeon/dragonbox/+archive/beeeef91cf6fef89a4d4ba5e95d47ca64ccb3a44.tar.gz"
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        SOURCE_SUBDIR cppdependencies-source-only
    )
    FetchContent_Declare(pdfium_abseil
        URL "https://chromium.googlesource.com/chromium/src/third_party/abseil-cpp/+archive/a00d74bb55b38f213a3c6110b4bcab5bb565bd56.tar.gz"
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        EXCLUDE_FROM_ALL
    )
    FetchContent_Declare(pdfium_harfbuzz
        URL "https://github.com/harfbuzz/harfbuzz/archive/ff36703b95013ec1d437e6038e1aa7c881275f4e.tar.gz"
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        EXCLUDE_FROM_ALL
    )
    FetchContent_Declare(pdfium_freetype
        URL "https://github.com/freetype/freetype/archive/refs/tags/VER-2-13-3.tar.gz"
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    )

    # Abseil has its own CMake project. Keep its settings local to this call.
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    set(CMAKE_FOLDER "${CPPCMAKE_PROJECT_IDE_THIRD_PARTY_FOLDER}/pdfium")
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)
    set(BUILD_SHARED_LIBS OFF)
    set(ABSL_BUILD_TESTING OFF)
    set(ABSL_USE_FOLDERS OFF)
    set(ABSL_IDE_FOLDER "${CMAKE_FOLDER}/Abseil")
    set(ABSL_PROPAGATE_CXX_STD ON)
    set(ABSL_ENABLE_INSTALL ON)
    set(CMAKE_CXX_STANDARD 20)
    
    # HarfBuzz is used for font subsetting. Disable utilities and bindings;
    # its optional Python discovery is for tests, which this build excludes.
    set(CMAKE_DISABLE_FIND_PACKAGE_Python3 TRUE)
    set(BUILD_TESTING OFF)
    set(HB_BUILD_UTILS OFF)
    set(HB_BUILD_SUBSET ON)
    set(HB_BUILD_RASTER OFF)
    set(HB_BUILD_VECTOR OFF)
    set(HB_BUILD_GPU OFF)
    set(HB_HAVE_GOBJECT OFF)
    set(HB_HAVE_INTROSPECTION OFF)
    FetchContent_MakeAvailable(pdfium pdfium_build_headers pdfium_icu
        pdfium_fast_float pdfium_dragonbox pdfium_abseil pdfium_harfbuzz
    )

    # libjpeg-turbo requires explicit documentation paths with CMake 4.
    if(NOT CMAKE_INSTALL_DOCDIR)
        set(CMAKE_INSTALL_DOCDIR "share/doc")
    endif()
    if(NOT CMAKE_INSTALL_MANDIR)
        set(CMAKE_INSTALL_MANDIR "share/man")
    endif()
    cppdependencies_jpeg(_jpeg STATIC)
    cppdependencies_zlib(_zlib STATIC)

    # FreeType's CMake build supports this source-only, no-optional-codecs
    # profile. PDFium handles PDF image compression itself.
    if(NOT TARGET Freetype::Freetype AND NOT TARGET freetype)
        set(FT_DISABLE_ZLIB ON)
        set(FT_DISABLE_BZIP2 ON)
        set(FT_DISABLE_PNG ON)
        set(FT_DISABLE_HARFBUZZ ON)
        set(FT_DISABLE_BROTLI ON)
        FetchContent_MakeAvailable(pdfium_freetype)
    endif()
    if(TARGET Freetype::Freetype)
        set(_freetype Freetype::Freetype)
    else()
        set(_freetype freetype)
    endif()

    # Another dependency may have created these static source targets before
    # this call. They still need PIC when linked into a shared PDFium library.
    foreach(_source_target IN ITEMS jpeg-static zlibstatic freetype)
        if(TARGET ${_source_target})
            get_target_property(_imported ${_source_target} IMPORTED)
            if(NOT _imported)
                set_property(TARGET ${_source_target} PROPERTY POSITION_INDEPENDENT_CODE ON)
            endif()
        endif()
    endforeach()

    # PDFium includes these headers using Chromium directory names. Recreate
    # only the header layout in the binary tree; leave fetched sources intact.
    set(_includes "${pdfium_BINARY_DIR}/include")
    file(MAKE_DIRECTORY "${_includes}/build")
    configure_file("${pdfium_build_headers_SOURCE_DIR}/build_config.h"
        "${_includes}/build/build_config.h" COPYONLY
    )
    configure_file("${pdfium_build_headers_SOURCE_DIR}/buildflag.h"
        "${_includes}/build/buildflag.h" COPYONLY
    )
    file(COPY "${pdfium_abseil_SOURCE_DIR}/absl"
        DESTINATION "${_includes}/third_party/abseil-cpp"
    )
    file(COPY "${pdfium_fast_float_SOURCE_DIR}/include"
        DESTINATION "${_includes}/third_party/fast_float/src"
    )
    file(COPY "${pdfium_dragonbox_SOURCE_DIR}/include"
        DESTINATION "${_includes}/third_party/dragonbox/src"
    )
    file(COPY "${pdfium_icu_SOURCE_DIR}/source/common/unicode"
        DESTINATION "${_includes}/third_party/icu/source/common"
    )

    if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        # Upstream assumes clang-cl on Windows. Adapt its compiler intrinsics
        # and allocator rebinding for native cl.exe and the MSVC Debug STL.
        # Generate copies in the binary tree; do not patch fetched sources.
        file(READ "${pdfium_SOURCE_DIR}/core/fxcrt/byteorder.h" _byteorder)
        string(REPLACE
            [=[#error "MSVC is not supported."
#else
  return __builtin_bswap16(x);]=]
            [=[  return static_cast<uint16_t>((x >> 8) | (x << 8));
#else
  return __builtin_bswap16(x);]=]
            _byteorder "${_byteorder}"
        )
        string(REPLACE
            [=[#error "MSVC is not supported."
#else
  return __builtin_bswap32(x);]=]
            [=[  return ((x & 0x000000ffu) << 24) | ((x & 0x0000ff00u) << 8) |
         ((x & 0x00ff0000u) >> 8) | ((x & 0xff000000u) >> 24);
#else
  return __builtin_bswap32(x);]=]
            _byteorder "${_byteorder}"
        )
        if(_byteorder MATCHES "MSVC is not supported")
            message(FATAL_ERROR "cppdependencies_pdfium: review the MSVC byteorder adaptation for this revision")
        endif()

        file(READ "${pdfium_SOURCE_DIR}/core/fxcrt/immediate_crash.h" _crash)
        string(REPLACE [=[#include "build/build_config.h"]=]
            [=[#include "build/build_config.h"
#include <intrin.h>]=] _crash "${_crash}"
        )
        string(REPLACE
            [=[#elif defined(COMPILER_MSVC)

#if defined(ARCH_CPU_ARM64)]=]
            [=[#elif defined(COMPILER_MSVC) && !defined(__clang__)

// FAST_FAIL_FATAL_APP_EXIT: terminate even if a debugger continues execution.
#define TRAP_SEQUENCE1_() __fastfail(7)
#define TRAP_SEQUENCE2_() ((void)0)

#elif defined(COMPILER_MSVC)

#if defined(ARCH_CPU_ARM64)]=]
            _crash "${_crash}"
        )
        if(NOT _crash MATCHES "__fastfail\\(7\\)")
            message(FATAL_ERROR "cppdependencies_pdfium: review the MSVC crash adaptation for this revision")
        endif()

        # Use upstream's portable checked arithmetic instead of GCC/Clang
        # attributes and overflow builtins. Overflow checks remain enabled.
        file(READ "${pdfium_SOURCE_DIR}/core/fxcrt/numerics/safe_math_shared_impl.h" _safe_math)
        string(REPLACE
            "#if defined(__asmjs__) || defined(__wasm__)"
            "#if defined(__asmjs__) || defined(__wasm__) || (defined(COMPILER_MSVC) && !defined(__clang__))"
            _safe_math "${_safe_math}"
        )

        # MSVC's Debug STL rebinds allocators to pointer-bearing bookkeeping
        # objects. Allocate those in the general partition, while preserving
        # the numeric-only check for the original data allocator.
        file(READ "${pdfium_SOURCE_DIR}/core/fxcrt/fx_memory_wrappers.h" _allocator)
        string(REPLACE
            "template <class T, void* Alloc(size_t, size_t), void Free(void*)>"
            "template <class T, void* Alloc(size_t, size_t), void Free(void*), bool DataPartition = true>"
            _allocator "${_allocator}"
        )
        string(REPLACE
            "static_assert(std::is_arithmetic<T>::value || std::is_enum<T>::value ||"
            "static_assert(!DataPartition || std::is_arithmetic<T>::value || std::is_enum<T>::value ||"
            _allocator "${_allocator}"
        )
        string(REPLACE
            "using other = FxPartitionAllocAllocator<U, Alloc, Free>;"
            "using other = FxPartitionAllocAllocator<U, Alloc, Free,\n        std::is_arithmetic<U>::value || std::is_enum<U>::value ||\n        IsFXDataPartitionException<U>::value>;"
            _allocator "${_allocator}"
        )
        string(REPLACE
            "template <typename U>\n  FxPartitionAllocAllocator(\n      const FxPartitionAllocAllocator<U, Alloc, Free>& other) noexcept {}"
            "template <typename U, bool OtherPartition>\n  FxPartitionAllocAllocator(\n      const FxPartitionAllocAllocator<U, Alloc, Free, OtherPartition>& other) noexcept {}"
            _allocator "${_allocator}"
        )
        string(REPLACE
            "return static_cast<pointer>(Alloc(n, sizeof(value_type)));"
            "if constexpr (DataPartition) {\n      return static_cast<pointer>(Alloc(n, sizeof(value_type)));\n    } else {\n      return static_cast<pointer>(pdfium::internal::AllocOrDie(n, sizeof(value_type)));\n    }"
            _allocator "${_allocator}"
        )
        string(REPLACE
            "void deallocate(pointer p, size_type n) { Free(p); }"
            "void deallocate(pointer p, size_type n) {\n    if constexpr (DataPartition) {\n      Free(p);\n    } else {\n      pdfium::internal::Dealloc(p);\n    }\n  }"
            _allocator "${_allocator}"
        )
        if(NOT _safe_math MATCHES "defined\\(COMPILER_MSVC\\)" OR
           NOT _allocator MATCHES "bool OtherPartition")
            message(FATAL_ERROR 
                "cppdependencies_pdfium: review the MSVC arithmetic/allocator adaptation for this revision"
            )
        endif()

        # file(CONFIGURE) preserves timestamps when content is unchanged,
        # avoiding a full recompilation on every CMake configure.
        file(CONFIGURE OUTPUT "${_includes}/core/fxcrt/byteorder.h"
            CONTENT "${_byteorder}" @ONLY
        )
        file(CONFIGURE OUTPUT "${_includes}/core/fxcrt/immediate_crash.h"
            CONTENT "${_crash}" @ONLY
        )
        file(CONFIGURE OUTPUT "${_includes}/core/fxcrt/numerics/safe_math_shared_impl.h"
            CONTENT "${_safe_math}" @ONLY
        )
        file(CONFIGURE OUTPUT "${_includes}/core/fxcrt/fx_memory_wrappers.h"
            CONTENT "${_allocator}" @ONLY
        )
    endif()

    # ICU's Unicode tables are checked-in data, not a prebuilt library.
    # Embed them as C++ bytes so the library is relocatable and needs no
    # external .dat file or ICU data-generation tools on the consumer machine.
    set(_icu_data "${pdfium_BINARY_DIR}/icu_data.cpp")
    if(NOT EXISTS "${_icu_data}")
        file(READ "${pdfium_icu_SOURCE_DIR}/common/icudtl.dat" _hex HEX)
        string(REGEX REPLACE "(..)" "0x\\1," _bytes "${_hex}")
        file(WRITE "${_icu_data}"
            "#include <unicode/utypes.h>\nextern \"C\" { alignas(16) extern const unsigned char U_ICUDATA_ENTRY_POINT[] = {${_bytes}}; }\n"
        )
    endif()
    # ICU common is self-contained C++ code. The directory contains no tests
    # or generated-source tools, so it can be compiled directly with CMake.
    file(GLOB _icu_sources CONFIGURE_DEPENDS "${pdfium_icu_SOURCE_DIR}/source/common/*.cpp")

    # Explicit source list for the pinned revision. Upstream has no CMake
    # targets; listing production files avoids accidentally compiling tests,
    # optional engines, or both Windows and POSIX implementations.
    set(_sources
        core/fdrm/fx_crypt.cpp
        core/fdrm/fx_crypt_aes.cpp
        core/fdrm/fx_crypt_sha.cpp
        core/fpdfapi/cmaps/CNS1/B5pc-H_0.cpp
        core/fpdfapi/cmaps/CNS1/B5pc-V_0.cpp
        core/fpdfapi/cmaps/CNS1/CNS-EUC-H_0.cpp
        core/fpdfapi/cmaps/CNS1/CNS-EUC-V_0.cpp
        core/fpdfapi/cmaps/CNS1/ETen-B5-H_0.cpp
        core/fpdfapi/cmaps/CNS1/ETen-B5-V_0.cpp
        core/fpdfapi/cmaps/CNS1/ETenms-B5-H_0.cpp
        core/fpdfapi/cmaps/CNS1/ETenms-B5-V_0.cpp
        core/fpdfapi/cmaps/CNS1/HKscs-B5-H_5.cpp
        core/fpdfapi/cmaps/CNS1/HKscs-B5-V_5.cpp
        core/fpdfapi/cmaps/CNS1/UniCNS-UCS2-H_3.cpp
        core/fpdfapi/cmaps/CNS1/UniCNS-UCS2-V_3.cpp
        core/fpdfapi/cmaps/CNS1/UniCNS-UTF16-H_0.cpp
        core/fpdfapi/cmaps/GB1/GB-EUC-H_0.cpp
        core/fpdfapi/cmaps/GB1/GB-EUC-V_0.cpp
        core/fpdfapi/cmaps/GB1/GBK-EUC-H_2.cpp
        core/fpdfapi/cmaps/GB1/GBK-EUC-V_2.cpp
        core/fpdfapi/cmaps/GB1/GBK2K-H_5.cpp
        core/fpdfapi/cmaps/GB1/GBK2K-V_5.cpp
        core/fpdfapi/cmaps/GB1/GBKp-EUC-H_2.cpp
        core/fpdfapi/cmaps/GB1/GBKp-EUC-V_2.cpp
        core/fpdfapi/cmaps/GB1/GBpc-EUC-H_0.cpp
        core/fpdfapi/cmaps/GB1/GBpc-EUC-V_0.cpp
        core/fpdfapi/cmaps/GB1/UniGB-UCS2-H_4.cpp
        core/fpdfapi/cmaps/GB1/UniGB-UCS2-V_4.cpp
        core/fpdfapi/cmaps/Japan1/83pv-RKSJ-H_1.cpp
        core/fpdfapi/cmaps/Japan1/90ms-RKSJ-H_2.cpp
        core/fpdfapi/cmaps/Japan1/90ms-RKSJ-V_2.cpp
        core/fpdfapi/cmaps/Japan1/90msp-RKSJ-H_2.cpp
        core/fpdfapi/cmaps/Japan1/90msp-RKSJ-V_2.cpp
        core/fpdfapi/cmaps/Japan1/90pv-RKSJ-H_1.cpp
        core/fpdfapi/cmaps/Japan1/Add-RKSJ-H_1.cpp
        core/fpdfapi/cmaps/Japan1/Add-RKSJ-V_1.cpp
        core/fpdfapi/cmaps/Japan1/EUC-H_1.cpp
        core/fpdfapi/cmaps/Japan1/EUC-V_1.cpp
        core/fpdfapi/cmaps/Japan1/Ext-RKSJ-H_2.cpp
        core/fpdfapi/cmaps/Japan1/Ext-RKSJ-V_2.cpp
        core/fpdfapi/cmaps/Japan1/H_1.cpp
        core/fpdfapi/cmaps/Japan1/UniJIS-UCS2-HW-H_4.cpp
        core/fpdfapi/cmaps/Japan1/UniJIS-UCS2-HW-V_4.cpp
        core/fpdfapi/cmaps/Japan1/UniJIS-UCS2-H_4.cpp
        core/fpdfapi/cmaps/Japan1/UniJIS-UCS2-V_4.cpp
        core/fpdfapi/cmaps/Japan1/V_1.cpp
        core/fpdfapi/cmaps/Korea1/KSC-EUC-H_0.cpp
        core/fpdfapi/cmaps/Korea1/KSC-EUC-V_0.cpp
        core/fpdfapi/cmaps/Korea1/KSCms-UHC-HW-H_1.cpp
        core/fpdfapi/cmaps/Korea1/KSCms-UHC-HW-V_1.cpp
        core/fpdfapi/cmaps/Korea1/KSCms-UHC-H_1.cpp
        core/fpdfapi/cmaps/Korea1/KSCms-UHC-V_1.cpp
        core/fpdfapi/cmaps/Korea1/KSCpc-EUC-H_0.cpp
        core/fpdfapi/cmaps/Korea1/UniKS-UCS2-H_1.cpp
        core/fpdfapi/cmaps/Korea1/UniKS-UCS2-V_1.cpp
        core/fpdfapi/cmaps/Korea1/UniKS-UTF16-H_0.cpp
        core/fpdfapi/cmaps/fpdf_cmaps.cpp
        core/fpdfapi/edit/cpdf_creator.cpp
        core/fpdfapi/edit/cpdf_font_util.cpp
        core/fpdfapi/edit/cpdf_fontsubsetter.cpp
        core/fpdfapi/edit/cpdf_npagetooneexporter.cpp
        core/fpdfapi/edit/cpdf_pagecontentgenerator.cpp
        core/fpdfapi/edit/cpdf_pagecontentmanager.cpp
        core/fpdfapi/edit/cpdf_pageexporter.cpp
        core/fpdfapi/edit/cpdf_pageorganizer.cpp
        core/fpdfapi/edit/cpdf_stringarchivestream.cpp
        core/fpdfapi/font/cpdf_cid2unicodemap.cpp
        core/fpdfapi/font/cpdf_cidfont.cpp
        core/fpdfapi/font/cpdf_cmap.cpp
        core/fpdfapi/font/cpdf_cmapparser.cpp
        core/fpdfapi/font/cpdf_facebasedsimplefont.cpp
        core/fpdfapi/font/cpdf_font.cpp
        core/fpdfapi/font/cpdf_fontencoding.cpp
        core/fpdfapi/font/cpdf_fontglobals.cpp
        core/fpdfapi/font/cpdf_simplefont.cpp
        core/fpdfapi/font/cpdf_stockfontarray.cpp
        core/fpdfapi/font/cpdf_tounicodemap.cpp
        core/fpdfapi/font/cpdf_truetypefont.cpp
        core/fpdfapi/font/cpdf_type1font.cpp
        core/fpdfapi/font/cpdf_type3char.cpp
        core/fpdfapi/font/cpdf_type3font.cpp
        core/fpdfapi/page/cpdf_allstates.cpp
        core/fpdfapi/page/cpdf_annotcontext.cpp
        core/fpdfapi/page/cpdf_basedcs.cpp
        core/fpdfapi/page/cpdf_clippath.cpp
        core/fpdfapi/page/cpdf_color.cpp
        core/fpdfapi/page/cpdf_colorspace.cpp
        core/fpdfapi/page/cpdf_colorstate.cpp
        core/fpdfapi/page/cpdf_contentmarkitem.cpp
        core/fpdfapi/page/cpdf_contentmarks.cpp
        core/fpdfapi/page/cpdf_contentparser.cpp
        core/fpdfapi/page/cpdf_devicecs.cpp
        core/fpdfapi/page/cpdf_dib.cpp
        core/fpdfapi/page/cpdf_docpagedata.cpp
        core/fpdfapi/page/cpdf_expintfunc.cpp
        core/fpdfapi/page/cpdf_form.cpp
        core/fpdfapi/page/cpdf_formobject.cpp
        core/fpdfapi/page/cpdf_function.cpp
        core/fpdfapi/page/cpdf_generalstate.cpp
        core/fpdfapi/page/cpdf_graphicstates.cpp
        core/fpdfapi/page/cpdf_iccprofile.cpp
        core/fpdfapi/page/cpdf_image.cpp
        core/fpdfapi/page/cpdf_imageloader.cpp
        core/fpdfapi/page/cpdf_imageobject.cpp
        core/fpdfapi/page/cpdf_indexedcs.cpp
        core/fpdfapi/page/cpdf_meshstream.cpp
        core/fpdfapi/page/cpdf_occontext.cpp
        core/fpdfapi/page/cpdf_page.cpp
        core/fpdfapi/page/cpdf_pageimagecache.cpp
        core/fpdfapi/page/cpdf_pagemodule.cpp
        core/fpdfapi/page/cpdf_pageobject.cpp
        core/fpdfapi/page/cpdf_pageobjectholder.cpp
        core/fpdfapi/page/cpdf_path.cpp
        core/fpdfapi/page/cpdf_pathobject.cpp
        core/fpdfapi/page/cpdf_pattern.cpp
        core/fpdfapi/page/cpdf_patterncs.cpp
        core/fpdfapi/page/cpdf_psengine.cpp
        core/fpdfapi/page/cpdf_psfunc.cpp
        core/fpdfapi/page/cpdf_sampledfunc.cpp
        core/fpdfapi/page/cpdf_shadingobject.cpp
        core/fpdfapi/page/cpdf_shadingpattern.cpp
        core/fpdfapi/page/cpdf_stitchfunc.cpp
        core/fpdfapi/page/cpdf_streamcontentparser.cpp
        core/fpdfapi/page/cpdf_streamparser.cpp
        core/fpdfapi/page/cpdf_textobject.cpp
        core/fpdfapi/page/cpdf_textstate.cpp
        core/fpdfapi/page/cpdf_tilingpattern.cpp
        core/fpdfapi/page/cpdf_transferfunc.cpp
        core/fpdfapi/page/cpdf_transferfuncdib.cpp
        core/fpdfapi/page/cpdf_transparency.cpp
        core/fpdfapi/page/jpx_decode_conversion.cpp
        core/fpdfapi/parser/cfdf_document.cpp
        core/fpdfapi/parser/cpdf_array.cpp
        core/fpdfapi/parser/cpdf_boolean.cpp
        core/fpdfapi/parser/cpdf_cross_ref_avail.cpp
        core/fpdfapi/parser/cpdf_cross_ref_table.cpp
        core/fpdfapi/parser/cpdf_crypto_handler.cpp
        core/fpdfapi/parser/cpdf_data_avail.cpp
        core/fpdfapi/parser/cpdf_dictionary.cpp
        core/fpdfapi/parser/cpdf_document.cpp
        core/fpdfapi/parser/cpdf_encryptor.cpp
        core/fpdfapi/parser/cpdf_flateencoder.cpp
        core/fpdfapi/parser/cpdf_hint_tables.cpp
        core/fpdfapi/parser/cpdf_indirect_object_holder.cpp
        core/fpdfapi/parser/cpdf_linearized_header.cpp
        core/fpdfapi/parser/cpdf_name.cpp
        core/fpdfapi/parser/cpdf_null.cpp
        core/fpdfapi/parser/cpdf_number.cpp
        core/fpdfapi/parser/cpdf_object.cpp
        core/fpdfapi/parser/cpdf_object_avail.cpp
        core/fpdfapi/parser/cpdf_object_stream.cpp
        core/fpdfapi/parser/cpdf_object_walker.cpp
        core/fpdfapi/parser/cpdf_page_object_avail.cpp
        core/fpdfapi/parser/cpdf_parser.cpp
        core/fpdfapi/parser/cpdf_read_validator.cpp
        core/fpdfapi/parser/cpdf_reference.cpp
        core/fpdfapi/parser/cpdf_security_handler.cpp
        core/fpdfapi/parser/cpdf_simple_parser.cpp
        core/fpdfapi/parser/cpdf_stream.cpp
        core/fpdfapi/parser/cpdf_stream_acc.cpp
        core/fpdfapi/parser/cpdf_string.cpp
        core/fpdfapi/parser/cpdf_syntax_parser.cpp
        core/fpdfapi/parser/fpdf_parser_decode.cpp
        core/fpdfapi/parser/fpdf_parser_utility.cpp
        core/fpdfapi/parser/object_tree_traversal_util.cpp
        core/fpdfapi/render/cpdf_devicebuffer.cpp
        core/fpdfapi/render/cpdf_docrenderdata.cpp
        core/fpdfapi/render/cpdf_imagerenderer.cpp
        core/fpdfapi/render/cpdf_pagerendercontext.cpp
        core/fpdfapi/render/cpdf_progressiverenderer.cpp
        core/fpdfapi/render/cpdf_rendercontext.cpp
        core/fpdfapi/render/cpdf_renderoptions.cpp
        core/fpdfapi/render/cpdf_rendershading.cpp
        core/fpdfapi/render/cpdf_renderstatus.cpp
        core/fpdfapi/render/cpdf_rendertiling.cpp
        core/fpdfapi/render/cpdf_textrenderer.cpp
        core/fpdfapi/render/cpdf_type3cache.cpp
        core/fpdfapi/render/cpdf_type3glyphmap.cpp
        core/fpdfdoc/cpdf_aaction.cpp
        core/fpdfdoc/cpdf_action.cpp
        core/fpdfdoc/cpdf_annot.cpp
        core/fpdfdoc/cpdf_annotlist.cpp
        core/fpdfdoc/cpdf_apsettings.cpp
        core/fpdfdoc/cpdf_bafontmap.cpp
        core/fpdfdoc/cpdf_bookmark.cpp
        core/fpdfdoc/cpdf_bookmarktree.cpp
        core/fpdfdoc/cpdf_color_utils.cpp
        core/fpdfdoc/cpdf_defaultappearance.cpp
        core/fpdfdoc/cpdf_dest.cpp
        core/fpdfdoc/cpdf_filespec.cpp
        core/fpdfdoc/cpdf_formcontrol.cpp
        core/fpdfdoc/cpdf_formfield.cpp
        core/fpdfdoc/cpdf_generateap.cpp
        core/fpdfdoc/cpdf_icon.cpp
        core/fpdfdoc/cpdf_iconfit.cpp
        core/fpdfdoc/cpdf_interactiveform.cpp
        core/fpdfdoc/cpdf_link.cpp
        core/fpdfdoc/cpdf_linklist.cpp
        core/fpdfdoc/cpdf_metadata.cpp
        core/fpdfdoc/cpdf_nametree.cpp
        core/fpdfdoc/cpdf_numbertree.cpp
        core/fpdfdoc/cpdf_pagelabel.cpp
        core/fpdfdoc/cpdf_structelement.cpp
        core/fpdfdoc/cpdf_structtree.cpp
        core/fpdfdoc/cpdf_viewerpreferences.cpp
        core/fpdfdoc/cpvt_fontmap.cpp
        core/fpdfdoc/cpvt_section.cpp
        core/fpdfdoc/cpvt_variabletext.cpp
        core/fpdfdoc/cpvt_word.cpp
        core/fpdfdoc/cpvt_wordinfo.cpp
        core/fpdftext/cpdf_linkextract.cpp
        core/fpdftext/cpdf_textpage.cpp
        core/fpdftext/cpdf_textpagefind.cpp
        core/fpdftext/unicodenormalizationdata.cpp
        core/fxcodec/basic/basicmodule.cpp
        core/fxcodec/data_and_bytes_consumed.cpp
        core/fxcodec/fax/faxmodule.cpp
        core/fxcodec/flate/flatemodule.cpp
        core/fxcodec/fx_codec.cpp
        core/fxcodec/icc/icc_transform.cpp
        core/fxcodec/image_predictors.cpp
        core/fxcodec/jbig2/jbig2_arith_decoder.cpp
        core/fxcodec/jbig2/jbig2_arith_int_decoder.cpp
        core/fxcodec/jbig2/jbig2_bit_stream.cpp
        core/fxcodec/jbig2/jbig2_context.cpp
        core/fxcodec/jbig2/jbig2_decoder.cpp
        core/fxcodec/jbig2/jbig2_document_context.cpp
        core/fxcodec/jbig2/jbig2_grd_proc.cpp
        core/fxcodec/jbig2/jbig2_grrd_proc.cpp
        core/fxcodec/jbig2/jbig2_htrd_proc.cpp
        core/fxcodec/jbig2/jbig2_huffman_decoder.cpp
        core/fxcodec/jbig2/jbig2_huffman_table.cpp
        core/fxcodec/jbig2/jbig2_image.cpp
        core/fxcodec/jbig2/jbig2_pattern_dict.cpp
        core/fxcodec/jbig2/jbig2_pdd_proc.cpp
        core/fxcodec/jbig2/jbig2_sdd_proc.cpp
        core/fxcodec/jbig2/jbig2_segment.cpp
        core/fxcodec/jbig2/jbig2_symbol_dict.cpp
        core/fxcodec/jbig2/jbig2_trd_proc.cpp
        core/fxcodec/jpeg/jpeg_common.c
        core/fxcodec/jpeg/jpegmodule.cpp
        core/fxcodec/jpeg/libjpeg_scanline_decoder.cpp
        core/fxcodec/jpx/cjpx_decoder.cpp
        core/fxcodec/jpx/jpx_decode_utils.cpp
        core/fxcodec/scanlinedecoder.cpp
        core/fxcrt/binary_buffer.cpp
        core/fxcrt/bytestring.cpp
        core/fxcrt/bytestring_pool.cpp
        core/fxcrt/cfx_bidi_resolver.cpp
        core/fxcrt/cfx_bitstream.cpp
        core/fxcrt/cfx_datetime.cpp
        core/fxcrt/cfx_fileaccess_stream.cpp
        core/fxcrt/cfx_read_only_container_stream.cpp
        core/fxcrt/cfx_read_only_span_stream.cpp
        core/fxcrt/cfx_seekablestreamproxy.cpp
        core/fxcrt/cfx_timer.cpp
        core/fxcrt/debug/alias.cc
        core/fxcrt/fx_bidi.cpp
        core/fxcrt/fx_codepage.cpp
        core/fxcrt/fx_coordinates.cpp
        core/fxcrt/fx_extension.cpp
        core/fxcrt/fx_memory.cpp
        core/fxcrt/fx_memory_malloc.cpp
        core/fxcrt/fx_number.cpp
        core/fxcrt/fx_random.cpp
        core/fxcrt/fx_stream.cpp
        core/fxcrt/fx_string.cpp
        core/fxcrt/fx_system.cpp
        core/fxcrt/fx_unicode.cpp
        core/fxcrt/observed_ptr.cpp
        core/fxcrt/stream_write_utils.cpp
        core/fxcrt/string_data_template.cpp
        core/fxcrt/string_template.cpp
        core/fxcrt/widestring.cpp
        core/fxcrt/widetext_buffer.cpp
        core/fxcrt/xml/cfx_xmlchardata.cpp
        core/fxcrt/xml/cfx_xmldocument.cpp
        core/fxcrt/xml/cfx_xmlelement.cpp
        core/fxcrt/xml/cfx_xmlinstruction.cpp
        core/fxcrt/xml/cfx_xmlnode.cpp
        core/fxcrt/xml/cfx_xmlparser.cpp
        core/fxcrt/xml/cfx_xmltext.cpp
        core/fxge/agg/cfx_agg_bitmapcomposer.cpp
        core/fxge/agg/cfx_agg_cliprgn.cpp
        core/fxge/agg/cfx_agg_devicedriver.cpp
        core/fxge/agg/cfx_agg_imagerenderer.cpp
        core/fxge/calculate_pitch.cpp
        core/fxge/cfx_charmap_resolver.cpp
        core/fxge/cfx_color.cpp
        core/fxge/cfx_cttgsubtable.cpp
        core/fxge/cfx_drawutils.cpp
        core/fxge/cfx_face.cpp
        core/fxge/cfx_folderfontinfo.cpp
        core/fxge/cfx_font.cpp
        core/fxge/cfx_fontmapper.cpp
        core/fxge/cfx_fontmgr.cpp
        core/fxge/cfx_gemodule.cpp
        core/fxge/cfx_glyphbitmap.cpp
        core/fxge/cfx_glyphcache.cpp
        core/fxge/cfx_graphstate.cpp
        core/fxge/cfx_graphstatedata.cpp
        core/fxge/cfx_path.cpp
        core/fxge/cfx_renderdevice.cpp
        core/fxge/cfx_standardfont.cpp
        core/fxge/cfx_substfont.cpp
        core/fxge/dib/blend.cpp
        core/fxge/dib/cfx_bitmapstorer.cpp
        core/fxge/dib/cfx_cmyk_to_srgb.cpp
        core/fxge/dib/cfx_dibbase.cpp
        core/fxge/dib/cfx_dibitmap.cpp
        core/fxge/dib/cfx_imagestretcher.cpp
        core/fxge/dib/cfx_imagetransformer.cpp
        core/fxge/dib/cfx_scanlinecompositor.cpp
        core/fxge/dib/cstretchengine.cpp
        core/fxge/dib/fx_dib.cpp
        core/fxge/fontdata/chromefontdata/FoxitDingbats.cpp
        core/fxge/fontdata/chromefontdata/FoxitFixed.cpp
        core/fxge/fontdata/chromefontdata/FoxitFixedBold.cpp
        core/fxge/fontdata/chromefontdata/FoxitFixedBoldItalic.cpp
        core/fxge/fontdata/chromefontdata/FoxitFixedItalic.cpp
        core/fxge/fontdata/chromefontdata/FoxitSans.cpp
        core/fxge/fontdata/chromefontdata/FoxitSansBold.cpp
        core/fxge/fontdata/chromefontdata/FoxitSansBoldItalic.cpp
        core/fxge/fontdata/chromefontdata/FoxitSansItalic.cpp
        core/fxge/fontdata/chromefontdata/FoxitSansMM.cpp
        core/fxge/fontdata/chromefontdata/FoxitSerif.cpp
        core/fxge/fontdata/chromefontdata/FoxitSerifBold.cpp
        core/fxge/fontdata/chromefontdata/FoxitSerifBoldItalic.cpp
        core/fxge/fontdata/chromefontdata/FoxitSerifItalic.cpp
        core/fxge/fontdata/chromefontdata/FoxitSerifMM.cpp
        core/fxge/fontdata/chromefontdata/FoxitSymbol.cpp
        core/fxge/freetype/fx_freetype.cpp
        core/fxge/fx_font.cpp
        core/fxge/renderdevicedriver_iface.cpp
        core/fxge/text_char_pos.cpp
        core/fxge/text_glyph_pos.cpp
        fpdfsdk/cpdfsdk_annot.cpp
        fpdfsdk/cpdfsdk_annotiteration.cpp
        fpdfsdk/cpdfsdk_annotiterator.cpp
        fpdfsdk/cpdfsdk_appstream.cpp
        fpdfsdk/cpdfsdk_baannot.cpp
        fpdfsdk/cpdfsdk_customaccess.cpp
        fpdfsdk/cpdfsdk_filewriteadapter.cpp
        fpdfsdk/cpdfsdk_formfillenvironment.cpp
        fpdfsdk/cpdfsdk_helpers.cpp
        fpdfsdk/cpdfsdk_interactiveform.cpp
        fpdfsdk/cpdfsdk_pageview.cpp
        fpdfsdk/cpdfsdk_pauseadapter.cpp
        fpdfsdk/cpdfsdk_renderpage.cpp
        fpdfsdk/cpdfsdk_widget.cpp
        fpdfsdk/formfiller/cffl_button.cpp
        fpdfsdk/formfiller/cffl_checkbox.cpp
        fpdfsdk/formfiller/cffl_combobox.cpp
        fpdfsdk/formfiller/cffl_fieldaction.cpp
        fpdfsdk/formfiller/cffl_formfield.cpp
        fpdfsdk/formfiller/cffl_interactiveformfiller.cpp
        fpdfsdk/formfiller/cffl_listbox.cpp
        fpdfsdk/formfiller/cffl_perwindowdata.cpp
        fpdfsdk/formfiller/cffl_pushbutton.cpp
        fpdfsdk/formfiller/cffl_radiobutton.cpp
        fpdfsdk/formfiller/cffl_textfield.cpp
        fpdfsdk/formfiller/cffl_textobject.cpp
        fpdfsdk/fpdf_annot.cpp
        fpdfsdk/fpdf_attachment.cpp
        fpdfsdk/fpdf_catalog.cpp
        fpdfsdk/fpdf_dataavail.cpp
        fpdfsdk/fpdf_doc.cpp
        fpdfsdk/fpdf_editimg.cpp
        fpdfsdk/fpdf_editpage.cpp
        fpdfsdk/fpdf_editpath.cpp
        fpdfsdk/fpdf_edittext.cpp
        fpdfsdk/fpdf_ext.cpp
        fpdfsdk/fpdf_flatten.cpp
        fpdfsdk/fpdf_formfill.cpp
        fpdfsdk/fpdf_javascript.cpp
        fpdfsdk/fpdf_ppo.cpp
        fpdfsdk/fpdf_progressive.cpp
        fpdfsdk/fpdf_save.cpp
        fpdfsdk/fpdf_searchex.cpp
        fpdfsdk/fpdf_signature.cpp
        fpdfsdk/fpdf_structtree.cpp
        fpdfsdk/fpdf_sysfontinfo.cpp
        fpdfsdk/fpdf_text.cpp
        fpdfsdk/fpdf_thumbnail.cpp
        fpdfsdk/fpdf_transformpage.cpp
        fpdfsdk/fpdf_view.cpp
        fpdfsdk/pwl/cpwl_button.cpp
        fpdfsdk/pwl/cpwl_caret.cpp
        fpdfsdk/pwl/cpwl_cbbutton.cpp
        fpdfsdk/pwl/cpwl_cblistbox.cpp
        fpdfsdk/pwl/cpwl_combo_box.cpp
        fpdfsdk/pwl/cpwl_edit.cpp
        fpdfsdk/pwl/cpwl_edit_impl.cpp
        fpdfsdk/pwl/cpwl_list_box.cpp
        fpdfsdk/pwl/cpwl_list_ctrl.cpp
        fpdfsdk/pwl/cpwl_sbbutton.cpp
        fpdfsdk/pwl/cpwl_scroll_bar.cpp
        fpdfsdk/pwl/cpwl_special_button.cpp
        fpdfsdk/pwl/cpwl_wnd.cpp
        fxjs/cjs_event_context_stub.cpp
        fxjs/cjs_runtimestub.cpp
        fxjs/ijs_runtime.cpp
        third_party/agg23/agg_curves.cpp
        third_party/agg23/agg_path_storage.cpp
        third_party/agg23/agg_rasterizer_scanline_aa.cpp
        third_party/agg23/agg_vcgen_dash.cpp
        third_party/agg23/agg_vcgen_stroke.cpp
        third_party/lcms/src/cmsalpha.c
        third_party/lcms/src/cmscam02.c
        third_party/lcms/src/cmscgats.c
        third_party/lcms/src/cmscnvrt.c
        third_party/lcms/src/cmserr.c
        third_party/lcms/src/cmsgamma.c
        third_party/lcms/src/cmsgmt.c
        third_party/lcms/src/cmshalf.c
        third_party/lcms/src/cmsintrp.c
        third_party/lcms/src/cmsio0.c
        third_party/lcms/src/cmsio1.c
        third_party/lcms/src/cmslut.c
        third_party/lcms/src/cmsmd5.c
        third_party/lcms/src/cmsmtrx.c
        third_party/lcms/src/cmsnamed.c
        third_party/lcms/src/cmsopt.c
        third_party/lcms/src/cmspack.c
        third_party/lcms/src/cmspcs.c
        third_party/lcms/src/cmsplugin.c
        third_party/lcms/src/cmsps2.c
        third_party/lcms/src/cmssamp.c
        third_party/lcms/src/cmssm.c
        third_party/lcms/src/cmstypes.c
        third_party/lcms/src/cmsvirt.c
        third_party/lcms/src/cmswtpnt.c
        third_party/lcms/src/cmsxform.c
        third_party/libopenjpeg/bio.c
        third_party/libopenjpeg/cio.c
        third_party/libopenjpeg/dwt.c
        third_party/libopenjpeg/event.c
        third_party/libopenjpeg/function_list.c
        third_party/libopenjpeg/ht_dec.c
        third_party/libopenjpeg/image.c
        third_party/libopenjpeg/invert.c
        third_party/libopenjpeg/j2k.c
        third_party/libopenjpeg/jp2.c
        third_party/libopenjpeg/mct.c
        third_party/libopenjpeg/mqc.c
        third_party/libopenjpeg/openjpeg.c
        third_party/libopenjpeg/opj_malloc.cc
        third_party/libopenjpeg/pi.c
        third_party/libopenjpeg/sparse_array.c
        third_party/libopenjpeg/t1.c
        third_party/libopenjpeg/t2.c
        third_party/libopenjpeg/tcd.c
        third_party/libopenjpeg/tgt.c
        third_party/libopenjpeg/thread.c
    )
    if(WIN32)
        list(APPEND _sources
            core/fpdfapi/render/cpdf_scaledrenderbuffer.cpp
            core/fxcrt/cfx_fileaccess_windows.cpp
            core/fxcrt/code_point_view.cpp
            core/fxcrt/fx_folder_windows.cpp
            core/fxcrt/win/win_util.cc
            core/fxge/win32/cfx_psfonttracker.cpp
            core/fxge/win32/cfx_psrenderer.cpp
            core/fxge/win32/cgdi_device_driver.cpp
            core/fxge/win32/cgdi_display_driver.cpp
            core/fxge/win32/cgdi_plus_ext.cpp
            core/fxge/win32/cgdi_printer_driver.cpp
            core/fxge/win32/cps_printer_driver.cpp
            core/fxge/win32/cpsoutput.cpp
            core/fxge/win32/ctext_only_printer_driver.cpp
            core/fxge/win32/cwin32_platform.cpp
        )
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        list(APPEND _sources
            core/fxcrt/cfx_fileaccess_posix.cpp
            core/fxcrt/fx_folder_posix.cpp
            core/fxcrt/mapped_data_bytes.cpp
            core/fxge/linux/fx_linux_impl.cpp
        )
    else()
        message(FATAL_ERROR 
            "cppdependencies_pdfium: this CMake source profile supports Windows and Linux"
        )
    endif()

    list(TRANSFORM _sources PREPEND "${pdfium_SOURCE_DIR}/")
    file(GLOB _public_headers CONFIGURE_DEPENDS "${pdfium_SOURCE_DIR}/public/*.h")

    add_library(pdfium 
        ${_linkage} 
        ${_sources} 
        ${_icu_sources} 
        "${_icu_data}" 
        ${_public_headers}
    )
    add_library(${_package_target} ALIAS pdfium)
    target_compile_features(pdfium PRIVATE
        cxx_std_20
    )
    target_compile_definitions(pdfium PRIVATE
        FPDF_IMPLEMENTATION 
        PDF_USE_AGG 
        PDF_ENABLE_FREETYPE 
        DEFINE_PS_TABLES_DATA
        USE_SYSTEM_ZLIB 
        OPJ_STATIC 
        U_STATIC_IMPLEMENTATION 
        U_COMMON_IMPLEMENTATION
    )
    target_include_directories(pdfium
        PUBLIC 
            "$<BUILD_INTERFACE:${pdfium_SOURCE_DIR}/public>"
        PRIVATE 
            "${pdfium_SOURCE_DIR}" 
            "${_includes}"
            "${pdfium_icu_SOURCE_DIR}/source/common"
            "${pdfium_SOURCE_DIR}/third_party/lcms/include"
            "${pdfium_SOURCE_DIR}/third_party/libopenjpeg"
    )
    target_link_libraries(pdfium PRIVATE
        ${_jpeg}
        ${_zlib} 
        ${_freetype}
        absl::flat_hash_set 
        absl::inlined_vector 
        absl::cleanup 
        harfbuzz-subset
    )
    set_target_properties(pdfium PROPERTIES
        POSITION_INDEPENDENT_CODE ON
        DEBUG_POSTFIX d
        DEFINE_SYMBOL ""
        # PDFium uses ordinary C++ translation units, not C++20 modules.
        CXX_SCAN_FOR_MODULES OFF
        MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL"
    )
    if(MSVC)
        # Prefer the native-MSVC header copies over the original private ones.
        target_include_directories(pdfium BEFORE PRIVATE "${_includes}")
        target_compile_options(pdfium PRIVATE 
            /utf-8 
            /bigobj
        )
        # PDFium passes wide strings to Windows APIs such as GetModuleHandle.
        target_compile_definitions(pdfium PRIVATE
            UNICODE 
            _UNICODE 
            NOMINMAX 
            WIN32_LEAN_AND_MEAN
        )
        target_link_libraries(pdfium PRIVATE
            advapi32
            gdi32
            user32
        )
        if(ARG_SHARED OR NOT ARG_STATIC)
            # Compile the same core without component DLL annotations. CMake
            # exports the actual symbols; clients use the public import API.
            set_property(TARGET pdfium PROPERTY WINDOWS_EXPORT_ALL_SYMBOLS ON)
            target_compile_definitions(pdfium INTERFACE COMPONENT_BUILD)
        endif()
    else()
        target_link_libraries(pdfium 
            PRIVATE 
                ${CMAKE_DL_LIBS} 
                pthread 
                m
        )
        target_compile_options(pdfium
            PRIVATE
                $<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions>
                $<$<COMPILE_LANGUAGE:CXX>:-Wno-return-type>
        )
    endif()

    cppcmake_dependency_set_folder(pdfium "pdfium")
    source_group(TREE "${pdfium_SOURCE_DIR}" PREFIX "Source" FILES 
        ${_sources}
        ${_public_headers})
    
    message(STATUS 
        "CppDependencies PDFium: source ${_linkage} (${CPPDEPENDENCIES_PDFIUM_VERSION})"
    )
    set(${OUT_TARGET} ${_package_target} PARENT_SCOPE)
endfunction()
