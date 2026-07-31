include_guard(GLOBAL)

set(_CPPDEPENDENCIES_GLAD_DIR "${CMAKE_CURRENT_LIST_DIR}")

function(_cppdependencies_glad_create)
    add_library(glad STATIC
        "${_CPPDEPENDENCIES_GLAD_DIR}/src/glad.c"
    )

    add_library(glad::glad ALIAS glad)

    target_include_directories(glad 
        PUBLIC
            "${_CPPDEPENDENCIES_GLAD_DIR}/include"
    )

    target_compile_features(glad
        PUBLIC
            c_std_99
    )

    cppcmake_dependency_set_folder(
        glad
        ""
    )
endfunction()

function(cppdependencies_glad OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides the glad dependency target.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the glad target name.
    #                      Empty when building with Emscripten.
    # =========================================================

    if(EMSCRIPTEN)
        set(${OUT_TARGET} "" PARENT_SCOPE)
        return()
    endif()

    if(TARGET glad::glad)
        set(${OUT_TARGET} glad::glad PARENT_SCOPE)
        return()
    endif()

    _cppdependencies_glad_create()

    set(${OUT_TARGET} glad::glad PARENT_SCOPE)
endfunction()