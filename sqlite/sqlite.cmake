include_guard(GLOBAL)

set(_CPPDEPENDENCIES_SQLITE_DIR "${CMAKE_CURRENT_LIST_DIR}")

function(_cppdependencies_sqlite3_create)
    add_library(SQLite3 STATIC
        "${_CPPDEPENDENCIES_SQLITE_DIR}/src/sqlite3.c"
    )

    add_library(SQLite3::SQLite3 ALIAS SQLite3)

    target_include_directories(SQLite3
        PUBLIC
            "${_CPPDEPENDENCIES_SQLITE_DIR}/include"
    )

    target_compile_features(SQLite3
        PUBLIC
            c_std_99
    )

    cppcmake_dependency_set_folder(
        SQLite3
        ""
    )
endfunction()

function(cppdependencies_sqlite OUT_TARGET)
    # =========================================================
    # Summary
    #
    # Provides the SQLite dependency target.
    #
    # Parameters:
    #   [out] OUT_TARGET - Receives the SQLite target name.
    # =========================================================

    if(NOT TARGET SQLite3::SQLite3)
        find_package(SQLite3 QUIET)
    endif()

    if(NOT TARGET SQLite3::SQLite3)
        _cppdependencies_sqlite3_create()
    endif()

    set(${OUT_TARGET} SQLite3::SQLite3 PARENT_SCOPE)
endfunction()