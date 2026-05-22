/// Real-time route snapshot received from the location WebSocket.
/// Contains current passenger counts and the ordered list of stops.
class RouteStationInfo {
  final Passangers passangers;
  final List<StationOnRoute> stops;

  RouteStationInfo({required this.passangers, required this.stops});

  @override
  String toString() {
    return 'StationInfo{passangers: $passangers, stops: $stops}';
  }

  factory RouteStationInfo.fromJson(Map json) {
    return RouteStationInfo(
        passangers: Passangers.fromJson(json['bus']),
        stops: (json['stops'] as List)
            .map((e) => StationOnRoute.fromJson(e))
            .toList());
  }
}

class StationOnRoute {
  int stopId;
  String stopName;
  DateTime scheduledArrival;
  double? estimatedDistance;
  DateTime? estimatedArrival;

  StationOnRoute(
      {required this.stopId,
      required this.stopName,
      required this.scheduledArrival,
      this.estimatedDistance,
      this.estimatedArrival});

  @override
  String toString() {
    return 'BusStop{stopId: $stopId, stopName: $stopName, scheduledArrival: $scheduledArrival, estimatedDistance: $estimatedDistance, estimatedArrival: $estimatedArrival}';
  }

  factory StationOnRoute.fromJson(Map json) {
    return StationOnRoute(
        stopId: json['stop_id'],
        stopName: json['stop_nam'],
        scheduledArrival: DateTime(
            1970,
            1,
            1,
            int.parse(json["arr_t"].substring(0, 2)),
            int.parse(json["arr_t"].substring(2, 4))),
        estimatedDistance: json['esta_dist'],
        estimatedArrival: json['esta_time'] == null
            ? null
            : DateTime.tryParse(json['esta_time']));
  }
}

class Passangers {
  /// May exceed [totalCapacity] when the bus is overcrowded.
  final int inBus;
  final int totalCapacity;

  Passangers({required this.inBus, required this.totalCapacity});

  @override
  String toString() {
    return '_Passangers{inBus: $inBus, totalCapacity: $totalCapacity}';
  }

  factory Passangers.fromJson(Map json) {
    return Passangers(inBus: json['pas'], totalCapacity: json['cap']);
  }
}
