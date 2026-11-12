/// A bus leaving a station.
class Departure {
  /// Scheduled time the bus passes the station. Has a real date.
  DateTime scheduledArrival;

  /// Scheduled time the trip leaves its origin. Time only; the date is fake.
  DateTime tripDepartureTime;

  /// Scheduled time the trip reaches its destination. Time only; the date is
  /// fake.
  DateTime? tripArrivalTime;

  /// Name of the trip's subline, e.g. `Palma - Magaluf`.
  String name;

  int tripId;

  /// Live tracking of the bus. `null` when it isn't tracked.
  RealTrip? realTrip;

  /// Whether the bus only stops here on request.
  bool onDemand;

  String lineCode;

  /// Town the trip starts in.
  String? origin;

  /// Town the trip ends in.
  String? destination;

  /// The line's colour as sent, e.g. `#28689D`. See [lineColorValue].
  String? lineColor;

  Departure(
      {required this.scheduledArrival,
      required this.tripDepartureTime,
      this.tripArrivalTime,
      required this.name,
      required this.tripId,
      this.realTrip,
      required this.onDemand,
      required this.lineCode,
      this.origin,
      this.destination,
      this.lineColor});

  /// [lineColor] as an ARGB int. `null` if absent or not `#RRGGBB`.
  int? get lineColorValue {
    final raw = lineColor;
    if (raw == null || !raw.startsWith('#')) return null;
    return int.tryParse(raw.replaceFirst('#', '0xFF'));
  }

  @override
  String toString() {
    return 'Departure{scheduledArrival: $scheduledArrival, tripDepartureTime: $tripDepartureTime, tripArrivalTime: $tripArrivalTime, name: $name, tripId: $tripId, realTrip: $realTrip, onDemand: $onDemand, lineCode: $lineCode, origin: $origin, destination: $destination, lineColor: $lineColor}';
  }

  factory Departure.fromJson(Map json) {
    return Departure(
        scheduledArrival: DateTime.parse(json['aet']),
        tripDepartureTime: DateTime.parse(json['dt']),
        tripArrivalTime:
            json['et'] != null ? DateTime.tryParse(json['et']) : null,
        name: json['snam'],
        tripId: json['trip_id'],
        realTrip: json['realTrip'] != null
            ? RealTrip.fromJson(json['realTrip'])
            : null,
        onDemand: json['dem'],
        lineCode: json['lcod'],
        origin: json['dtn'],
        destination: json['etn'],
        lineColor: json['lineColor']);
  }

  Map<String, dynamic> toJson() {
    return {
      'aet': scheduledArrival.toIso8601String(),
      'dt': tripDepartureTime.toIso8601String(),
      'et': tripArrivalTime?.toIso8601String(),
      'snam': name,
      'trip_id': tripId,
      'realTrip': realTrip?.toJson(),
      'dem': onDemand,
      'lcod': lineCode,
      'dtn': origin,
      'etn': destination,
      'lineColor': lineColor
    };
  }
}

/// Live tracking of a departure's bus.
class RealTrip {
  /// Id to track the bus with, see [TibRealtime.track].
  int id;

  /// Live estimate of when the bus passes the station.
  DateTime? estimatedArrival;

  /// Last known position of the bus.
  double lat;
  double long;

  RealTrip(
      {required this.id,
      this.estimatedArrival,
      required this.lat,
      required this.long});

  @override
  String toString() {
    return 'RealTrip{id: $id, estimatedArrival: $estimatedArrival, lat: $lat, long: $long}';
  }

  factory RealTrip.fromJson(Map json) {
    return RealTrip(
        // Sent as a string.
        id: json['id'] is int ? json['id'] : int.parse(json['id']),
        estimatedArrival:
            json['aet'] != null ? DateTime.tryParse(json['aet']) : null,
        lat: (json['lastCoords']['lat'] as num).toDouble(),
        long: (json['lastCoords']['lng'] as num).toDouble());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': '$id',
      'aet': estimatedArrival?.toIso8601String(),
      'lastCoords': {'lat': lat, 'lng': long}
    };
  }
}
