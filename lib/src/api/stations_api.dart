import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart';
import 'package:mallorca_transit_services/src/api/route_lines_api.dart';
import 'package:mallorca_transit_services/src/models/route_line.dart';
import 'package:mallorca_transit_services/src/models/station.dart';

class StationsApi {
  static Client httpClient = Client();

  /// Use [Station.code], not [Station.id].
  static Future<List<RouteLine>> getLines(int stationCode) async {
    Uri url =
        Uri.parse("https://ws.tib.org/sictmws-rest/stops/ctmr4/$stationCode");
    try {
      Uint8List responseBytes =
          await httpClient.get(url).then((value) => value.bodyBytes);

      List<RouteLine> lines = [];
      for (Map line in json.decode(utf8.decode(responseBytes))["lines"]) {
        lines.add(await RouteLinesApi.getLine(line["cod"]));
      }

      return lines;
    } on FormatException {
      throw FormatException("The station code is invalid. 😶");
    }
  }

  static Future<Station> fromId(int id) async {
    final url = Uri.parse("https://ws.tib.org/sictmws-rest/stops/ctmr4/$id");

    try {
      Uint8List responseBytes =
          await httpClient.get(url).then((value) => value.bodyBytes);

      return Station.fromJson(json.decode(utf8.decode(responseBytes)));
    } catch (e) {
      throw Exception(
          "There was an error fetching the station. 😕 Please try again later.");
    }
  }

  /// Pass [count] to limit results; -1 returns all stations (default).
  static Future<List<Station>> getAllStations({int count = -1}) async {
    final url =
        Uri.parse("https://ws.tib.org/sictmws-rest/stops/ctmr4?res=$count");

    try {
      Uint8List responseBytes =
          await httpClient.get(url).then((value) => value.bodyBytes);

      List<Station> stations = [];
      for (Map station
          in json.decode(utf8.decode(responseBytes))["stopsInfo"]) {
        stations.add(Station.fromJson(station));
      }

      return stations;
    } catch (e) {
      throw Exception(
          "There was an error fetching the stations. 😕 Please try again later.");
    }
  }
}
