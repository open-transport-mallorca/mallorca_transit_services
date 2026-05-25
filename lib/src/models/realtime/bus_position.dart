/// Real-time bus position received from the location WebSocket.
class BusPosition {
  final double lat;
  final double long;
  final double? speed;
  final DateTime timestamp;

  BusPosition(
      {required this.lat,
      required this.long,
      this.speed,
      required this.timestamp});

  @override
  String toString() {
    return 'BusPosition{lat: $lat, long: $long, speed: $speed, timestamp: $timestamp}';
  }

  factory BusPosition.fromJson(Map json) {
    return BusPosition(
        lat: json['lat'],
        long: json['lng'],
        speed: json['vel'],
        timestamp: DateTime.parse(json['upd']));
  }
}
