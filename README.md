# CppDependencies
[CppDependencies](https://github.com/Iso83/CppDependencies) provides reusable CMake wrappers for third-party C++ libraries.

The goal is to expose a stable interface for external dependencies by pinning validated versions and hiding library-specific CMake configuration. This allows projects to remain independent of upstream CMake implementations and simplifies future library upgrades.

## Philosophy
CppDependencies is intentionally **not** a package manager. Dependencies are never activated automatically; each project explicitly requests only the libraries it needs.
```cmake
include(extern/CppDependencies/CppDependencies.cmake)

cppdependencies_glfw(GLFW_TARGET)
cppdependencies_imgui(IMGUI_TARGET)
```
Each dependency is implemented as an independent wrapper with a consistent API, making it safe to use across multiple projects and subprojects.

## Relationship with CppCMake
**[CppCMake](https://github.com/Iso83/CppCMake) provides reusable CMake infrastructure.**

CppDependencies builds on that foundation by providing wrappers around third-party libraries. Both repositories are intentionally kept separate so they can evolve independently.

## Third-party libraries
CppDependencies only provides CMake wrappers for third-party libraries.
Each library remains subject to its own license and terms of use. It is the responsibility of the project using a dependency to review and comply with the applicable third-party licenses.
