import 'package:latlong2/latlong.dart';
import 'package:mallorca_transit_services/src/models/station.dart';
import 'package:xml/xml.dart';

enum Way { way, back }

enum LineType {
  train, // 1
  metro, // 2
  bus, // 3
  unknown
}

enum PickupDropoffType {
  regular, // 0
  notAvailable, // 1
  phoneAgency, // 2
  coordinateWithDriver, // 3
}

class RouteLine {
  bool active;
  String code;
  int id;
  String name;
  int color;
  LineType type;
  List<Subline>? sublines;
  bool? summerOnly;
  List<RouteSession>? sessions;
  List<RouteTown>? towns;
  List<RouteHoliday>? holidays;
  List<int>? zoneIds;
  bool? onDemand;

  RouteLine(
      {required this.active,
      required this.code,
      required this.id,
      required this.name,
      required this.color,
      this.sublines,
      required this.type,
      this.summerOnly,
      this.sessions,
      this.towns,
      this.holidays,
      this.zoneIds,
      this.onDemand});

  @override
  String toString() {
    return 'Line{active: $active, code: $code, color: $color, id: $id, name: $name, type: $type, sublines: $sublines, summerOnly: $summerOnly, sessions: $sessions, towns: $towns, holidays: $holidays, zoneIds: $zoneIds, onDemand: $onDemand}';
  }

  factory RouteLine.fromJson(Map json) {
    final routeLine = RouteLine(
      active: json['act'],
      code: json['cod'],
      id: json['id'],
      name: json['nam'],
      color: int.parse(json['color'].replaceAll("#", "0xFF")),
      type: switch (json['typ']) {
        1 => LineType.train,
        2 => LineType.metro,
        3 => LineType.bus,
        _ => LineType.unknown,
      },
      summerOnly: json['summ'],
    );

    routeLine.sublines = (json['sublines'] as List?)
        ?.map((s) => Subline.fromJson(s, routeLine))
        .toList();
    routeLine.sessions = (json['sessions'] as List?)
        ?.map((s) => RouteSession.fromJson(s))
        .toList();
    routeLine.towns =
        (json['towns'] as List?)?.map((t) => RouteTown.fromJson(t)).toList();
    routeLine.holidays = (json['festius'] as List?)
        ?.map((h) => RouteHoliday.fromJson(h))
        .toList();
    routeLine.zoneIds =
        (json['zoneTransport'] as List?)?.map((z) => z['id'] as int).toList();
    routeLine.onDemand = json['dem'];

    return routeLine;
  }

  static Map toJson(RouteLine line) {
    return {
      'act': line.active,
      'cod': line.code,
      'id': line.id,
      'nam': line.name,
      'color': line.color.toString(),
      'typ': switch (line.type) {
        LineType.train => 1,
        LineType.metro => 2,
        LineType.bus => 3,
        _ => -1,
      },
      'sublines': line.sublines?.map(Subline.toJson).toList(),
      'summ': line.summerOnly,
      'sessions': line.sessions?.map(RouteSession.toJson).toList(),
      'towns': line.towns?.map(RouteTown.toJson).toList(),
      'festius': line.holidays?.map(RouteHoliday.toJson).toList(),
      'zoneTransport': line.zoneIds?.map((id) => {'id': id}).toList(),
      'dem': line.onDemand
    };
  }
}

class Subline {
  RouteLine parentLine;
  bool active;
  String code;
  int id;
  String name;
  int color;
  LineType type;
  Way way;
  List<Station> stations;
  List<RouteTown>? towns;
  bool? main;
  double? distance;

  Subline(
      {required this.parentLine,
      required this.active,
      required this.code,
      required this.id,
      required this.name,
      required this.color,
      required this.type,
      required this.stations,
      required this.way,
      this.towns,
      this.main,
      this.distance});

  factory Subline.fromJson(Map json, RouteLine mainRouteLine) {
    return Subline(
        parentLine: mainRouteLine,
        active: json['vis'],
        code: json['cod'],
        id: json['id'],
        name: json['nam'],
        color: mainRouteLine.color,
        type: mainRouteLine.type,
        stations: (json['stops'] as List<dynamic>)
            .map<Station>((station) => Station.fromJson(station))
            .toList(),
        towns: json['towns'] != null
            ? (json['towns'] as List<dynamic>)
                .map((town) => RouteTown.fromJson(town))
                .toList()
            : null,
        way: json['dir'] == "Anada" ? Way.way : Way.back,
        main: json['main'],
        distance: (json['distance'] as num?)?.toDouble());
  }

