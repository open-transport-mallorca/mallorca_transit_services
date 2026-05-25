/// Event received from the location WebSocket when a bus stops at a station.
class BusStopped {
  DateTime timestamp;
  double lat;
  double long;
  double speed;
  int? delay;
  int passangers;
  String stopName;
  DateTime scheduledTime;
  DateTime? actualTime;
  DateTime? stopTime;
  DateTime? leaveTime;

  BusStopped(
      {required this.timestamp,
      required this.lat,
      required this.long,
      required this.speed,
      this.delay,
      required this.passangers,
      required this.stopName,
      required this.scheduledTime,
      this.actualTime,
      this.stopTime,
      this.leaveTime});

  @override
  String toString() {
    return 'BusStopped{timestamp: $timestamp, lat: $lat, long: $long, speed: $speed, delay: $delay, passangers: $passangers, stopName: $stopName, scheduledTime: $scheduledTime, actualTime: $actualTime, stopTime: $stopTime, leaveTime: $leaveTime}';
  }

  factory BusStopped.fromJson(Map json) {
    return BusStopped(
        timestamp: DateTime.parse(json['upd']),
        lat: (json['lat'] as num).toDouble(),
        long: (json['lng'] as num).toDouble(),
        speed: (json['vel'] as num).toDouble(),
        delay: json['del'] as int?,
        passangers: json['pass'] as int,
        stopName: json['stop_nam'] as String,
        scheduledTime: DateTime(
            1970,
            1,
            1,
            int.parse(json["arr_t"].substring(0, 2)),
            int.parse(json["arr_t"].substring(2, 4))),
        actualTime:
            json['arr_rt'] != null ? DateTime.tryParse(json['arr_rt']) : null,
        stopTime:
            json['stp_rt'] != null ? DateTime.tryParse(json['stp_rt']) : null,
        leaveTime:
            json['dep_rt'] != null ? DateTime.tryParse(json['dep_rt']) : null);
  }
}
