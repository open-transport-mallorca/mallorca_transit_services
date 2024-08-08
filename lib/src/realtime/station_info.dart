/// Received data from the server about the bus route
/// and the stations on the route.
///
/// The data includes the number of passengers in the bus,
/// the total capacity of the bus, and the stops on the route.
class RouteStationInfo {
  final Passangers passangers;
  final List<StationOnRoute> stops;

  RouteStationInfo({required this.passangers, required this.stops});

  @override
  String toString() {
    return 'StationInfo{passangers: $passangers, stops: $stops}';
  }

  /// Converts a JSON map to a [RouteStationInfo] object.
  /// The [json] parameter is a map representing the JSON data.
  factory RouteStationInfo.fromJson(Map json) {
    return RouteStationInfo(
        passangers: Passangers.fromJson(json['bus']),
        stops: (json['stops'] as List)
            .map((e) => StationOnRoute.fromJson(e))
            .toList());
  }
}

/// Represents a station on the route.
///
/// It includes the stop ID, the name of the stop, the scheduled arrival time,
/// the estimated distance from the bus, and the estimated arrival time.
class StationOnRoute {
  int stopId;
  String stopName;
  DateTime scheduledArrival;
  double estimatedDistance;
  DateTime estimatedArrival;

  StationOnRoute(
      {required this.stopId,
      required this.stopName,
      required this.scheduledArrival,
      required this.estimatedDistance,
      required this.estimatedArrival});

  @override
  String toString() {
    return 'BusStop{stopId: $stopId, stopName: $stopName, scheduledArrival: $scheduledArrival, estimatedDistance: $estimatedDistance, estimatedArrival: $estimatedArrival}';
  }

  /// Converts a JSON map to a [StationOnRoute] object.
  /// The [json] parameter is a map representing the JSON data.
  /// Returns a [StationOnRoute] object with the converted data.
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
        estimatedArrival: DateTime.parse(json['esta_time']));
  }
}

/// Represents the number of passengers in the bus and the total capacity of the bus.
///
/// It is received by the location socket and is used to track the bus.
class Passangers {
  /// The number of passengers in the bus.
  ///
  /// This number might be greater than the total capacity of the bus
  /// if the bus is overcrowded and no seats are available.
  final int inBus;

  /// The total capacity of the bus.
  final int totalCapacity;

  Passangers({required this.inBus, required this.totalCapacity});

  @override
  String toString() {
    return '_Passangers{inBus: $inBus, totalCapacity: $totalCapacity}';
  }

  /// Converts a JSON map to a [Passangers] object.
  /// The [json] parameter is a map representing the JSON data.
  factory Passangers.fromJson(Map json) {
    return Passangers(inBus: json['pas'], totalCapacity: json['cap']);
  }
}
