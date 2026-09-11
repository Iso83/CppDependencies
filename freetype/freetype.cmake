include_guard(GLOBAL)

include(FetchContent)

function(cppdependencies_freetype OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides the FreeType dependency target.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the FreeType target name.
    #                      Empty when building with Emscripten.
    # =========================================================

    if(EMSCRIPTEN)
        # Emscripten's FreeType port is selected on the consuming render target.
        set(${OUT_TARGET} "" PARENT_SCOPE)
        return()
    endif()

    if(TARGET Freetype::Freetype)
        set(${OUT_TARGET} Freetype::Freetype PARENT_SCOPE)
        return()
    endif()

    find_package(Freetype QUIET)

    if(TARGET Freetype::Freetype)
        set(${OUT_TARGET} Freetype::Freetype PARENT_SCOPE)
        return()
    endif()

    if(TARGET freetype)
        set(${OUT_TARGET} freetype PARENT_SCOPE)
        return()
    endif()

    FetchContent_Declare(
        freetype
        GIT_REPOSITORY https://gitlab.freedesktop.org/freetype/freetype.git
        GIT_TAG VER-2-13-3
    )

    set(FT_DISABLE_ZLIB ON CACHE BOOL "" FORCE)
    set(FT_DISABLE_BZIP2 ON CACHE BOOL "" FORCE)
    set(FT_DISABLE_PNG ON CACHE BOOL "" FORCE)
    set(FT_DISABLE_HARFBUZZ ON CACHE BOOL "" FORCE)
    set(FT_DISABLE_BROTLI ON CACHE BOOL "" FORCE)

    cppcmake_dependency_make_available(freetype)

    set_target_properties(
        freetype
        PROPERTIES
            DEBUG_POSTFIX ""
            RELWITHDEBINFO_POSTFIX ""
            MINSIZEREL_POSTFIX ""
    )

    cppcmake_dependency_set_folder(
        freetype
        ""
    )

    set(${OUT_TARGET} freetype PARENT_SCOPE)
endfunction()
