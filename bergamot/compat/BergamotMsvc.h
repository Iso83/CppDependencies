#pragma once

// Initialize the STL before temporarily selecting fmt's ordinary pointer path.
// This preserves MSVC's iterator debugging and its ABI in Debug builds.
#include <iterator>

#pragma push_macro("_SECURE_SCL")
#undef _SECURE_SCL
#define _SECURE_SCL 0
#include <spdlog/details/format.h>
#pragma pop_macro("_SECURE_SCL")

// Old fmt defines this as an alias of _SECURE_SCL. Freeze its selected
// pointer implementation after restoring the STL macro.
#undef FMT_SECURE_SCL
#define FMT_SECURE_SCL 0
