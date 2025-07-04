# example module for linking to the lib in downstream projects

set(LIBNAME libvalhalla_test.a)
find_library(VALHALLA_TEST_LIB ${LIBNAME} PATH_SUFFIXES lib)

find_path(VALHALLA_TEST_INCLUDE_DIR valhalla/test.h
    PATH_SUFFIXES include
    PATHS ${CMAKE_SOURCE_DIR}/../valhalla
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ValhallaTest
                                  REQUIRED_VARS VALHALLA_TEST_LIB VALHALLA_TEST_INCLUDE_DIR)