  static Map toJson(Subline subline) {
    return {
      'vis': subline.active,
      'cod': subline.code,
      'id': subline.id,
      'nam': subline.name,
      'stops':
          subline.stations.map((station) => Station.toJson(station)).toList(),
      'dir': subline.way == Way.way ? "Anada" : "Tornada",
      'main': subline.main,
      'towns': subline.towns?.map((town) => RouteTown.toJson(town)).toList(),
      'distance': subline.distance
    };
  }

  @override
  String toString() {
    return 'Subline{active: $active, code: $code, color: $color, id: $id, name: $name, type: $type, way: $way, stations: $stations, parentLine: $parentLine, towns: $towns, main: $main, distance: $distance}';
  }
}

class RouteSession {
  String? busTypeId;
  bool current;
  DateTime startDate;
  DateTime endDate;
  String name;

  RouteSession(
      {this.busTypeId,
      required this.current,
      required this.startDate,
      required this.endDate,
      required this.name});

  @override
  String toString() {
    return 'RouteSession{busTypeId: $busTypeId, current: $current, startDate: $startDate, endDate: $endDate, name: $name}';
  }

  factory RouteSession.fromJson(Map json) {
    return RouteSession(
        busTypeId: json['busTypeId'],
        current: json['cur'],
        startDate: DateTime.parse(json['ini']),
        endDate: DateTime.parse(json['end']),
        name: json['nam']);
  }

  static Map toJson(RouteSession session) {
    return {
      'busTypeId': session.busTypeId,
      'cur': session.current,
      'ini': session.startDate.toIso8601String(),
      'end': session.endDate.toIso8601String(),
      'nam': session.name
    };
  }
}

class RouteTown {
  int id;
  double distance;
  String name;

  RouteTown({required this.id, required this.distance, required this.name});

  @override
  String toString() {
    return 'RouteTown{id: $id, distance: $distance, name: $name}';
  }

  factory RouteTown.fromJson(Map json) {
    return RouteTown(id: json['id'], distance: (json['dis'] as num).toDouble(), name: json['nam']);
  }

  static Map toJson(RouteTown town) {
    return {'id': town.id, 'dis': town.distance, 'nam': town.name};
  }
}

/// Holidays that may affect the schedule of a route line.
///
/// Only returned by [RouteLinesApi.getLine], not by [RouteLinesApi.getAllLines].
class RouteHoliday {
  DateTime date;
  String name;

  RouteHoliday({required this.date, required this.name});

  @override
  String toString() {
    return 'RouteHoliday{date: $date, name: $name}';
  }

  factory RouteHoliday.fromJson(Map json) {
    return RouteHoliday(date: DateTime.parse(json['dat']), name: json['nam']);
  }

  static Map toJson(RouteHoliday holiday) {
    return {'dat': holiday.date.toIso8601String(), 'nam': holiday.name};
  }
}

/// A route path with a list of coordinate segments for a given [Subline].
class RoutePath {
  Subline subline;
  List<List<LatLng>> paths;

  RoutePath({required this.subline, required this.paths});

  @override
  String toString() {
    return 'RoutePath{line: ${subline.parentLine}, subline: $subline, paths: $paths}';
  }

  static RoutePath fromKmz(String kmz, Subline subline) {
    final document = XmlDocument.parse(kmz);
    List<List<LatLng>> allCoordinates = [];
    var lineStrings = document.findAllElements('LineString');

    for (XmlElement lineString in lineStrings) {
      var coordinates = lineString.findElements('coordinates');
      if (coordinates.isNotEmpty) {
        List<LatLng> coordinatesList = [];
        var coordinatesString = coordinates.first.innerText;
        var coordinatesSplit = coordinatesString.split(" ");
        for (var coordinate in coordinatesSplit) {
          var latLong = coordinate.split(",");
          coordinatesList
              .add(LatLng(double.parse(latLong[1]), double.parse(latLong[0])));
        }
        allCoordinates.add(coordinatesList);
      }
    }
    return RoutePath(paths: allCoordinates, subline: subline);
  }
}
