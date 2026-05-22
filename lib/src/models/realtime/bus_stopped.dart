/// Event received from the location WebSocket when a bus stops at a station.
class BusStopped {
  DateTime timestamp;
  double lat;
  double long;
  double speed;
  int delay;
  int passangers;
  String stopName;
  DateTime scheduledTime;
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
