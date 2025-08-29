add_executable(mpc_partyA mpc_partyA.cpp)

target_include_directories(mpc_partyA PRIVATE "${CBMPC_INCLUDE_DIR}")
if(CBMPC_SOURCE_DIR)
  target_include_directories(mpc_partyA PRIVATE "${CBMPC_SOURCE_DIR}")
endif()

target_link_libraries(mpc_partyA PRIVATE ${CBMPC_DEMO_COMMON_LIBS})
