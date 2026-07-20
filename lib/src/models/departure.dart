import 'dart:convert';

class Departure {
  /// Scheduled departure from the queried stop. Time only, so the date part is
  /// the Unix epoch and is not a real date.
  DateTime departureTime;

  /// Real-time estimated arrival at the queried stop. Carries a real date.
  DateTime estimatedArrival;

  String name;
  int tripId;
  RealTrip? realTrip;
  bool delayed;
  String lineCode;

  /// Name of the trip's terminus.
  String? destination;

  /// The line's colour as sent by the API, e.g. `"#28689D"`. Kept raw so it
  /// round-trips untouched; see [lineColorValue] for an ARGB int.
  String? lineColor;

  /// Name of the trip's origin stop. Unverified: it was `null` in every
  /// captured payload, so the type is assumed by symmetry with [destination].
  String? originStop;

  /// Arrival at the trip's terminus. Time only, like [departureTime].
  DateTime? endTime;

  @Deprecated(
      'Misparsed: holds `et`, an arrival time, not a stop name. Use endTime.')
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
      this.lineColor,
      this.originStop,
      this.endTime,
      @Deprecated(
          'Misparsed: holds `et`, an arrival time, not a stop name. Use endTime.')
      this.departureStop});

  /// [lineColor] as an ARGB int, or `null` if absent or not `#RRGGBB`.
  int? get lineColorValue {
    final raw = lineColor;
    if (raw == null || !raw.startsWith('#')) return null;
    return int.tryParse(raw.replaceFirst('#', '0xFF'));
  }

  @override
  String toString() {
    return 'Departure{departureTime: $departureTime, estimatedArrival: $estimatedArrival, name: $name, tripId: $tripId, realTrip: $realTrip, delayed: $delayed, lineCode: $lineCode, destination: $destination, lineColor: $lineColor, originStop: $originStop, endTime: $endTime, departureStop: $_departureStop}';
  }

  // Internal read, so toString/toJson don't trip the deprecation warning.
  // ignore: deprecated_member_use_from_same_package
  String? get _departureStop => departureStop;

  factory Departure.fromJson(Map json) {
    return Departure(
        departureTime: DateTime.parse(json['dt']),
        estimatedArrival: DateTime.parse(json['aet']),
        name: json['snam'],
        tripId: json['trip_id'],
        realTrip: _realTripFromJson(json['realTrip']),
        delayed: json['dem'],
        lineCode: json['lcod'],
        destination: json['etn'],
        lineColor: json['lineColor'],
        originStop: json['dtn'],
        endTime: json['et'] != null ? DateTime.tryParse(json['et']) : null,
        // ignore: deprecated_member_use_from_same_package
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
      'lineColor': departure.lineColor,
      'dtn': departure.originStop,
      // `et` backs both endTime and the deprecated departureStop. Prefer the
      // parsed value; fall back for objects built with only the old field.
      'et': departure.endTime?.toIso8601String() ?? departure._departureStop
    };
  }

  /// [RealTrip.toJson] returns an encoded string, not a map, so a round-trip
  /// hands this key back as a string. Accept both shapes.
  static RealTrip? _realTripFromJson(Object? value) {
    if (value == null) return null;
    if (value is String) return RealTrip.fromJson(jsonDecode(value));
    return RealTrip.fromJson(value as Map);
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
        lat: (json['lastCoords']['lat'] as num).toDouble(),
        long: (json['lastCoords']['lng'] as num).toDouble(),
        // The API sends a string; a round-trip through toJson sends an int.
        id: json['id'] is int ? json['id'] : int.parse(json['id']),
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
