/// Represents the bus stop at a station.
///
/// It is received by the location socket and is used to track the bus.
///
/// The stop includes the latitude, longitude, speed, delay, number of passengers,
/// the name of the stop, the scheduled time, the actual time, the time the bus
/// stopped, and the time the bus left the stop.
class BusStopped {
  /// The timestamp of the stop.
  DateTime timestamp;

  /// The latitude of the stop.
  double lat;

  /// The longitude of the stop.
  double long;

  /// The speed of the bus.
  double speed;

  /// The delay of the bus.
  int delay;

  /// The number of passengers on the bus.
  int passangers;

  /// The name of the stop.
  String stopName;

  /// The scheduled time of the stop.
  DateTime scheduledTime;

  /// The actual time of the stop.
  DateTime actualTime;
  DateTime? stopTime;
  DateTime? leaveTime;

  BusStopped(
      {required this.timestamp,
      required this.lat,
      required this.long,
      required this.speed,
      required this.delay,
      required this.passangers,
      required this.stopName,
      required this.scheduledTime,
      required this.actualTime,
      this.stopTime,
      this.leaveTime});

  @override
  String toString() {
    return 'BusStopped{timestamp: $timestamp, lat: $lat, long: $long, speed: $speed, delay: $delay, passangers: $passangers, stopName: $stopName, scheduledTime: $scheduledTime, actualTime: $actualTime, stopTime: $stopTime, leaveTime: $leaveTime}';
  }

  /// Converts a JSON map to a [BusStopped] object.
  /// The [json] parameter is a map representing the JSON data.
  /// Returns a [BusStopped] object with the converted data.
  /// The JSON data is received from the location socket.
  /// The JSON data includes the latitude, longitude, speed, delay, number of passengers,
  /// the name of the stop, the scheduled time, the actual time, the time the bus
  /// stopped, and the time the bus left the stop.
  factory BusStopped.fromJson(Map json) {
    return BusStopped(
        timestamp: DateTime.parse(json['upd']),
        lat: json['lat'],
        long: json['lng'],
        speed: json['vel'],
        delay: json['del'],
        passangers: json['pass'],
        stopName: json['stop_nam'],
        scheduledTime: DateTime(
            1970,
            1,
            1,
            int.parse(json["arr_t"].substring(0, 2)),
            int.parse(json["arr_t"].substring(2, 4))),
        actualTime: DateTime.parse(json['arr_rt']),
        stopTime:
            json['stp_rt'] != null ? DateTime.tryParse(json['stp_rt']) : null,
        leaveTime:
            json['dep_rt'] != null ? DateTime.tryParse(json['dep_rt']) : null);
  }
}
