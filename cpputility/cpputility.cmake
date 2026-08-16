include_guard(GLOBAL)

include(FetchContent)

function(cppdependencies_cpputility OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides the CppUtility dependency target.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the CppUtility target name.
    # =========================================================

    if(TARGET CppUtility)
        set(${OUT_TARGET} CppUtility PARENT_SCOPE)
        return()
    endif()
   

    FetchContent_Declare(
        CppUtility
        GIT_REPOSITORY https://github.com/Iso83/CppUtility.git
        GIT_TAG main
    )

    cppcmake_dependency_make_available(CppUtility)

    set(${OUT_TARGET} CppUtility PARENT_SCOPE)
endfunction()