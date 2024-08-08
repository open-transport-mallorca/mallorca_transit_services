import 'dart:convert';
import 'dart:typed_data';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart';
import 'package:latlong2/latlong.dart';
import 'package:mallorca_transit_services/src/api/stations.dart';
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

  static Client httpClient = Client();

  static Future<List<RouteLine>> getAllLines() async {
    Uri url = Uri.parse("https://ws.tib.org/sictmws-rest/lines/ctmr4");
    try {
      Uint8List responseBytes =
          await httpClient.get(url).then((value) => value.bodyBytes);

      List<RouteLine> lines = [];
      for (Map line in json.decode(utf8.decode(responseBytes))["linesInfo"]) {
        RouteLine responseLine = RouteLine.fromJson(line);
        lines.add(responseLine);
      }

      return lines;
    } on FormatException {
      throw FormatException("Something went wrong. 😶");
    }
  }

  static Future<RouteLine> getLine(String lineCode) async {
    Uri url =
        Uri.parse("https://ws.tib.org/sictmws-rest/lines/ctmr4/$lineCode");
    try {
      Uint8List responseBytes =
          await httpClient.get(url).then((value) => value.bodyBytes);
      return RouteLine.fromJson(json.decode(utf8.decode(responseBytes)));
    } on FormatException {
      throw FormatException("Something went wrong. 😶");
    }
  }

  static Future<Uri?> getPdfTimetable(String lineCode) async {
    try {
      final response = await httpClient.get(Uri.parse(
          "https://www.tib.org/es/lineas-y-horarios/autobus/-/linia/$lineCode"));
      final parser = parse(response.body);
      Element div =
          parser.getElementsByClassName('ctm-line-schedule-link').first;
      String? href = div.querySelector('a')!.attributes['href'];
      return href != null ? Uri.parse(href) : null;
    } catch (e) {
      throw Exception('Failed to scrape Timetable PDF');
    }
  }

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

  /// Get the sublines of a line.
  /// If [onlyActive] is true, only the active sublines are returned.
  /// If [onlyActive] is false, all sublines are returned.
  /// The default value of [onlyActive] is true.
  static Future<List<Subline>> getSublines(RouteLine line,
      [bool onlyActive = true]) async {
    Uri url =
        Uri.parse("https://ws.tib.org/sictmws-rest/lines/ctmr4/${line.code}");
    try {
      Uint8List responseBytes = await get(url).then((value) => value.bodyBytes);
      List<Subline> sublines = [];
      final Map responseMap = json.decode(utf8.decode(responseBytes));
      List sublinesList = responseMap["sublines"];
      for (Map subline in sublinesList) {
        Subline responseSubline = Subline.fromJson(subline, line);
        sublines.add(responseSubline);
      }
      if (onlyActive && sublinesList.length > 2) {
        sublines.removeWhere((element) => element.active == false);
      }
      return sublines;
    } on FormatException {
      throw FormatException("Something went wrong. 😶");
    }
  }

  /// Get [Subline] object from JSON data.
  /// The [json] parameter is a map representing the JSON data.
  /// The [mainRouteLine] parameter is the parent line of the subline.
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

  /// Get JSON data from [Subline] object.
  /// The [subline] parameter is the subline object to convert to JSON.
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

/// A class that represents a route path.
/// A route path has a subline and a list of paths.
/// Each path is a list of coordinates.
/// The coordinates are represented by a [LatLng] object.
/// The [subline] parameter is the subline of the route path.
class RoutePath {
  static Client httpClient = Client();

  Subline subline;
  List<List<LatLng>> paths;

  RoutePath({required this.subline, required this.paths});

  /// Get the path of a subline.
  /// The [subline] parameter is the subline to get the path from.
  /// Returns a [RoutePath] object with the path of the subline.
  static Future<RoutePath> getPath(Subline subline) async {
    Uri url = Uri.parse(
        "https://ws.tib.org/sictmws-rest/lines/ctmr4/${subline.parentLine.code}/kmz/${subline.code}");
    try {
      Uint8List responseBytes =
          await httpClient.get(url).then((value) => value.bodyBytes);
      return RoutePath.fromKmz(utf8.decode(responseBytes), subline);
    } on FormatException {
      throw FormatException("Something went wrong. 😶");
    }
  }

  @override
  String toString() {
    return 'RoutePath{line: ${subline.parentLine}, subline: $subline, paths: $paths}';
  }

  /// Get a [RoutePath] object from a KMZ file.
  /// The [kmz] parameter is the KMZ file to get the path from.
  /// The [subline] parameter is the subline of the route path.
  /// Returns a [RoutePath] object with the path of the subline.
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
