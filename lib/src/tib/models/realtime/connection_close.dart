/// Sent when a tracked bus reaches its destination.
class ConnectionClose {
  @override
  String toString() =>
      "Connection has been closed. Bus arrived at the final destination.";
}
