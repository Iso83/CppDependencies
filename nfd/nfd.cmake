include_guard(GLOBAL)

include(FetchContent)

function(cppdependencies_nfd OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides the NFD dependency target.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the NFD target name.
    # =========================================================

    if(TARGET nfd::nfd)
        set(${OUT_TARGET} glm::glm PARENT_SCOPE)
        return()
    endif()

    FetchContent_Declare(
        nfd
        GIT_REPOSITORY https://github.com/btzy/nativefiledialog-extended.git
        GIT_TAG v1.2.1
    )

    cppcmake_dependency_make_available(nfd)
    
    cppcmake_dependency_set_folder(nfd "")

    set(${OUT_TARGET} nfd::nfd PARENT_SCOPE)
endfunction()