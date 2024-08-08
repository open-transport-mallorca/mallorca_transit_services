/// ConnectionClose is a class that represents the event of a connection being closed.
/// Usually this event is sent when the bus has arrived at the final destination.
class ConnectionClose {
  /// Returns a string representation of the object.
  @override
  String toString() =>
      "Connection has been closed. Bus arrived at the final destination.";
}
