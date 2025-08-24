# server.py
import os
import time
import queue
from flask import Flask, request, jsonify, Response

app = Flask(__name__)

# Inbound queues keyed by (sid, sender) -> Queue[str hex payload]
# This queue is the "local inbound queue" for the party on THIS server.
INBOUND = {}

def _q(sid: str, sender: int) -> queue.Queue:
    key = (sid, int(sender))
    if key not in INBOUND:
        INBOUND[key] = queue.Queue()
    return INBOUND[key]

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"ok": True}), 200

@app.route("/mpc/enqueue", methods=["POST"])
def mpc_enqueue():
    """
    Peer calls this to deliver a message to us.
    Body: {sid, sender, receiver, payload_hex}
    We do not check `receiver` (informational); we just enqueue for (sid, sender).
    """
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "bad json"}), 400
    sid = data.get("sid")
    sender = data.get("sender")
    payload_hex = data.get("payload_hex")
    if sid is None or sender is None or payload_hex is None:
        return jsonify({"error": "missing fields"}), 400

    q = _q(sid, int(sender))
    q.put(payload_hex)
    return jsonify({"ok": True}), 200

@app.route("/mpc/dequeue", methods=["GET"])
def mpc_dequeue():
    """
    Local C++ transport calls this to pop the next message sent by `sender`.
    Query: ?sid=...&sender=...
    Returns:
      200 + raw hex body if message available,
      204 if queue empty (transport will poll again).
    """
    sid = request.args.get("sid", type=str)
    sender = request.args.get("sender", type=int)
    if sid is None or sender is None:
        return jsonify({"error": "missing sid/sender"}), 400

    q = _q(sid, int(sender))
    try:
        payload_hex = q.get_nowait()
    except queue.Empty:
        return Response(status=204)

    # Return *raw* hex in body to keep the C++ receive() trivial
    return Response(payload_hex, mimetype="text/plain", status=200)

if __name__ == "__main__":
    # Config via env for convenience
    port = int(os.environ.get("PORT", "5001"))
    app.run(host="0.0.0.0", port=port)
