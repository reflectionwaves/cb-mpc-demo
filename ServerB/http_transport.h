// http_transport.h
#pragma once

#include <string>
#include <vector>
#include <memory>
#include <cstdint>

// ---- cb-mpc core headers ----
#include <cbmpc/protocol/data_transport.h>   // data_transport_interface_t, party_idx_t
#include <cbmpc/core/mem.h>                  // coinbase::mem_t, coinbase::buf_t
#include <cbmpc/core/error.h>                // coinbase::error_t

namespace mpcnet {

// Hex helpers (no external deps)
std::string to_hex(const uint8_t* data, size_t len);
std::vector<uint8_t> from_hex(const std::string& hex);

// Minimal HTTP client (libcurl) wrappers
struct HttpClient {
  static bool post_json(const std::string& url, const std::string& body,
                        long* http_code, std::string* resp_body, long timeout_ms = 10000);
  static bool get(const std::string& url, long* http_code, std::string* resp_body,
                  long timeout_ms = 30000);
};

// HTTP-based implementation of Coinbase cb-mpc data transport.
//
// Design:
//  - send(): POST to peer's /mpc/enqueue  (peer writes to its local inbound queue)
//  - receive(): GET from our local /mpc/dequeue (we pop from our local inbound queue)
// This matches the "two-server" design and removes the need for local threads.
class HttpTransport final : public coinbase::mpc::data_transport_interface_t {
public:
  // my_idx: this party index (usually 0 or 1).
  // self_base: e.g. "http://127.0.0.1:5001"
  // peer_base: e.g. "http://10.0.0.12:5001"
  // sid: session identifier (both parties MUST use the same sid)
  HttpTransport(coinbase::mpc::party_idx_t my_idx,
                std::string self_base,
                std::string peer_base,
                std::string sid);

  // ---- data_transport_interface_t ----
  coinbase::error_t send(coinbase::mpc::party_idx_t receiver,
                         const coinbase::mem_t& msg) override;

  coinbase::error_t receive(coinbase::mpc::party_idx_t sender,
                            coinbase::mem_t& msg) override;

  coinbase::error_t receive_all(const std::vector<coinbase::mpc::party_idx_t>& senders,
                                std::vector<coinbase::mem_t>& messages) override;

  // Optional: tuning
  void set_poll_interval_ms(unsigned ms) { poll_interval_ms_ = ms; }
  void set_receive_timeout_ms(unsigned ms) { receive_timeout_ms_ = ms; }

private:
  coinbase::mpc::party_idx_t my_idx_;
  std::string self_base_;
  std::string peer_base_;
  std::string sid_;

  // Internal storage for last received buffer (mem_t is a view, so keep backing data)
  std::vector<uint8_t> rx_storage_;

  unsigned poll_interval_ms_ = 100;   // ms
  unsigned receive_timeout_ms_ = 30000; // ms total

  std::string enqueue_url_peer() const { return peer_base_ + "/mpc/enqueue"; }
  // GET /mpc/dequeue?sid=...&sender=...
  std::string dequeue_url_self(coinbase::mpc::party_idx_t sender) const;
};

} // namespace mpcnet
