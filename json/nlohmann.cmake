include_guard(GLOBAL)

include(FetchContent)

function(cppdependencies_json_nlohmann OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides the nlohmann_json dependency target.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the nlohmann_json target name.
    # =========================================================

    if(TARGET nlohmann_json::nlohmann_json)
        set(${OUT_TARGET} nlohmann_json::nlohmann_json PARENT_SCOPE)
        return()
    endif()
   

    FetchContent_Declare(
        json_nlohmann
        GIT_REPOSITORY https://github.com/nlohmann/json.git
        GIT_TAG v3.11.3
    )

    cppcmake_dependency_make_available(json_nlohmann)

    set(${OUT_TARGET} nlohmann_json::nlohmann_json PARENT_SCOPE)
endfunction()