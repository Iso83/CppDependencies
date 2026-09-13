include_guard(GLOBAL)

# ============================================================================
# CppDependencies instance
# ============================================================================
#
# The first CppDependencies.cmake included by the project becomes the active
# dependency provider for the complete CMake configuration.
#
# Nested projects may include their own CppDependencies.cmake as usual. Those
# includes are ignored when another instance is already active.
#
# To explicitly load another instance, set CPPDEPENDENCIES_FORCE_LOAD to ON
# immediately before including its CppDependencies.cmake. The flag is consumed
# by this file and reset automatically.
#
# Example:
#
#   set(CPPDEPENDENCIES_FORCE_LOAD ON)
#   include("${CMAKE_CURRENT_LIST_DIR}/extern/CppDependencies/CppDependencies.cmake")
#
# ============================================================================

get_property(
    CPPDEPENDENCIES_ACTIVE
    GLOBAL
    PROPERTY CPPDEPENDENCIES_ACTIVE
)

if(CPPDEPENDENCIES_ACTIVE AND NOT CPPDEPENDENCIES_FORCE_LOAD)
    return()
endif()

# FORCE_LOAD is intentionally one-shot.
unset(CPPDEPENDENCIES_FORCE_LOAD)

set_property(
    GLOBAL
    PROPERTY CPPDEPENDENCIES_ACTIVE TRUE
)

set_property(
    GLOBAL
    PROPERTY CPPDEPENDENCIES_ROOT "${CMAKE_CURRENT_LIST_DIR}"
)

# ============================================================================
# Dependencies
# ============================================================================

include("${CMAKE_CURRENT_LIST_DIR}/cli11/cli11.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/clipper2/clipper2.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cpputility/cpputility.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/curl/curl.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/freetype/freetype.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/glad/glad.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/glfw/glfw.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/glm/glm.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/imgui/docking.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/implot/implot.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/json/nlohmann.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/nfd/nfd.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/opencv/opencv.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/sqlite/sqlite.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/talib/talib.cmake")