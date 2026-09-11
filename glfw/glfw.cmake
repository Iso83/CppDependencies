include_guard(GLOBAL)

include(FetchContent)

set(CPPDEPENDENCIES_GLFW_VERSION "3.3.9")

function(cppdependencies_glfw OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides the GLFW dependency target.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the GLFW target name.
    #                      Empty when building with Emscripten.
    # =========================================================

    if(EMSCRIPTEN)
        set(${OUT_TARGET} "" PARENT_SCOPE)
        return()
    endif()

    if(TARGET glfw)
        set(${OUT_TARGET} glfw PARENT_SCOPE)
        return()
    endif()

    find_package(
        glfw3 ${CPPDEPENDENCIES_GLFW_VERSION}
        CONFIG
        QUIET
    )

    if(TARGET glfw)
        set(${OUT_TARGET} glfw PARENT_SCOPE)
        return()
    endif()

    FetchContent_Declare(
        glfw
        GIT_REPOSITORY https://github.com/glfw/glfw.git
        GIT_TAG ${CPPDEPENDENCIES_GLFW_VERSION}
    )

    set(GLFW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(GLFW_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(GLFW_BUILD_DOCS OFF CACHE BOOL "" FORCE)
    set(GLFW_INSTALL OFF CACHE BOOL "" FORCE)

    cppcmake_dependency_make_available(glfw)

    cppcmake_dependency_set_folder(glfw glfw)
    cppcmake_dependency_set_folder(update_mappings glfw)

    set(${OUT_TARGET} glfw PARENT_SCOPE)
endfunction()
