/// Represents the position of a bus.
/// It is received by the location socket and is used to track the bus.
///
/// The position includes the latitude, longitude, speed, and the timestamp of
/// the position.
class BusPosition {
  /// The latitude of the bus.
  final double lat;

  /// The longitude of the bus.
  final double long;

  /// The speed of the bus.
  final double speed;

  /// The timestamp of the position.
  final DateTime timestamp;

  BusPosition(
      {required this.lat,
      required this.long,
      required this.speed,
      required this.timestamp});

  @override
  String toString() {
    return 'BusPosition{lat: $lat, long: $long, speed: $speed, timestamp: $timestamp}';
  }

  /// Converts a JSON map to a [BusPosition] object.
  factory BusPosition.fromJson(Map json) {
    return BusPosition(
        lat: json['lat'],
        long: json['lng'],
        speed: json['vel'],
        timestamp: DateTime.parse(json['upd']));
  }
}
