// http_transport.cpp
#include "http_transport.h"
#include <sstream>
#include <thread>
#include <chrono>
#include <cstring>

// libcurl
#include <curl/curl.h>

using coinbase::error_t;
using coinbase::buf_t;
using coinbase::mem_t;
using coinbase::mpc::party_idx_t;

namespace mpcnet {

// ---------- hex ----------
static inline uint8_t hexval(char c) {
  if (c >= '0' && c <= '9') return uint8_t(c - '0');
  if (c >= 'a' && c <= 'f') return uint8_t(c - 'a' + 10);
  if (c >= 'A' && c <= 'F') return uint8_t(c - 'A' + 10);
  return 0;
}

std::string to_hex(const uint8_t* data, size_t len) {
  static const char* H = "0123456789abcdef";
  std::string out; out.resize(len * 2);
  for (size_t i = 0; i < len; ++i) {
    out[2*i]   = H[(data[i] >> 4) & 0xF];
    out[2*i+1] = H[data[i] & 0xF];
  }
  return out;
}
std::vector<uint8_t> from_hex(const std::string& hex) {
  std::string h = (hex.rfind("0x", 0) == 0) ? hex.substr(2) : hex;
  if (h.size() % 2) throw std::runtime_error("hex length must be even");
  std::vector<uint8_t> out(h.size()/2);
  for (size_t i = 0; i < out.size(); ++i) {
    out[i] = (hexval(h[2*i]) << 4) | hexval(h[2*i+1]);
  }
  return out;
}

// ---------- curl ----------
static size_t curl_write_cb(void* contents, size_t size, size_t nmemb, void* userp) {
  size_t total = size * nmemb;
  std::string* s = static_cast<std::string*>(userp);
  s->append(static_cast<char*>(contents), total);
  return total;
}

static CURL* new_easy() {
  CURL* h = curl_easy_init();
  if (!h) throw std::runtime_error("curl_easy_init failed");
  curl_easy_setopt(h, CURLOPT_FOLLOWLOCATION, 1L);
  curl_easy_setopt(h, CURLOPT_NOPROGRESS, 1L);
  curl_easy_setopt(h, CURLOPT_USERAGENT, "cbmpc-http-transport/1.0");
  return h;
}

bool HttpClient::post_json(const std::string& url, const std::string& body,
                           long* http_code, std::string* resp_body, long timeout_ms) {
  CURL* h = new_easy();
  struct curl_slist* headers = nullptr;
  headers = curl_slist_append(headers, "Content-Type: application/json");
  curl_easy_setopt(h, CURLOPT_HTTPHEADER, headers);
  curl_easy_setopt(h, CURLOPT_URL, url.c_str());
  curl_easy_setopt(h, CURLOPT_POST, 1L);
  curl_easy_setopt(h, CURLOPT_POSTFIELDS, body.c_str());
  curl_easy_setopt(h, CURLOPT_POSTFIELDSIZE, long(body.size()));
  std::string out;
  curl_easy_setopt(h, CURLOPT_WRITEFUNCTION, curl_write_cb);
  curl_easy_setopt(h, CURLOPT_WRITEDATA, &out);
  curl_easy_setopt(h, CURLOPT_TIMEOUT_MS, timeout_ms);

  CURLcode rc = curl_easy_perform(h);
  long code = 0;
  curl_easy_getinfo(h, CURLINFO_RESPONSE_CODE, &code);
  if (http_code) *http_code = code;
  if (resp_body) *resp_body = std::move(out);
  curl_slist_free_all(headers);
  curl_easy_cleanup(h);
  return (rc == CURLE_OK);
}

bool HttpClient::get(const std::string& url, long* http_code, std::string* resp_body,
                     long timeout_ms) {
  CURL* h = new_easy();
  curl_easy_setopt(h, CURLOPT_URL, url.c_str());
  std::string out;
  curl_easy_setopt(h, CURLOPT_WRITEFUNCTION, curl_write_cb);
  curl_easy_setopt(h, CURLOPT_WRITEDATA, &out);
  curl_easy_setopt(h, CURLOPT_TIMEOUT_MS, timeout_ms);
  CURLcode rc = curl_easy_perform(h);
  long code = 0;
  curl_easy_getinfo(h, CURLINFO_RESPONSE_CODE, &code);
  if (http_code) *http_code = code;
  if (resp_body) *resp_body = std::move(out);
  curl_easy_cleanup(h);
  return (rc == CURLE_OK);
}

// ---------- HttpTransport ----------
HttpTransport::HttpTransport(party_idx_t my_idx,
                             std::string self_base,
                             std::string peer_base,
                             std::string sid)
: my_idx_(my_idx),
  self_base_(std::move(self_base)),
  peer_base_(std::move(peer_base)),
  sid_(std::move(sid)) {}

std::string HttpTransport::dequeue_url_self(party_idx_t sender) const {
  std::ostringstream oss;
  oss << self_base_ << "/mpc/dequeue?sid=" << sid_ << "&sender=" << sender;
  return oss.str();
}

error_t HttpTransport::send(party_idx_t receiver, const mem_t& msg) {
  // JSON: {"sid":"...", "sender": <my_idx>, "receiver": <receiver>, "payload_hex":"..."}
  std::string payload_hex = to_hex(static_cast<const uint8_t*>(msg.ptr()), msg.size());
  std::ostringstream body;
  body << "{\"sid\":\"" << sid_ << "\","
       << "\"sender\":" << (unsigned)my_idx_ << ","
       << "\"receiver\":" << (unsigned)receiver << ","
       << "\"payload_hex\":\"" << payload_hex << "\"}";
  long code = 0; std::string resp;
  bool ok = HttpClient::post_json(enqueue_url_peer(), body.str(), &code, &resp, /*timeout*/15000);
  if (!ok || code != 200) return coinbase::ERR_NETWORK;
  return coinbase::SUCCESS;
}

error_t HttpTransport::receive(party_idx_t sender, mem_t& msg) {
  const auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(receive_timeout_ms_);
  while (true) {
    long code = 0; std::string resp;
    std::string url = dequeue_url_self(sender);
    bool ok = HttpClient::get(url, &code, &resp, /*timeout*/ 10000);
    if (ok && code == 200) {
      // resp is just hex of payload for simplicity
      try {
        rx_storage_ = from_hex(resp);
      } catch (...) {
        return coinbase::ERR_BAD_MESSAGE;
      }
      msg = mem_t(rx_storage_.data(), rx_storage_.size());
      return coinbase::SUCCESS;
    }
    if (!ok) {
      // brief backoff
      std::this_thread::sleep_for(std::chrono::milliseconds(poll_interval_ms_));
    } else if (code == 204) {
      // no content - keep polling until deadline
      if (std::chrono::steady_clock::now() >= deadline)
        return coinbase::ERR_TIMEOUT;
      std::this_thread::sleep_for(std::chrono::milliseconds(poll_interval_ms_));
    } else if (code >= 400) {
      return coinbase::ERR_NETWORK;
    } else {
      // unexpected; small sleep to avoid busy loop
      std::this_thread::sleep_for(std::chrono::milliseconds(poll_interval_ms_));
    }
  }
}

error_t HttpTransport::receive_all(const std::vector<party_idx_t>& senders,
                                   std::vector<mem_t>& messages) {
  messages.resize(senders.size());
  for (size_t i = 0; i < senders.size(); ++i) {
    error_t rv = receive(senders[i], messages[i]);
    if (rv != coinbase::SUCCESS) return rv;
  }
  return coinbase::SUCCESS;
}

} // namespace mpcnet
