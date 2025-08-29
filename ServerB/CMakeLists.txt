# Party B target
add_executable(mpc_partyB mpc_partyB.cpp)
target_include_directories(mpc_partyB PRIVATE "${CBMPC_INCLUDE_DIR}")
target_link_libraries(mpc_partyB PRIVATE ${CBMPC_DEMO_COMMON_LIBS})
