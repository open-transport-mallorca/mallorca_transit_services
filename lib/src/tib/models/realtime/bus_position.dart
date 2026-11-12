import 'package:mallorca_transit_services/src/tib/models/realtime/timestamps.dart';

/// Position of a tracked bus.
///
/// Also embedded in every [RouteStationInfo], so those give a denser stream.
class BusPosition {
  final double lat;
  final double long;

  /// Speed in km/h.
  final double? speed;

  /// When the server sent the position.
  final DateTime timestamp;

  /// Id of the tracked trip, see [RealTrip.id].
  final int? tripId;

  /// When the bus recorded the position. `null` in a [RouteStationInfo].
  final DateTime? recordedAt;

  BusPosition(
      {required this.lat,
      required this.long,
      this.speed,
      required this.timestamp,
      this.tripId,
      this.recordedAt});

  @override
  String toString() {
    return 'BusPosition{lat: $lat, long: $long, speed: $speed, timestamp: $timestamp, tripId: $tripId, recordedAt: $recordedAt}';
  }

  /// Parses a `position` event, or a [RouteStationInfo]'s `pos` with
  /// [timestampKey] `time` and its [tripId].
  factory BusPosition.fromJson(Map json,
      {String timestampKey = 'upd', int? tripId}) {
    return BusPosition(
        lat: (json['lat'] as num).toDouble(),
        long: (json['lng'] as num).toDouble(),
        speed: (json['vel'] as num?)?.toDouble(),
        timestamp: DateTime.parse(json[timestampKey]),
        tripId: tripId ?? json['rt_id'],
        recordedAt: parseSocketTimestamp(json['date']));
  }
}
