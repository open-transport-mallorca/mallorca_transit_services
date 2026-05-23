import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart';
import 'package:mallorca_transit_services/src/models/route_line.dart';

class RouteLinesApi {
  static Client httpClient = Client();

  static Future<List<RouteLine>> getAllLines({bool activeOnly = false}) async {
    Uri url = Uri.parse("https://ws.tib.org/sictmws-rest/lines/ctmr4");
    try {
      Uint8List responseBytes =
          await httpClient.get(url).then((value) => value.bodyBytes);

      List<RouteLine> lines = [];
      for (Map line in json.decode(utf8.decode(responseBytes))["linesInfo"]) {
        if (activeOnly && line["act"] == false) {
          continue;
        }
        lines.add(RouteLine.fromJson(line));
      }

      return lines;
    } on FormatException {
      throw FormatException("Something went wrong.");
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
      throw FormatException("Something went wrong.");
    }
  }

  /// Fetches the URL of the most recent PDF timetable for the given [lineCode].
  static Future<Uri?> getPdfTimetable(String lineCode, {int? lineId}) async {
    try {
      if (lineId == null) {
        final lineQuery = await httpClient.get(
            Uri.parse("https://ws.tib.org/sictmws-rest/lines/ctmr4/$lineCode"));
        lineId = json.decode(lineQuery.body)["id"];
      }
      final pdfQuery = await httpClient.get(Uri.parse(
        "https://www.tib.org/o/manager/schedules/$lineId?groupId=20124",
      ));

      final List<dynamic> schedules = jsonDecode(pdfQuery.body);
      final latest = schedules.reduce((a, b) {
        final dateA = a["JSONObject"]["FechaDeInicioDeValidez"] as String;
        final dateB = b["JSONObject"]["FechaDeInicioDeValidez"] as String;
        return dateA.compareTo(dateB) >= 0 ? a : b;
      });

      final pdfPath = latest["JSONObject"]["urlScheduleFile"];
      return Uri.parse("https://www.tib.org$pdfPath");
    } catch (e) {
      throw Exception('Failed to scrape Timetable PDF');
    }
  }

  /// Pass [onlyActive] false to include inactive sublines.
  static Future<List<Subline>> getSublines(RouteLine line,
      [bool onlyActive = true]) async {
    Uri url =
        Uri.parse("https://ws.tib.org/sictmws-rest/lines/ctmr4/${line.code}");
    try {
      Uint8List responseBytes =
          await httpClient.get(url).then((value) => value.bodyBytes);
      List<Subline> sublines = [];
      final Map responseMap = json.decode(utf8.decode(responseBytes));
      List sublinesList = responseMap["sublines"];
      for (Map subline in sublinesList) {
        sublines.add(Subline.fromJson(subline, line));
      }
      if (onlyActive && sublinesList.length > 2) {
        sublines.removeWhere((element) => element.active == false);
      }
      return sublines;
    } on FormatException {
      throw FormatException("Something went wrong.");
    }
  }

  static Future<RoutePath> getPath(Subline subline) async {
    Uri url = Uri.parse(
        "https://ws.tib.org/sictmws-rest/lines/ctmr4/${subline.parentLine.code}/kmz/${subline.code}");
    try {
      Uint8List responseBytes =
          await httpClient.get(url).then((value) => value.bodyBytes);
      return RoutePath.fromKmz(utf8.decode(responseBytes), subline);
    } on FormatException {
      throw FormatException("Something went wrong.");
    }
  }
}
