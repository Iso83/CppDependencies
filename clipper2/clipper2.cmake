include_guard(GLOBAL)

include(FetchContent)

function(cppdependencies_clipper2 OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides the Clipper2 dependency target.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the Clipper2 target name.
    # =========================================================

    if(TARGET Clipper2::Clipper2)
        set(${OUT_TARGET} Clipper2::Clipper2 PARENT_SCOPE)
        return()
    endif()

    FetchContent_Declare(
        Clipper2
        GIT_REPOSITORY https://github.com/AngusJohnson/Clipper2.git
        GIT_TAG f9c5eb6e14a59f6f5d65fbfb3564519a561cf4fd
        GIT_SHALLOW TRUE
        SOURCE_SUBDIR CPP
    )

    set(CLIPPER2_UTILS OFF CACHE BOOL "" FORCE)
    set(CLIPPER2_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(CLIPPER2_TESTS OFF CACHE BOOL "" FORCE)
    set(CLIPPER2_USINGZ OFF CACHE STRING "" FORCE)

    cppcmake_dependency_make_available(Clipper2)
    
    cppcmake_dependency_set_folder(Clipper2 "")

    set(${OUT_TARGET} Clipper2::Clipper2 PARENT_SCOPE)
endfunction()