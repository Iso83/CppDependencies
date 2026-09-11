# CppDependencies

[CppDependencies](https://github.com/Iso83/CppDependencies) provides small, reusable CMake resolvers for third-party C++ libraries.

The root `CMakeLists.txt` explicitly requests only the libraries used by the project. Each resolver first accepts an existing target, then tries a compatible CMake package, and finally falls back to a pinned `FetchContent` source. A machine with BuildFarm packages therefore configures quickly, while a clean checkout remains self-contained and buildable.

## Philosophy

CppDependencies is intentionally **not** a package manager. Dependencies are never activated automatically; each project explicitly requests only the libraries it needs.

```cmake
include(extern/CppDependencies/CppDependencies.cmake)

cppdependencies_glfw(GLFW_TARGET)
cppdependencies_imgui_docking(IMGUI_TARGET)
cppdependencies_talib(TALIB_TARGET STATIC)
cppdependencies_opencv(OPENCV_TARGETS STATIC COMPONENTS core imgproc)
```

Each dependency is implemented as an independent wrapper with a consistent API, making it safe to use across multiple projects and subprojects.

Shared-library runtimes are deployed by CppCMake after the executable has linked its dependencies:

```cmake
cppdependencies_opencv(OPENCV_TARGETS SHARED COMPONENTS core imgproc)

target_link_libraries(MyApp PRIVATE ${OPENCV_TARGETS})
cppcmake_dependency_copy_runtime(MyApp)
```

OpenCV requires an explicit `STATIC` or `SHARED` selection. Each BuildFarm package contains both Debug and Release artifacts for that linkage. Multi-configuration generators such as Visual Studio select the matching runtime configuration automatically.

## Relationship with CppCMake

**[CppCMake](https://github.com/Iso83/CppCMake) provides reusable CMake infrastructure.**

CppDependencies builds on that foundation by providing wrappers around third-party libraries. Both repositories are intentionally kept separate so they can evolve independently.

## Third-party libraries

CppDependencies only provides CMake wrappers for third-party libraries.
Each library remains subject to its own license and terms of use. It is the responsibility of the project using a dependency to review and comply with the applicable third-party licenses.
