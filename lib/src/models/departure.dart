import 'dart:convert';

class Departure {
  DateTime departureTime;
  DateTime estimatedArrival;
  String name;
  int tripId;
  RealTrip? realTrip;
  bool delayed;
  String lineCode;
  String? destination;
  String? departureStop;

  Departure(
      {required this.departureTime,
      required this.estimatedArrival,
      required this.name,
      required this.tripId,
      this.realTrip,
      required this.delayed,
      required this.lineCode,
      this.destination,
      this.departureStop});

  @override
  String toString() {
    return 'Departure{departureTime: $departureTime, estimatedArrival: $estimatedArrival, name: $name, tripId: $tripId, realTrip: $realTrip, delayed: $delayed, lineCode: $lineCode, destination: $destination, departureStop: $departureStop}';
  }

  factory Departure.fromJson(Map json) {
    return Departure(
        departureTime: DateTime.parse(json['dt']),
        estimatedArrival: DateTime.parse(json['aet']),
        name: json['snam'],
        tripId: json['trip_id'],
        realTrip: json['realTrip'] != null
            ? RealTrip.fromJson(json['realTrip'])
            : null,
        delayed: json['dem'],
        lineCode: json['lcod'],
        destination: json['etn'],
        departureStop: json['et']);
  }

  static Map toJson(Departure departure) {
    return {
      'dt': departure.departureTime.toIso8601String(),
      'aet': departure.estimatedArrival.toIso8601String(),
      'snam': departure.name,
      'trip_id': departure.tripId,
      'realTrip': departure.realTrip != null
          ? RealTrip.toJson(departure.realTrip!)
          : null,
      'dem': departure.delayed,
      'lcod': departure.lineCode,
      'etn': departure.destination,
      'et': departure.departureStop
    };
  }
}

class RealTripBusStats {
  /// Total number of places to sit in the bus (counting occupied and free)
  int placesToSit;

  /// Total number of places to stand in the bus (counting occupied and free)
  int placesToStand;

  /// Total number of passengers currently in the bus
  int passengers;

  RealTripBusStats(
      {required this.placesToSit,
      required this.placesToStand,
      required this.passengers});

  @override
  String toString() {
    return 'RealTripBusStats{placesToSit: $placesToSit, placesToStand: $placesToStand, passengers: $passengers}';
  }

  factory RealTripBusStats.fromJson(Map json) {
    return RealTripBusStats(
        placesToSit: json['placesSeated'],
        placesToStand: json['placesStanding'],
        passengers: json['passengers']);
  }

  static Map toJson(RealTripBusStats realTripBusStats) {
    return {
      'placesSeated': realTripBusStats.placesToSit,
      'placesStanding': realTripBusStats.placesToStand,
      'passengers': realTripBusStats.passengers
    };
  }
}

class RealTrip {
  DateTime? estimatedArrival;
  double lat;
  double long;
  int id;
  RealTripBusStats? stats;

  RealTrip(
      {this.estimatedArrival,
      required this.lat,
      required this.long,
      required this.id,
      this.stats});

  @override
  toString() {
    return 'RealTrip{estimatedArrival: $estimatedArrival, lat: $lat, long: $long, stats: $stats, id: $id}';
  }

  factory RealTrip.fromJson(Map json) {
    return RealTrip(
        estimatedArrival:
            json['aet'] != null ? DateTime.tryParse(json['aet']) : null,
        lat: json['lastCoords']['lat'],
        long: json['lastCoords']['lng'],
        id: int.parse(json['id']),
        stats: json['bus'] != null
            ? RealTripBusStats.fromJson(json['bus'])
            : null);
  }

  static String toJson(RealTrip realTrip) {
    return jsonEncode({
      'estimatedArrival': realTrip.estimatedArrival?.toIso8601String(),
      'aet': realTrip.estimatedArrival?.toIso8601String(),
      'lastCoords': {'lat': realTrip.lat, 'lng': realTrip.long},
      'id': realTrip.id,
      'bus': realTrip.stats != null
          ? RealTripBusStats.toJson(realTrip.stats!)
          : null
    });
  }
}
