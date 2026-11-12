class EmtDeparture {
  /// See [EmtLine.code].
  final String lineCode;

  final String destination;

  /// The number on the bus.
  final int busNumber;

  /// When the bus reaches the stop.
  final DateTime arrival;

  final bool atStop;

  /// Whether the bus is about to reach the stop.
  final bool arriving;

  /// Whether the bus starts its route at this stop.
  final bool startsHere;

  EmtDeparture(
      {required this.lineCode,
      required this.destination,
      required this.busNumber,
      required this.arrival,
      this.atStop = false,
      this.arriving = false,
      this.startsHere = false});

  @override
  String toString() {
    return 'EmtDeparture{lineCode: $lineCode, destination: $destination, busNumber: $busNumber, arrival: $arrival, atStop: $atStop, arriving: $arriving, startsHere: $startsHere}';
  }

  /// EMT sends the seconds until arrival, counted from [now]. Without
  /// `seconds`, reads `arrival`, which [toJson] writes.
  factory EmtDeparture.fromJson(Map json, {DateTime? now}) {
    final seconds = json['seconds'];
    return EmtDeparture(
        lineCode: json['lineCode'],
        destination: json['destination'],
        busNumber: json['code'],
        arrival: seconds != null
            ? (now ?? DateTime.now()).add(Duration(seconds: seconds))
            : DateTime.parse(json['arrival']),
        atStop: json['atStop'] ?? false,
        arriving: json['arriving'] ?? false,
        startsHere: json['head'] ?? false);
  }

  Map<String, dynamic> toJson() {
    return {
      'lineCode': lineCode,
      'destination': destination,
      'code': busNumber,
      'arrival': arrival.toIso8601String(),
      'atStop': atStop,
      'arriving': arriving,
      'head': startsHere,
    };
  }
}
