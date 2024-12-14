include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(CPP_cmake_template_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(CPP_cmake_template_setup_options)
  option(CPP_cmake_template_ENABLE_HARDENING "Enable hardening" ON)
  option(CPP_cmake_template_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    CPP_cmake_template_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    CPP_cmake_template_ENABLE_HARDENING
    OFF)

  CPP_cmake_template_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR CPP_cmake_template_PACKAGING_MAINTAINER_MODE)
    option(CPP_cmake_template_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(CPP_cmake_template_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(CPP_cmake_template_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(CPP_cmake_template_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(CPP_cmake_template_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(CPP_cmake_template_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(CPP_cmake_template_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(CPP_cmake_template_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(CPP_cmake_template_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(CPP_cmake_template_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(CPP_cmake_template_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(CPP_cmake_template_ENABLE_PCH "Enable precompiled headers" OFF)
    option(CPP_cmake_template_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(CPP_cmake_template_ENABLE_IPO "Enable IPO/LTO" ON)
    option(CPP_cmake_template_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(CPP_cmake_template_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(CPP_cmake_template_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(CPP_cmake_template_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(CPP_cmake_template_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(CPP_cmake_template_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(CPP_cmake_template_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(CPP_cmake_template_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(CPP_cmake_template_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(CPP_cmake_template_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(CPP_cmake_template_ENABLE_PCH "Enable precompiled headers" OFF)
    option(CPP_cmake_template_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      CPP_cmake_template_ENABLE_IPO
      CPP_cmake_template_WARNINGS_AS_ERRORS
      CPP_cmake_template_ENABLE_USER_LINKER
      CPP_cmake_template_ENABLE_SANITIZER_ADDRESS
      CPP_cmake_template_ENABLE_SANITIZER_LEAK
      CPP_cmake_template_ENABLE_SANITIZER_UNDEFINED
      CPP_cmake_template_ENABLE_SANITIZER_THREAD
      CPP_cmake_template_ENABLE_SANITIZER_MEMORY
      CPP_cmake_template_ENABLE_UNITY_BUILD
      CPP_cmake_template_ENABLE_CLANG_TIDY
      CPP_cmake_template_ENABLE_CPPCHECK
      CPP_cmake_template_ENABLE_COVERAGE
      CPP_cmake_template_ENABLE_PCH
      CPP_cmake_template_ENABLE_CACHE)
  endif()

  CPP_cmake_template_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (CPP_cmake_template_ENABLE_SANITIZER_ADDRESS OR CPP_cmake_template_ENABLE_SANITIZER_THREAD OR CPP_cmake_template_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(CPP_cmake_template_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(CPP_cmake_template_global_options)
  if(CPP_cmake_template_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    CPP_cmake_template_enable_ipo()
  endif()

  CPP_cmake_template_supports_sanitizers()

  if(CPP_cmake_template_ENABLE_HARDENING AND CPP_cmake_template_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR CPP_cmake_template_ENABLE_SANITIZER_UNDEFINED
       OR CPP_cmake_template_ENABLE_SANITIZER_ADDRESS
       OR CPP_cmake_template_ENABLE_SANITIZER_THREAD
       OR CPP_cmake_template_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${CPP_cmake_template_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${CPP_cmake_template_ENABLE_SANITIZER_UNDEFINED}")
    CPP_cmake_template_enable_hardening(CPP_cmake_template_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(CPP_cmake_template_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(CPP_cmake_template_warnings INTERFACE)
  add_library(CPP_cmake_template_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  CPP_cmake_template_set_project_warnings(
    CPP_cmake_template_warnings
    ${CPP_cmake_template_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(CPP_cmake_template_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    CPP_cmake_template_configure_linker(CPP_cmake_template_options)
  endif()

  include(cmake/Sanitizers.cmake)
  CPP_cmake_template_enable_sanitizers(
    CPP_cmake_template_options
    ${CPP_cmake_template_ENABLE_SANITIZER_ADDRESS}
    ${CPP_cmake_template_ENABLE_SANITIZER_LEAK}
    ${CPP_cmake_template_ENABLE_SANITIZER_UNDEFINED}
    ${CPP_cmake_template_ENABLE_SANITIZER_THREAD}
    ${CPP_cmake_template_ENABLE_SANITIZER_MEMORY})

  set_target_properties(CPP_cmake_template_options PROPERTIES UNITY_BUILD ${CPP_cmake_template_ENABLE_UNITY_BUILD})

  if(CPP_cmake_template_ENABLE_PCH)
    target_precompile_headers(
      CPP_cmake_template_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(CPP_cmake_template_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    CPP_cmake_template_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(CPP_cmake_template_ENABLE_CLANG_TIDY)
    CPP_cmake_template_enable_clang_tidy(CPP_cmake_template_options ${CPP_cmake_template_WARNINGS_AS_ERRORS})
  endif()

  if(CPP_cmake_template_ENABLE_CPPCHECK)
    CPP_cmake_template_enable_cppcheck(${CPP_cmake_template_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(CPP_cmake_template_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    CPP_cmake_template_enable_coverage(CPP_cmake_template_options)
  endif()

  if(CPP_cmake_template_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(CPP_cmake_template_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(CPP_cmake_template_ENABLE_HARDENING AND NOT CPP_cmake_template_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR CPP_cmake_template_ENABLE_SANITIZER_UNDEFINED
       OR CPP_cmake_template_ENABLE_SANITIZER_ADDRESS
       OR CPP_cmake_template_ENABLE_SANITIZER_THREAD
       OR CPP_cmake_template_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    CPP_cmake_template_enable_hardening(CPP_cmake_template_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
