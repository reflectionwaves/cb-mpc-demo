// ServerB/mpc_partyB.cpp
#include <iostream>
#include <fstream>
#include <string>
#include <vector>

#include <cbmpc/protocol/ecdsa_2p.h>
#include <cbmpc/crypto/ec/ec.h>
#include <cbmpc/core/mem.h>
#include <cbmpc/core/error.h>
#include <cbmpc/protocol/data_transport.h>
#include <cbmpc/protocol/job.h>

#include "http_transport.h"

using namespace coinbase;
using namespace coinbase::mpc;

extern std::vector<uint8_t> from_hex(const std::string& hex);
extern std::string to_hex(const uint8_t* data, size_t len);

static void usage() {
  std::cerr <<
    "Usage:\n"
    "  mpc_partyB dkg  --sid <sid> --self <http://host:port> --peer <http://host:port>\n"
    "  mpc_partyB sign --sid <sid> --self <http://host:port> --peer <http://host:port> --msg <32B_hex>\n";
}

int main(int argc, char** argv) {
  if (argc < 2) { usage(); return 1; }
  std::string command = argv[1];

  std::string sid, self_url, peer_url, msg_hex;
  for (int i = 2; i < argc; ++i) {
    std::string a = argv[i];
    auto next = [&](std::string& out) {
      if (i+1 >= argc) { usage(); exit(1); }
      out = argv[++i];
    };
    if (a == "--sid")  next(sid);
    else if (a == "--self") next(self_url);
    else if (a == "--peer") next(peer_url);
    else if (a == "--msg")  next(msg_hex);
  }
  if (sid.empty() || self_url.empty() || peer_url.empty()) { usage(); return 1; }

  const mpc::party_idx_t MY_IDX = 1;
  auto net = std::make_shared<mpcnet::HttpTransport>(MY_IDX, self_url, peer_url, sid);
  job_2p_t job(party_t::p2, net);  // adjust ctor if needed
  crypto::ecurve_t curve = crypto::curve_secp256k1;

  mpc::ecdsa2pc::key_t key;

  if (command == "dkg") {
    error_t rv = mpc::ecdsa2pc::dkg(job, curve, key);
    if (rv != SUCCESS) { std::cerr << "PartyB DKG failed: " << rv << "\n"; return 2; }
    // Persist
    std::ofstream f("partyB_keyshare.bin", std::ios::binary);
    auto key_bytes = key.serialize();
    f.write(reinterpret_cast<const char*>(key_bytes.data()), key_bytes.size());
    f.close();

    auto Q_bytes = key.Q.to_bytes();
    std::cout << "PubKey(compressed)=" << mpcnet::to_hex(Q_bytes.data(), Q_bytes.size()) << std::endl;
    return 0;
  }

  if (command == "sign") {
    if (msg_hex.empty()) { usage(); return 1; }
    std::ifstream f("partyB_keyshare.bin", std::ios::binary);
    if (!f.good()) { std::cerr << "Missing partyB_keyshare.bin (run dkg first)\n"; return 1; }
    std::vector<uint8_t> kb((std::istreambuf_iterator<char>(f)), {});
    f.close();
    if (!key.deserialize(mem_t(kb))) { std::cerr << "Failed to parse key share\n"; return 1; }

    std::vector<uint8_t> msg = from_hex(msg_hex);
    if (msg.size() != 32) { std::cerr << "Message must be 32-byte hash in hex\n"; return 1; }

    buf_t sid_buf;
    buf_t sig;
    error_t rv = mpc::ecdsa2pc::sign(job, sid_buf, key, mem_t(msg), sig);
    if (rv != SUCCESS) { std::cerr << "PartyB sign failed: " << rv << "\n"; return 3; }

    std::cout << "Signature=" << mpcnet::to_hex(sig.data(), sig.size()) << std::endl;
    return 0;
  }

  usage();
  return 1;
}
