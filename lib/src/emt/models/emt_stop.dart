class EmtStop {
  /// Also the code shown at the stop.
  final int id;

  final String name;
  final double lat;
  final double long;

  /// `null` if unknown.
  final bool? wheelchairAccessible;

  EmtStop(
      {required this.id,
      required this.name,
      required this.lat,
      required this.long,
      this.wheelchairAccessible});

  @override
  String toString() {
    return 'EmtStop{id: $id, name: $name, lat: $lat, long: $long, wheelchairAccessible: $wheelchairAccessible}';
  }

  factory EmtStop.fromJson(Map json) {
    return EmtStop(
        id: json['id'],
        name: json['stopName'],
        lat: (json['stopLat'] as num).toDouble(),
        long: (json['stopLon'] as num).toDouble(),
        // GTFS: 0 is no information, 1 is accessible, 2 is not.
        wheelchairAccessible: switch (json['stopWheelchairBoarding']) {
          1 => true,
          2 => false,
          _ => null,
        });
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stopName': name,
      'stopLat': lat,
      'stopLon': long,
      'stopWheelchairBoarding': switch (wheelchairAccessible) {
        true => 1,
        false => 2,
        null => 0,
      },
    };
  }
}
