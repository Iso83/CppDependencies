include_guard(GLOBAL)

include(FetchContent)

function(cppdependencies_cli11 OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides the CLI11 dependency target.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the CLI11 target name.
    # =========================================================

    if(TARGET CLI11::CLI11)
        set(${OUT_TARGET} CLI11::CLI11 PARENT_SCOPE)
        return()
    endif()

    find_package(CLI11 CONFIG QUIET)

    if(NOT TARGET CLI11::CLI11)
        FetchContent_Declare(
            CLI11
            GIT_REPOSITORY https://github.com/CLIUtils/CLI11.git
            GIT_TAG v2.6.2
        )
        
        cppcmake_dependency_make_available(CLI11)
        cppcmake_dependency_set_folder(CLI11 "")
    endif()

    set(${OUT_TARGET} CLI11::CLI11 PARENT_SCOPE)
endfunction()