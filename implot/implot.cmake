include_guard(GLOBAL)

include(FetchContent)

function(_cppdependencies_implot_create IMGUI_TARGET)
    add_library(implot STATIC
        "${implot_SOURCE_DIR}/implot_internal.h"
        
        "${implot_SOURCE_DIR}/implot.h"
        "${implot_SOURCE_DIR}/implot.cpp"

        "${implot_SOURCE_DIR}/implot_items.cpp"
    )

    add_library(implot::implot ALIAS implot)

    target_include_directories(imgui_docking
        PUBLIC
            "${implot_SOURCE_DIR}"
    )

    target_link_libraries(implot
        PUBLIC
            ${IMGUI_TARGET}
    )

    cppcmake_dependency_set_folder(
        implot
        ""
    )
endfunction()

function(cppdependencies_implot OUT_TARGET IMGUI_TARGET)
    # =========================================================
    # Summary
    #
    # Provides the ImPlot dependency target.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the ImPlot target name.
    #   [in]  IMGUI_TARGET - Existing ImGui target to link ImPlot against.
    # =========================================================

    if(NOT TARGET ${IMGUI_TARGET})
        message(FATAL_ERROR
            "cppdependencies_implot: '${IMGUI_TARGET}' is not a valid ImGui target"
        )
    endif()

    if(TARGET implot::implot)
        set(${OUT_TARGET} implot::implot PARENT_SCOPE)
        return()
    endif()

    FetchContent_Declare(
        implot
        GIT_REPOSITORY https://github.com/epezent/implot.git
        GIT_TAG 7eeb9168d2e5e6b14e266d8782ecf7e649dfc3a4 # 2026-08
    )

    cppcmake_dependency_make_available(implot)

    _cppdependencies_implot_create(${IMGUI_TARGET})

    set(${OUT_TARGET} implot::implot PARENT_SCOPE)
endfunction()