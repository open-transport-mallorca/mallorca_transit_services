/// Whether passengers can board or get off at a stop. Follows GTFS.
enum PickupDropoffType {
  regular(0),
  notAvailable(1),

  /// Must be arranged by phone.
  phoneAgency(2),

  /// Must be arranged with the driver.
  coordinateWithDriver(3),
  unknown(-1);

  /// The value TIB sends.
  final int value;

  const PickupDropoffType(this.value);

  static PickupDropoffType? _fromValue(int? value) {
    if (value == null) return null;
    return values.firstWhere((type) => type.value == value,
        orElse: () => unknown);
  }
}

/// A bus stop.
class Station {
  /// Public code, shown at the stop.
  String code;

  /// Internal id.
  int id;

  double lat;
  double long;
  String name;

  /// Direction the stop serves, e.g. `Sentit cap a Cala Bona`. Only set on
  /// stops from [TibStations].
  String? ref;

  /// Whether passengers can board here. Only set on a [Subline]'s stops.
  PickupDropoffType? pickupType;

  /// Whether passengers can get off here. Only set on a [Subline]'s stops.
  PickupDropoffType? dropoffType;

  /// Town the stop belongs to. Only set on a [Subline]'s stops.
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

  /// Whether passengers can only get off here.
  bool get isDischargeOnly =>
      pickupType == PickupDropoffType.notAvailable &&
      dropoffType != PickupDropoffType.notAvailable;

  /// Whether passengers can only board here.
  bool get isPickupOnly =>
      dropoffType == PickupDropoffType.notAvailable &&
      pickupType != PickupDropoffType.notAvailable;

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
        pickupType: PickupDropoffType._fromValue(json['pickupType']),
        dropoffType: PickupDropoffType._fromValue(json['dropoffType']),
        town: json['parent']);
  }

  Map<String, dynamic> toJson() {
    return {
      'cod': code,
      'id': id,
      'lat': lat,
      'lon': long,
      'nam': name,
      'ref': ref,
      'pickupType': pickupType?.value,
      'dropoffType': dropoffType?.value,
      'parent': town
    };
  }
}
