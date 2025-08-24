// ServerA/mpc_partyA.cpp
#include <iostream>
#include <fstream>
#include <string>
#include <vector>

// cb-mpc
#include <cbmpc/protocol/ecdsa_2p.h>       // coinbase::mpc::ecdsa2pc::{dkg, sign}
#include <cbmpc/crypto/ec/ec.h>            // curve definitions, key utils
#include <cbmpc/core/mem.h>
#include <cbmpc/core/error.h>
#include <cbmpc/protocol/data_transport.h>
#include <cbmpc/protocol/job.h>            // job_2p_t (exact header path may vary)

// our transport
#include "http_transport.h"

using namespace coinbase;
using namespace coinbase::mpc;

// simple hex helpers (reuse transport’s)
extern std::vector<uint8_t> from_hex(const std::string& hex);
extern std::string to_hex(const uint8_t* data, size_t len);

static void usage() {
  std::cerr <<
    "Usage:\n"
    "  mpc_partyA dkg  --sid <sid> --self <http://host:port> --peer <http://host:port>\n"
    "  mpc_partyA sign --sid <sid> --self <http://host:port> --peer <http://host:port> --msg <32B_hex>\n";
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

  // Party indices: A=0, B=1 (must match both sides)
  const mpc::party_idx_t MY_IDX = 0;

  // Build HTTP transport
  auto net = std::make_shared<mpcnet::HttpTransport>(MY_IDX, self_url, peer_url, sid);

  // Build two-party job context (check your header for exact ctor)
  // The job needs our role (p1) and the transport.
  job_2p_t job(party_t::p1, net);  // If your version needs extra args, adjust (e.g., peer id)

  // Curve
  crypto::ecurve_t curve = crypto::curve_secp256k1;

  // Key share persists between DKG and SIGN
  mpc::ecdsa2pc::key_t key;

  if (command == "dkg") {
    // Run distributed key generation (blocking; uses our HttpTransport under the hood)
    error_t rv = mpc::ecdsa2pc::dkg(job, curve, key);
    if (rv != SUCCESS) {
      std::cerr << "PartyA DKG failed: " << rv << "\n"; return 2;
    }

    // Save key share to disk for later signing
    std::ofstream f("partyA_keyshare.bin", std::ios::binary);
    auto key_bytes = key.serialize(); // if your version uses different API, adjust (e.g., to_bytes())
    f.write(reinterpret_cast<const char*>(key_bytes.data()), key_bytes.size());
    f.close();

    // Print compressed pubkey hex
    auto Q_bytes = key.Q.to_bytes(); // 33-byte compressed
    std::cout << "PubKey(compressed)=" << mpcnet::to_hex(Q_bytes.data(), Q_bytes.size()) << std::endl;
    return 0;
  }

  if (command == "sign") {
    if (msg_hex.empty()) { usage(); return 1; }
    // Load key share
    std::ifstream f("partyA_keyshare.bin", std::ios::binary);
    if (!f.good()) { std::cerr << "Missing partyA_keyshare.bin (run dkg first)\n"; return 1; }
    std::vector<uint8_t> kb((std::istreambuf_iterator<char>(f)), {});
    f.close();
    if (!key.deserialize(mem_t(kb))) { std::cerr << "Failed to parse key share\n"; return 1; }

    // Message must be 32 bytes (hash)
    std::vector<uint8_t> msg = from_hex(msg_hex);
    if (msg.size() != 32) {
      std::cerr << "Message must be 32-byte hash in hex\n"; return 1;
    }

    // Session id buffer (can be empty; library may fill)
    buf_t sid_buf; // optional; keep empty to let lib derive, or set from 'sid'

    buf_t sig;
    error_t rv = mpc::ecdsa2pc::sign(job, sid_buf, key, mem_t(msg), sig);
    if (rv != SUCCESS) {
      std::cerr << "PartyA sign failed: " << rv << "\n"; return 3;
    }

    // Print signature as hex (DER or (r||s) depending on library build)
    std::cout << "Signature=" << mpcnet::to_hex(sig.data(), sig.size()) << std::endl;
    return 0;
  }

  usage();
  return 1;
}
