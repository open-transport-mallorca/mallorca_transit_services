import 'package:latlong2/latlong.dart';
import 'package:mallorca_transit_services/src/models/station.dart';
import 'package:xml/xml.dart';

enum Way { way, back }

enum LineClass { main, sub }

enum LineType { train, metro, bus, unknown }

class RouteLine {
  bool active;
  String code;
  int id;
  String name;
  int color;
  LineType type;
  List<Subline>? sublines;

  RouteLine(
      {required this.active,
      required this.code,
      required this.id,
      required this.name,
      required this.color,
      this.sublines,
      required this.type});

  @override
  String toString() {
    return 'Line{active: $active, code: $code, color: $color id: $id, name: $name, type: $type, sublines: $sublines}';
  }

  factory RouteLine.fromJson(Map json) {
    LineType type;

    if (json['typ'] == 1) {
      type = LineType.train;
    } else if (json['typ'] == 2) {
      type = LineType.metro;
    } else if (json['typ'] == 3) {
      type = LineType.bus;
    } else {
      type = LineType.unknown;
    }

    var routeLine = RouteLine(
        active: json['act'],
        code: json['cod'],
        id: json['id'],
        name: json['nam'],
        color: int.parse(json['color'].replaceAll("#", "0xFF")),
        type: type);

    if (json['sublines'] != null) {
      List<Subline>? sublines = (json['sublines'] as List<dynamic>)
          .map((subline) => Subline.fromJson(subline, routeLine))
          .toList();
      routeLine.sublines = sublines;
    }

    return routeLine;
  }

  static Map toJson(RouteLine line) {
    int type;

    if (line.type == LineType.train) {
      type = 1;
    } else if (line.type == LineType.metro) {
      type = 2;
    } else if (line.type == LineType.bus) {
      type = 3;
    } else {
      type = -1;
    }

    return {
      'act': line.active,
      'cod': line.code,
      'id': line.id,
      'nam': line.name,
      'color': line.color.toString(),
      'type': type,
      'sublines':
          line.sublines?.map((subline) => Subline.toJson(subline)).toList()
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

  Subline(
      {required this.parentLine,
      required this.active,
      required this.code,
      required this.id,
      required this.name,
      required this.color,
      required this.type,
      required this.stations,
      required this.way});

  factory Subline.fromJson(Map json, RouteLine mainRouteLine) {
    return Subline(
        parentLine: mainRouteLine,
        active: json['vis'],
        code: json['cod'],
        id: json['id'],
        name: json['nam'],
        color: mainRouteLine.color,
        type: mainRouteLine.type,
        stations: json['stops']
            .map<Station>((station) => Station.fromJson(station))
            .toList(),
        way: json['way'] == "Anada" ? Way.way : Way.back);
  }

  static Map toJson(Subline subline) {
    return {
      'vis': subline.active,
      'cod': subline.code,
      'id': subline.id,
      'nam': subline.name,
      'stops':
          subline.stations.map((station) => Station.toJson(station)).toList(),
      'way': subline.way == Way.way ? "Anada" : "Tornada"
    };
  }

  @override
  String toString() {
    return 'Subline{active: $active, code: $code, color: $color, id: $id, name: $name, type: $type, way: $way, stations: $stations, parentLine: $parentLine}';
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
