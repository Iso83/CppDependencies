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
   

    #[[FetchContent_Declare(
        json_nlohmann
        GIT_REPOSITORY https://github.com/nlohmann/json.git
        GIT_TAG v3.11.3
    )]]

    FetchContent_Declare(
        json_nlohmann
        URL https://github.com/nlohmann/json/releases/download/v3.12.0/json.tar.xz
        URL_HASH SHA256=42f6e95cad6ec532fd372391373363b62a14af6d771056dbfc86160e6dfff7aa
    )

    cppcmake_dependency_make_available(json_nlohmann)

    set(${OUT_TARGET} nlohmann_json::nlohmann_json PARENT_SCOPE)
endfunction()