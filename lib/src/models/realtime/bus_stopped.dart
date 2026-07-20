import 'package:mallorca_transit_services/src/models/realtime/timestamps.dart';

/// Event received from the location WebSocket when a bus stops at a station.
class BusStopped {
  /// When the server published the event, roughly a second after [recordedAt].
  DateTime timestamp;

  double lat;
  double long;
  double speed;
  int? delay;
  int passangers;
  String stopName;

  /// Internal id of the stop, matching [Station.id].
  int? stopId;

  /// Public code of the stop, matching [Station.code].
  String? stopCode;

  /// Id of the trip this event belongs to, matching the id passed to
  /// [LocationWebSocket.locationChannel].
  int? tripId;

  /// When the vehicle recorded the event.
  DateTime? recordedAt;

  /// Scheduled arrival. Time only, so the date part is the Unix epoch.
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
      this.leaveTime,
      this.stopId,
      this.stopCode,
      this.tripId,
      this.recordedAt});

  @override
  String toString() {
    return 'BusStopped{timestamp: $timestamp, lat: $lat, long: $long, speed: $speed, delay: $delay, passangers: $passangers, stopName: $stopName, stopId: $stopId, stopCode: $stopCode, tripId: $tripId, recordedAt: $recordedAt, scheduledTime: $scheduledTime, actualTime: $actualTime, stopTime: $stopTime, leaveTime: $leaveTime}';
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
        stopId: json['stop_id'] as int?,
        stopCode: json['stop_code'] as String?,
        tripId: json['rt_id'] as int?,
        recordedAt: parseSocketTimestamp(json['date']),
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
