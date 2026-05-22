/// Sent by the WebSocket when the bus reaches its final destination.
class ConnectionClose {
  @override
  String toString() =>
      "Connection has been closed. Bus arrived at the final destination.";
}
