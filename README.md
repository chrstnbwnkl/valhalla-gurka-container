# Valhalla Test Container Image

A container image containing dependencies to write your own Gurka tests for applications using Valhalla's C++ API.

## Usage 

```sh 
docker  pull ghcr.io/chrstnbwnkl/valhalla-dev:latest

# or if you want a specific version of Valhalla (reach out if you need an older version)
docker  pull ghcr.io/chrstnbwnkl/valhalla-dev:3.5.1
```

The image contains a release build of Valhalla with debug information along with Valhalla's test library and headers that you can link your project against if you want to write your own Gurka tests. 

`cmake/FindValhallaTest.cmake` contains an example module that you can use for linking. You can copy that module into your project and use it like this: 

```cmake 
# Filename: CMakeLists.txt
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
