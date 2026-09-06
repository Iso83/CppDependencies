include_guard(GLOBAL)

include(FetchContent)
include("${CMAKE_CURRENT_LIST_DIR}/../glfw/glfw.cmake")

set(CPPDEPENDENCIES_IMGUI_DOCKING_VERSION "1.92.9b")

function(_cppdependencies_imgui_docking_create)
    add_library(imgui_docking STATIC
        "${imgui_docking_SOURCE_DIR}/imgui.cpp"
        "${imgui_docking_SOURCE_DIR}/imgui_draw.cpp"
        "${imgui_docking_SOURCE_DIR}/imgui_tables.cpp"
        "${imgui_docking_SOURCE_DIR}/imgui_widgets.cpp"
        "${imgui_docking_SOURCE_DIR}/backends/imgui_impl_glfw.cpp"
        "${imgui_docking_SOURCE_DIR}/backends/imgui_impl_opengl3.cpp"
    )

    add_library(imgui_docking::imgui_docking ALIAS imgui_docking)

    target_include_directories(imgui_docking
        PUBLIC
            "${imgui_docking_SOURCE_DIR}"
            "${imgui_docking_SOURCE_DIR}/backends"
    )

    cppdependencies_glfw(GLFW)

    target_link_libraries(imgui_docking
        PUBLIC
            ${GLFW}
    )

    cppcmake_dependency_set_folder(
        imgui_docking
        ""
    )
endfunction()

function(cppdependencies_imgui_docking OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides the imgui_docking dependency target.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the imgui_docking target name.
    # =========================================================

    if(TARGET imgui_docking::imgui_docking)
        set(${OUT_TARGET} imgui_docking::imgui_docking PARENT_SCOPE)
        return()
    endif()

    find_package(imgui_docking CONFIG QUIET)

    if(NOT TARGET imgui_docking::imgui_docking)
        FetchContent_Declare(
            imgui_docking
            URL https://github.com/ocornut/imgui/archive/refs/tags/v${CPPDEPENDENCIES_IMGUI_DOCKING_VERSION}-docking.tar.gz
            URL_HASH SHA256=90ded916bd57db2e0e171b6b098940a47c6f5042725dcdc67fb19940ca8bfdcc
        )
        
        cppcmake_dependency_make_available(imgui_docking)

        _cppdependencies_imgui_docking_create()
    endif()

    set(${OUT_TARGET} imgui_docking::imgui_docking PARENT_SCOPE)
endfunction()