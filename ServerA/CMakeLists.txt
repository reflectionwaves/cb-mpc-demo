# CMakeLists.txt snippet
find_package(PkgConfig REQUIRED)
pkg_check_modules(CURL REQUIRED libcurl)

include_directories(/usr/local/opt/cbmpc/include)   # adjust if installed elsewhere
link_directories(/usr/local/opt/cbmpc/lib)

add_library(http_transport http_transport.cpp)
target_include_directories(http_transport PUBLIC ${CURL_INCLUDE_DIRS})
target_link_libraries(http_transport ${CURL_LIBRARIES})

add_executable(mpc_partyA ServerA/mpc_partyA.cpp)
target_link_libraries(mpc_partyA http_transport cbmpc ${CURL_LIBRARIES})

add_executable(mpc_partyB ServerB/mpc_partyB.cpp)
target_link_libraries(mpc_partyB http_transport cbmpc ${CURL_LIBRARIES})
