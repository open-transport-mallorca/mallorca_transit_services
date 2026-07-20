import 'package:mallorca_transit_services/src/models/realtime/bus_position.dart';
import 'package:mallorca_transit_services/src/models/realtime/timestamps.dart';

/// Real-time route snapshot received from the location WebSocket.
/// Contains current passenger counts and the ordered list of stops.
class RouteStationInfo {
  final Passangers passangers;
  final List<StationOnRoute> stops;

  /// Id of the trip this snapshot belongs to, matching the id passed to
  /// [LocationWebSocket.locationChannel].
  final int? tripId;

  /// The bus' position at the time of the snapshot. Every `esta-info` message
  /// carries one, so these give a denser position stream than the `position`
  /// messages alone. [BusPosition.recordedAt] is always `null` here.
  final BusPosition? position;

  RouteStationInfo(
      {required this.passangers,
      required this.stops,
      this.tripId,
      this.position});

  @override
  String toString() {
    return 'StationInfo{passangers: $passangers, stops: $stops, tripId: $tripId, position: $position}';
  }

  factory RouteStationInfo.fromJson(Map json) {
    final tripId = json['rt_id'] as int?;
    return RouteStationInfo(
        passangers: Passangers.fromJson(json['bus']),
        stops: (json['stops'] as List)
            .map((e) => StationOnRoute.fromJson(e))
            .toList(),
        tripId: tripId,
        position: json['pos'] != null
            ? BusPosition.fromJson(json['pos'],
                timestampKey: 'time', tripId: tripId)
            : null);
  }
}

class StationOnRoute {
  /// Internal id of the stop, matching [Station.id].
  int stopId;

  /// Public code of the stop, matching [Station.code].
  String? stopCode;

  String stopName;

  /// Scheduled arrival. Time only, so the date part is the Unix epoch.
  DateTime scheduledArrival;

  /// Remaining distance to the stop. Unverified: it did not appear in any
  /// captured payload, so expect `null`.
  double? estimatedDistance;

  DateTime? estimatedArrival;

  StationOnRoute(
      {required this.stopId,
      required this.stopName,
      required this.scheduledArrival,
      this.estimatedDistance,
      this.estimatedArrival,
      this.stopCode});

  @override
  String toString() {
    return 'BusStop{stopId: $stopId, stopCode: $stopCode, stopName: $stopName, scheduledArrival: $scheduledArrival, estimatedDistance: $estimatedDistance, estimatedArrival: $estimatedArrival}';
  }

  factory StationOnRoute.fromJson(Map json) {
    return StationOnRoute(
        stopId: json['stop_id'],
        stopCode: json['stop_code'] as String?,
        stopName: json['stop_nam'],
        scheduledArrival: DateTime(
            1970,
            1,
            1,
            int.parse(json["arr_t"].substring(0, 2)),
            int.parse(json["arr_t"].substring(2, 4))),
        estimatedDistance: (json['esta_dist'] as num?)?.toDouble(),
        estimatedArrival: parseSocketTimestamp(json['esta_time']));
  }
}

class Passangers {
  /// May exceed [totalCapacity] when the bus is overcrowded.
  final int inBus;

  /// Total capacity as reported by the API. Ambiguous: samples report `50`
  /// alongside a seated capacity of `50` and a standing one of `44`, so it is
  /// not their sum. What it counts is unknown, so don't rely on it as a total.
  final int totalCapacity;

  final int? seatedCapacity;
  final int? standingCapacity;

  Passangers(
      {required this.inBus,
      required this.totalCapacity,
      this.seatedCapacity,
      this.standingCapacity});

  @override
  String toString() {
    return '_Passangers{inBus: $inBus, totalCapacity: $totalCapacity, seatedCapacity: $seatedCapacity, standingCapacity: $standingCapacity}';
  }

  factory Passangers.fromJson(Map json) {
    return Passangers(
        inBus: json['pas'],
        totalCapacity: json['cap'],
        seatedCapacity: json['cap_seated'],
        standingCapacity: json['cap_standing']);
  }
}
