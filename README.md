# Valhalla Test Container Image

A container image for writing your own Gurka tests for applications using Valhalla's C++ API

## Introduction 

Valhalla uses its own integration test library called Gurka. Besides a lot of convenient features for running actions and checking their outcomes (e.g. routes, matrix, etc.) its most practical use is drawing ASCII maps and converting them into OSM maps and Valhalla graphs. Here's what that looks like:  

```cpp
using namespace valhalla;

constexpr double gridsize = 100;
const std::string ascii_map = R"(
    A-B-C-D-E
        |
        |1
        F···G
        |
        |2
        H
  )";

const gurka::ways ways = {
{"AB", {{"highway", "primary"}}}, {"BC", {{"highway", "primary"}}},
{"CD", {{"highway", "primary"}}}, {"DE", {{"highway", "primary"}}},
{"CF", {{"highway", "service"}}}, {"FH", {{"highway", "service"}}},
{"FG", {{"highway", "footway"}}},
};

const gurka::nodes nodes = {{"E", {{"barrier", "block"}}}};

const auto layout = gurka::detail::map_to_coordinates(ascii_map, gridsize);

auto map = gurka::buildtiles(layout, ways, nodes, {}, "test/data/deadend");
```

You can read more about Gurka [here](https://github.com/valhalla/valhalla/blob/master/docs/docs/test/gurka.md).

## Usage 

Just pull the image and use it to integrate with your own application:

```sh 
docker pull ghcr.io/chrstnbwnkl/valhalla-gurka-container/valhalla-dev:latest

# or if you want a specific version of Valhalla (reach out if you need an older version)
docker pull ghcr.io/chrstnbwnkl/valhalla-gurka-container/valhalla-dev:3.5.1
```

The image contains a release build of Valhalla with debug information along with Valhalla's test library and headers that you can link your project against if you want to write your own Gurka tests. 

`cmake/FindValhallaTest.cmake` contains an example module that you can use for linking. You can copy that module into your project and use it like this: 

```cmake 
# in your CMakeLists.txt
find_package(ValhallaTest REQUIRED)

# Valhalla vendors googletest
pkg_check_modules(GMOCK REQUIRED IMPORTED_TARGET gmock)
pkg_check_modules(GTEST_MAIN REQUIRED IMPORTED_TARGET gtest_main)
pkg_check_modules(GTEST REQUIRED IMPORTED_TARGET gtest)

target_link_libraries(${your_test} PkgConfig::GTEST PkgConfig::GTEST_MAIN PkgConfig::GMOCK ${VALHALLA_TEST_LIB})
``` 


Then in your tests, you can include everything you need like this: 

```cpp 
#include <gtest/gtest.h>
#include <valhalla/gurka.h>
#include <valhalla/test.h>

// ...your tests here, just like in the upstream repo
```
