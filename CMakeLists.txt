cmake_minimum_required(VERSION 3.20)
project(cbmpc_demo LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Where cb-mpc was installed by 'sudo make install'
if(NOT DEFINED CBMPC_PREFIX)
  if(DEFINED ENV{CBMPC_PREFIX})
    set(CBMPC_PREFIX "$ENV{CBMPC_PREFIX}")
  else()
    set(CBMPC_PREFIX "/usr/local/opt/cbmpc")
  endif()
endif()

# OpenSSL (static build default path from our setup)
if(NOT DEFINED OPENSSL_ROOT_DIR)
  if(DEFINED ENV{OPENSSL_ROOT_DIR})
    set(OPENSSL_ROOT_DIR "$ENV{OPENSSL_ROOT_DIR}")
  else()
    set(OPENSSL_ROOT_DIR "/usr/local/opt/openssl@3.2.0")
  endif()
endif()

# Help CMake look under these prefixes
if(CMAKE_PREFIX_PATH)
  list(APPEND CMAKE_PREFIX_PATH "${CBMPC_PREFIX}" "${OPENSSL_ROOT_DIR}")
else()
  set(CMAKE_PREFIX_PATH "${CBMPC_PREFIX};${OPENSSL_ROOT_DIR}")
endif()

find_package(Threads REQUIRED)
find_package(OpenSSL REQUIRED)

# cb-mpc static lib
find_library(CBMPC_LIBRARY NAMES cbmpc HINTS "${CBMPC_PREFIX}/lib" REQUIRED)

# Installed headers
find_path(CBMPC_INCLUDE_DIR
  NAMES cbmpc/protocol/mpc_job.h cbmpc/crypto/base.h
  HINTS "${CBMPC_PREFIX}/include" "/usr/local/include" "/usr/include"
  REQUIRED)

# Optional: cb-mpc source tree for internal headers like cbmpc/crypto/ec/ec.h
if(NOT CBMPC_SOURCE_DIR AND DEFINED ENV{CBMPC_SOURCE_DIR})
  set(CBMPC_SOURCE_DIR "$ENV{CBMPC_SOURCE_DIR}")
endif()
if(NOT CBMPC_SOURCE_DIR)
  foreach(p "${CBMPC_PREFIX}/src" "${CMAKE_SOURCE_DIR}/../cb-mpc/src" "$ENV{HOME}/cb-mpc/src")
    if(EXISTS "${p}/cbmpc/crypto")
      set(CBMPC_SOURCE_DIR "${p}")
      break()
    endif()
  endforeach()
endif()

message(STATUS "CBMPC_PREFIX=${CBMPC_PREFIX}")
message(STATUS "OPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR}")
message(STATUS "CBMPC_INCLUDE_DIR=${CBMPC_INCLUDE_DIR}")
message(STATUS "CBMPC_SOURCE_DIR=${CBMPC_SOURCE_DIR}")

set(CBMPC_DEMO_COMMON_LIBS
  ${CBMPC_LIBRARY}
  OpenSSL::SSL
  OpenSSL::Crypto
  Threads::Threads
  dl
  m
)

# Reduce noisy warnings from upstream headers when using Clang
if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wno-parentheses)
endif()

add_subdirectory(ServerA)
add_subdirectory(ServerB)
