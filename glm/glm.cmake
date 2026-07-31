include_guard(GLOBAL)

include(FetchContent)

function(cppdependencies_glm OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides the GLM dependency target.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the GLM target name.
    # =========================================================

    if(TARGET glm::glm)
        set(${OUT_TARGET} glm::glm PARENT_SCOPE)
        return()
    endif()

    FetchContent_Declare(
        glm
        GIT_REPOSITORY https://github.com/g-truc/glm.git
        GIT_TAG 1.0.1
    )

    cppcmake_dependency_make_available(glm)
    
    cppcmake_dependency_set_folder(glm "")

    set(${OUT_TARGET} glm::glm PARENT_SCOPE)
endfunction()