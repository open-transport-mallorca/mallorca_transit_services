import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart';
import 'package:mallorca_transit_services/src/models/departure.dart';

class DeparturesApi {
  static Client httpClient = Client();

  /// Throws [FormatException] for an invalid station code, [Exception] if no departures are found.
  static Future<List<Departure>> getDepartures(
      {required int stationCode, required int numberOfDepartures}) async {
    Uri url = Uri.parse(
        'http://tib.org/o/manager/stop-code/$stationCode/departures/ctmr4?res=$numberOfDepartures');
    try {
      Uint8List responseBytes =
          await httpClient.get(url).then((value) => value.bodyBytes);
      List<Departure> departures = [];
      for (var response in json.decode(utf8.decode(responseBytes))) {
        departures.add(Departure.fromJson(response));
      }

      if (departures.isEmpty) {
        throw Exception(
            "No departures found. Please check that the station code is correct.");
      } else {
        return departures;
      }
    } on FormatException {
      throw FormatException("The station code is invalid.");
    } catch (e) {
      throw Exception(
          "There was an error fetching the departures. Please try again later.");
    }
  }
}
