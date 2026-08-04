include_guard(GLOBAL)

# ============================================================================
# Options
# ============================================================================

option(CPPDEPENDENCIES_USE_SYSTEM_PACKAGES
    "Prefer system packages over FetchContent"
    OFF
)

# ============================================================================
# Dependencies
# ============================================================================

include("${CMAKE_CURRENT_LIST_DIR}/freetype/freetype.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/glad/glad.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/glfw/glfw.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/glm/glm.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/imgui/docking.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/json/nlohmann.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/nfd/nfd.cmake")