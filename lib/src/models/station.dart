/// A transit stop.
///
/// Which optional fields are populated depends on where the stop came from.
/// Stops nested in a [Subline] carry [town], [pickupType] and [dropoffType]
/// but no [ref]; stops from [StationsApi] carry [ref] but none of the others.
class Station {
  String code;
  int id;
  double lat;
  double long;
  String name;

  /// Only set on stops from [StationsApi].
  String? ref;

  /// Only set on stops nested in a [Subline].
  int? pickupType;

  /// Only set on stops nested in a [Subline].
  int? dropoffType;

  /// Town the stop belongs to. Only set on stops nested in a [Subline].
  String? town;

  Station(
      {required this.code,
      required this.id,
      required this.lat,
      required this.long,
      required this.name,
      this.ref,
      this.pickupType,
      this.dropoffType,
      this.town});

  bool get isDischargeOnly => pickupType == 1 && dropoffType != 1;
  bool get isPickupOnly => dropoffType == 1 && pickupType != 1;

  @override
  String toString() {
    return 'Station{code: $code, id: $id, lat: $lat, long: $long, name: $name, ref: $ref, pickupType: $pickupType, dropoffType: $dropoffType, town: $town}';
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
        dropoffType: json['dropoffType'],
        town: json['parent']);
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
      'dropoffType': station.dropoffType,
      'parent': station.town
    };
  }
}
