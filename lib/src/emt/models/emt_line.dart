class EmtLine {
  final int id;

  /// E.g. `A1`, `4` or `N1`.
  final String code;

  final String name;

  /// ARGB.
  final int color;

  EmtLine(
      {required this.id,
      required this.code,
      required this.name,
      required this.color});

  @override
  String toString() {
    return 'EmtLine{id: $id, code: $code, name: $name, color: $color}';
  }

  factory EmtLine.fromJson(Map json) {
    return EmtLine(
        id: json['id'],
        code: json['code'],
        name: json['name'],
        color: 0xFF000000 | int.parse(json['routeColor'], radix: 16));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'routeColor':
          (color & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase(),
    };
  }
}

/// A variant of an [EmtLine], e.g. a shortened one.
class EmtSubline {
  final int id;
  final int lineId;

  /// E.g. `Nou Llevant - Ses Illetes`.
  final String name;

  /// E.g. `Nou Llevant-Illetes`.
  final String shortName;

  /// EMT's number for it within the line.
  final int number;

  EmtSubline(
      {required this.id,
      required this.lineId,
      required this.name,
      required this.shortName,
      required this.number});

  @override
  String toString() {
    return 'EmtSubline{id: $id, lineId: $lineId, name: $name, shortName: $shortName, number: $number}';
  }

  factory EmtSubline.fromJson(Map json) {
    return EmtSubline(
        id: json['subLineId'],
        lineId: json['lineId'],
        name: json['longName'],
        shortName: json['shortName'],
        number: json['externalCode']);
  }

  Map<String, dynamic> toJson() {
    return {
      'subLineId': id,
      'lineId': lineId,
      'longName': name,
      'shortName': shortName,
      'externalCode': number,
    };
  }
}

/// One direction of an [EmtSubline].
class EmtRoute {
  /// EMT calls it `tripId`, but it's shared by every trip in this direction.
  final int id;

  final int lineId;
  final int sublineId;

  /// 1 outbound, 2 return.
  final int direction;

  /// Where it's heading, as shown on the bus.
  final String headsign;

  EmtRoute(
      {required this.id,
      required this.lineId,
      required this.sublineId,
      required this.direction,
      required this.headsign});

  @override
  String toString() {
    return 'EmtRoute{id: $id, lineId: $lineId, sublineId: $sublineId, direction: $direction, headsign: $headsign}';
  }

  /// EMT doesn't send [lineId] and [sublineId], so they default to those in
  /// [json], which [toJson] writes.
  factory EmtRoute.fromJson(Map json, {int? lineId, int? sublineId}) {
    return EmtRoute(
        id: json['tripId'],
        lineId: lineId ?? json['lineId'],
        sublineId: sublineId ?? json['subLineId'],
        direction: json['directionId'],
        headsign: json['headSign']);
  }

  Map<String, dynamic> toJson() {
    return {
      'tripId': id,
      'lineId': lineId,
      'subLineId': sublineId,
      'directionId': direction,
      'headSign': headsign,
    };
  }
}
