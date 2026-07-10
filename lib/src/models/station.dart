class Station {
  String code;
  int id;
  double lat;
  double long;
  String name;
  String? ref;
  int? pickupType;
  int? dropoffType;

  Station(
      {required this.code,
      required this.id,
      required this.lat,
      required this.long,
      required this.name,
      this.ref,
      this.pickupType,
      this.dropoffType});

  bool get isDischargeOnly => pickupType == 1 && dropoffType != 1;
  bool get isPickupOnly => dropoffType == 1 && pickupType != 1;

  @override
  String toString() {
    return 'Station{code: $code, id: $id, lat: $lat, long: $long, name: $name, ref: $ref, pickupType: $pickupType, dropoffType: $dropoffType}';
  }

  factory Station.fromJson(Map json) {
    return Station(
        code: json['cod'],
        id: json['id'],
        lat: json['lat'],
        long: json['lon'],
        name: json['nam'],
        ref: json['ref'],
        pickupType: json['pickupType'],
        dropoffType: json['dropoffType']);
  }

  static Map toJson(Station station) {
    return {
      'cod': station.code,
      'id': station.id,
      'lat': station.lat,
      'lon': station.long,
      'nam': station.name,
      'ref': station.ref,
      'pickupType': station.pickupType,
      'dropoffType': station.dropoffType
    };
  }
}
