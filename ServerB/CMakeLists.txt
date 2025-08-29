add_executable(mpc_partyB mpc_partyB.cpp)

target_include_directories(mpc_partyB PRIVATE "${CBMPC_INCLUDE_DIR}")
if(CBMPC_SOURCE_DIR)
  target_include_directories(mpc_partyB PRIVATE "${CBMPC_SOURCE_DIR}")
endif()

target_link_libraries(mpc_partyB PRIVATE ${CBMPC_DEMO_COMMON_LIBS})
