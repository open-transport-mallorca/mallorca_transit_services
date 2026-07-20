import 'package:mallorca_transit_services/src/models/realtime/timestamps.dart';

/// Real-time bus position received from the location WebSocket.
///
/// Sent as a `position` message, and also embedded in every `esta-info` one -
/// see [RouteStationInfo.position] for a denser stream.
class BusPosition {
  final double lat;
  final double long;
  final double? speed;

  /// When the server published the fix, roughly a second after [recordedAt].
  final DateTime timestamp;

  /// Id of the trip this position belongs to, matching the id passed to
  /// [LocationWebSocket.locationChannel].
  final int? tripId;

  /// When the vehicle recorded the position. `null` on positions embedded in
  /// an `esta-info` message.
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

  /// Parses a `position` message, or an `esta-info` `pos` object when
  /// [timestampKey] is `'time'`. Pass [tripId] for a `pos` object, which does
  /// not carry one itself.
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
