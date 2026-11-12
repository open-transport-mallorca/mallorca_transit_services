/// One run of a bus along a [Subline].
class Trip {
  /// See [Departure.tripId].
  final int id;

  /// When the trip leaves its first stop.
  final DateTime departureTime;

  /// Whether the trip only runs on request.
  final bool onDemand;

  /// See [RouteLine.code]. Only set on trips from [TibTrips.all] and
  /// [TibTrips.forLine].
  final String? lineCode;

  /// The line's name, e.g. `Cala Millor - Palma`. Only set with [lineCode].
  final String? lineName;

  /// See [Subline.code]. Not set on trips from [TibTrips.byId].
  final String? sublineCode;

  /// See [Station.code]. Not set on trips from [TibTrips.byId].
  final String? firstStopCode;
  final String? firstStopName;

  /// The stops in order. Only set on trips from [TibTrips.byId] and
  /// [TibTrips.forSubline].
  final List<TripStop>? stops;

  Trip(
      {required this.id,
      required this.departureTime,
      this.onDemand = false,
      this.lineCode,
      this.lineName,
      this.sublineCode,
      this.firstStopCode,
      this.firstStopName,
      this.stops});

  @override
  String toString() {
    return 'Trip{id: $id, departureTime: $departureTime, onDemand: $onDemand, lineCode: $lineCode, lineName: $lineName, sublineCode: $sublineCode, firstStopCode: $firstStopCode, firstStopName: $firstStopName, stops: $stops}';
  }

  /// TIB sends times only, so [date] is the day the trip runs. Defaults to
  /// `dat`, which [toJson] writes.
  factory Trip.fromJson(Map json, {DateTime? date}) {
    date ??= DateTime.parse(json['dat']);
    final departureTime = _time(date, json['dep_t']);

    // A trip can run past midnight, so a time earlier than the previous one is
    // on the next day.
    var previous = departureTime;
    final stops = (json['stops'] as List?)?.map((stop) {
      var time = _time(date!, stop['dep_t']);
      while (time.isBefore(previous)) {
        time = time.add(const Duration(days: 1));
      }
      previous = time;
      return TripStop._fromJson(stop, time);
    }).toList();

    return Trip(
        id: json['trip_id'],
        departureTime: departureTime,
        onDemand: json['dem'] ?? false,
        lineCode: json['route']?['codi'],
        lineName: json['route']?['nom'],
        sublineCode: json['sublinea'],
        firstStopCode: json['stp_cod'],
        firstStopName: json['stp_nam'],
        stops: stops);
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': id,
      'dat':
          DateTime(departureTime.year, departureTime.month, departureTime.day)
              .toIso8601String(),
      'dep_t': _format(departureTime),
      'dem': onDemand,
      if (lineCode != null) 'route': {'codi': lineCode, 'nom': lineName},
      'sublinea': sublineCode,
      'stp_cod': firstStopCode,
      'stp_nam': firstStopName,
      'stops': stops?.map((stop) => stop.toJson()).toList(),
    };
  }

  /// [time] is `HH:mm:ss`.
  static DateTime _time(DateTime date, String time) {
    final [hours, minutes, seconds] = time.split(':').map(int.parse).toList();
    return DateTime(date.year, date.month, date.day, hours, minutes, seconds);
  }

  static String _format(DateTime time) => [time.hour, time.minute, time.second]
      .map((part) => '$part'.padLeft(2, '0'))
      .join(':');
}

/// A stop on a [Trip].
class TripStop {
  /// See [Station.id].
  final int stopId;

  /// See [Station.code].
  final String stopCode;

  final String name;

  /// Locality, e.g. `Cala Millor`.
  final String? town;

  /// When the bus passes.
  final DateTime time;

  /// Whether the bus only stops here on request.
  final bool onDemand;

  final double lat;
  final double long;

  /// Position in the itinerary. Increasing, but not necessarily by one.
  final int sequence;

  /// Id of the stop's fare zone.
  final int? fareZoneId;

  TripStop(
      {required this.stopId,
      required this.stopCode,
      required this.name,
      this.town,
      required this.time,
      this.onDemand = false,
      required this.lat,
      required this.long,
      required this.sequence,
      this.fareZoneId});

  @override
  String toString() {
    return 'TripStop{stopId: $stopId, stopCode: $stopCode, name: $name, town: $town, time: $time, onDemand: $onDemand, lat: $lat, long: $long, sequence: $sequence, fareZoneId: $fareZoneId}';
  }

  factory TripStop._fromJson(Map json, DateTime time) {
    return TripStop(
        stopId: json['stop_id'],
        stopCode: json['stop_cod'],
        name: json['nam'],
        town: json['town'],
        time: time,
        onDemand: json['dem'] ?? false,
        lat: (json['lat'] as num).toDouble(),
        long: (json['lng'] as num).toDouble(),
        sequence: json['seq'],
        fareZoneId: json['nt']);
  }

  Map<String, dynamic> toJson() {
    return {
      'stop_id': stopId,
      'stop_cod': stopCode,
      'nam': name,
      'town': town,
      'dep_t': Trip._format(time),
      'dem': onDemand,
      'lat': lat,
      'lng': long,
      'seq': sequence,
      'nt': fareZoneId,
    };
  }
}
