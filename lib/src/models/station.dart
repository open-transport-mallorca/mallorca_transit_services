class Station {
  int code;
  int id;
  double lat;
  double long;
  String name;
  String? ref;

  Station(
      {required this.code,
      required this.id,
      required this.lat,
      required this.long,
      required this.name,
      this.ref});

  @override
  String toString() {
    return 'Station{code: $code, id: $id, lat: $lat, long: $long, name: $name, ref: $ref}';
  }

  factory Station.fromJson(Map json) {
    return Station(
        code: int.parse(json['cod']),
        id: json['id'],
        lat: json['lat'],
        long: json['lon'],
        name: json['nam'],
        ref: json['ref']);
  }

  static Map toJson(Station station) {
    return {
      'cod': station.code.toString(),
      'id': station.id,
      'lat': station.lat,
      'lon': station.long,
      'nam': station.name,
      'ref': station.ref
    };
  }
}
