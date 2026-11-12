import 'package:mallorca_transit_services/src/tib/models/realtime/bus_position.dart';
import 'package:mallorca_transit_services/src/tib/models/realtime/timestamps.dart';

/// The stops a tracked bus has left, with live arrival estimates.
class RouteStationInfo {
  /// `null` when TIB sends no count, which it has done since October 2026.
  final Passengers? passengers;

  /// The stops left, in driving order.
  final List<StationOnRoute> stops;

  /// Id of the tracked trip, see [RealTrip.id].
  final int? tripId;

  /// The bus' position when the event was sent.
  final BusPosition? position;

  RouteStationInfo(
      {this.passengers, required this.stops, this.tripId, this.position});

  @override
  String toString() {
    return 'RouteStationInfo{passengers: $passengers, stops: $stops, tripId: $tripId, position: $position}';
  }

  factory RouteStationInfo.fromJson(Map json) {
    final tripId = json['rt_id'] as int?;
    return RouteStationInfo(
        passengers: Passengers._fromJson(json['bus']),
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

/// A stop ahead of a tracked bus.
class StationOnRoute {
  /// See [Station.id].
  int stopId;

  /// See [Station.code].
  String? stopCode;

  String stopName;

  /// Scheduled arrival. Time only; the date is fake.
  DateTime scheduledArrival;

  /// Live arrival estimate.
  DateTime? estimatedArrival;

  /// Remaining distance to the stop.
  double? estimatedDistance;

  StationOnRoute(
      {required this.stopId,
      this.stopCode,
      required this.stopName,
      required this.scheduledArrival,
      this.estimatedArrival,
      this.estimatedDistance});

  @override
  String toString() {
    return 'StationOnRoute{stopId: $stopId, stopCode: $stopCode, stopName: $stopName, scheduledArrival: $scheduledArrival, estimatedArrival: $estimatedArrival, estimatedDistance: $estimatedDistance}';
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
        estimatedArrival: parseSocketTimestamp(json['esta_time']),
        estimatedDistance: (json['esta_dist'] as num?)?.toDouble());
  }
}

/// Passengers on a bus and its capacity.
class Passengers {
  /// May exceed [totalCapacity] when the bus is crowded.
  final int inBus;

  /// Not the sum of [seatedCapacity] and [standingCapacity]; its meaning is
  /// unclear.
  final int totalCapacity;

  final int? seatedCapacity;
  final int? standingCapacity;

  Passengers(
      {required this.inBus,
      required this.totalCapacity,
      this.seatedCapacity,
      this.standingCapacity});

  @override
  String toString() {
    return 'Passengers{inBus: $inBus, totalCapacity: $totalCapacity, seatedCapacity: $seatedCapacity, standingCapacity: $standingCapacity}';
  }

  /// `null` when the capacity is `0`, which TIB sends instead of no data.
  static Passengers? _fromJson(Map? json) {
    if (json == null || json['cap'] == 0) return null;
    return Passengers.fromJson(json);
  }

  factory Passengers.fromJson(Map json) {
    return Passengers(
        inBus: json['pas'],
        totalCapacity: json['cap'],
        seatedCapacity: json['cap_seated'],
        standingCapacity: json['cap_standing']);
  }
}
