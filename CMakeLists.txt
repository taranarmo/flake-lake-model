cmake_minimum_required(VERSION 3.16)
project(FLake
  VERSION 1.0.0
  DESCRIPTION "Fresh-water Lake model (FLake) Fortran core library and CLI"
  HOMEPAGE_URL "https://github.com/taranarmo/flake-lake-model"
  LANGUAGES Fortran
)

set(CMAKE_Fortran_STANDARD 90)
set(CMAKE_Fortran_STANDARD_REQUIRED ON)

# Compiler warnings and optimization flags
if(CMAKE_Fortran_COMPILER_ID MATCHES "GNU")
  add_compile_options(-O3 -fPIC)
endif()

# Core library sources (in compilation order)
set(FLAKE_SOURCES
  src/data_parameters.f90
  src/flake_derivedtypes.f90
  src/flake_parameters.f90
  src/flake_configure.f90
  src/flake_albedo_ref.f90
  src/flake_paramoptic_ref.f90
  src/flake.f90
  src/SfcFlx.f90
  src/src_flake_interface_1D.f90
)

# Core FLake library
add_library(flake_core STATIC ${FLAKE_SOURCES})
target_include_directories(flake_core PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
  $<INSTALL_INTERFACE:include>
)

# FLake CLI driver executable
add_executable(flake app/flake_cli.f90)
target_link_libraries(flake PRIVATE flake_core)
target_include_directories(flake PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/src
  ${CMAKE_CURRENT_BINARY_DIR}
)

# Testing
enable_testing()

add_test(
  NAME test_heiligensee
  COMMAND flake ${CMAKE_CURRENT_SOURCE_DIR}/examples/Heiligensee80-96/Heiligensee80-96.nml
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)

add_test(
  NAME test_mueggelsee
  COMMAND flake ${CMAKE_CURRENT_SOURCE_DIR}/examples/Mueggelsee80-96/Mueggelsee80-96.nml
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)

add_test(
  NAME test_stechlin
  COMMAND flake ${CMAKE_CURRENT_SOURCE_DIR}/examples/Stechlin94-98/Stechlin94-98.nml
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)

# Installation rules
include(GNUInstallDirs)
install(TARGETS flake flake_core
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/src/
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/flake
  FILES_MATCHING PATTERN "*.f90" PATTERN "*.incf"
)
