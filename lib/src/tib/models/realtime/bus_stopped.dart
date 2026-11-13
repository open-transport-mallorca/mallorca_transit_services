import 'package:mallorca_transit_services/src/tib/models/realtime/timestamps.dart';

/// Sent when a tracked bus stops at a station.
class BusStopped {
  /// When the server sent the event.
  DateTime timestamp;

  double lat;
  double long;
  double speed;

  /// Minutes behind schedule.
  int? delay;

  /// Passengers on board. `0` since October 2026, as TIB stopped counting.
  int passengers;

  String stopName;

  /// See [Station.id].
  int? stopId;

  /// See [Station.code].
  String? stopCode;

  /// Id of the tracked trip, see [RealTrip.id].
  int? tripId;

  /// When the vehicle recorded the event.
  DateTime? recordedAt;

  /// Scheduled arrival. Time only; the date is fake.
  DateTime scheduledTime;

  /// When the bus arrived.
  DateTime? actualTime;

  /// When the bus stopped.
  DateTime? stopTime;

  /// When the bus left.
  DateTime? leaveTime;

  BusStopped(
      {required this.timestamp,
      required this.lat,
      required this.long,
      required this.speed,
      this.delay,
      required this.passengers,
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
    return 'BusStopped{timestamp: $timestamp, lat: $lat, long: $long, speed: $speed, delay: $delay, passengers: $passengers, stopName: $stopName, stopId: $stopId, stopCode: $stopCode, tripId: $tripId, recordedAt: $recordedAt, scheduledTime: $scheduledTime, actualTime: $actualTime, stopTime: $stopTime, leaveTime: $leaveTime}';
  }

  factory BusStopped.fromJson(Map json) {
    return BusStopped(
        timestamp: DateTime.parse(json['upd']),
        lat: (json['lat'] as num).toDouble(),
        long: (json['lng'] as num).toDouble(),
        speed: (json['vel'] as num).toDouble(),
        delay: json['del'] as int?,
        passengers: json['pass'] as int,
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
