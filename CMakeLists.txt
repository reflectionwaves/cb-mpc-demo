cmake_minimum_required(VERSION 3.20)
project(cbmpc_demo LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Where cb-mpc was installed by 'sudo make install'.
# Default matches our bootstrap: /usr/local/opt/cbmpc
if(NOT DEFINED CBMPC_PREFIX)
  if(DEFINED ENV{CBMPC_PREFIX})
    set(CBMPC_PREFIX "$ENV{CBMPC_PREFIX}")
  else()
    set(CBMPC_PREFIX "/usr/local/opt/cbmpc")
  endif()
endif()

# OpenSSL prefix (default from our bootstrap)
if(NOT DEFINED OPENSSL_ROOT_DIR)
  if(DEFINED ENV{OPENSSL_ROOT_DIR})
    set(OPENSSL_ROOT_DIR "$ENV{OPENSSL_ROOT_DIR}")
  else()
    set(OPENSSL_ROOT_DIR "/usr/local/opt/openssl@3.2.0")
  endif()
endif()

find_package(Threads REQUIRED)
find_package(OpenSSL REQUIRED)

# Find cb-mpc static library + headers
find_library(CBMPC_LIBRARY NAMES cbmpc HINTS "${CBMPC_PREFIX}/lib" REQUIRED)
set(CBMPC_INCLUDE_DIR "${CBMPC_PREFIX}/include")

# Optional: GMP
find_library(GMP_LIBRARY NAMES gmp)

set(CBMPC_DEMO_COMMON_LIBS ${CBMPC_LIBRARY} OpenSSL::SSL OpenSSL::Crypto Threads::Threads dl m)
if(GMP_LIBRARY)
  list(APPEND CBMPC_DEMO_COMMON_LIBS ${GMP_LIBRARY})
endif()

add_subdirectory(ServerA)
add_subdirectory(ServerB)
