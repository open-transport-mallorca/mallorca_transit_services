// ignore_for_file: non_constant_identifier_names, unused_element

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart';

class Departures {
  static Client httpClient = Client();
  List<Departure>? departures;

  Departures({this.departures});

  /// Connects to the API and returns the list of departures from a station.
  /// The [stationCode] is the ID of the station.
  /// The [numberOfDepartures] is the number of departures to return.
  ///
  /// Throws a [FormatException] if the station code is invalid.
  /// Throws an [HttpException] if the server is unreachable.
  /// Throws a [SocketException] if there is no internet connection.
  /// Throws an [Exception] if there are no departures found.
  static Future<List<Departure>> getDepartures(
      {required int stationCode, required int numberOfDepartures}) async {
    Uri url = Uri.parse(
        'http://tib.org/o/manager/stop-code/$stationCode/departures/ctmr4?res=$numberOfDepartures');
    try {
      Uint8List responseBytes =
          await httpClient.get(url).then((value) => value.bodyBytes);
      List<Departure> departures = [];
      for (var response in json.decode(utf8.decode(responseBytes))) {
        Departure responseDeparture = Departure.fromJson(response);
        departures.add(responseDeparture);
      }

      if (departures.isEmpty) {
        throw Exception(
            "No departures found. 😕 Please check that the station code is correct.");
      } else {
        return departures;
      }
    } on FormatException {
      throw FormatException("The station code is invalid. 😶");
    } catch (e) {
      throw Exception(
          "There was an error fetching the departures. 😕 Please try again later.");
    }
  }
}

/// A class that represents a real-time trip from a Departure.
/// A real-time trip has an estimated arrival time, a latitude, and a longitude.
///
/// The estimated arrival time is optional.
class RealTrip {
  DateTime? estimatedArrival;
  double lat;
  double long;
  int id;

  RealTrip(
      {this.estimatedArrival,
      required this.lat,
      required this.long,
      required this.id});

  @override
  toString() {
    return 'RealTrip{estimatedArrival: $estimatedArrival, lat: $lat, long: $long}';
  }

  /// Converts a JSON map to a [RealTrip] object.
  ///
  /// The [json] parameter is a map representing the JSON data.
  /// Returns a [RealTrip] object with the converted data.
  factory RealTrip.fromJson(Map json) {
    return RealTrip(
        estimatedArrival:
            json['aet'] != null ? DateTime.tryParse(json['aet']) : null,
        lat: json['lastCoords']['lat'],
        long: json['lastCoords']['lng'],
        id: int.parse(json['id']));
  }

  /// Converts a [RealTrip] object to a JSON map.
  static String toJson(RealTrip realTrip) {
    return jsonEncode({
      'aet': realTrip.estimatedArrival?.toIso8601String(),
      'lastCoords': {'lat': realTrip.lat, 'lng': realTrip.long},
      'id': realTrip.id
    });
  }
}

/// A departure from the departures list.
///
/// A departure has a departure time, an estimated arrival time, a name, a trip ID,
/// a real trip, a line color, a delayed status, a line code, a destination, and a departure stop.
/// The real trip, destination, and departure stop are optional.
class Departure {
  DateTime departureTime;
  DateTime estimatedArrival;
  String name;
  int tripId;
  RealTrip? realTrip;
  bool delayed;
  String lineCode;
  String? destination;
  String? departureStop;

  Departure(
      {required this.departureTime,
      required this.estimatedArrival,
      required this.name,
      required this.tripId,
      this.realTrip,
      required this.delayed,
      required this.lineCode,
      this.destination,
      this.departureStop});

  @override
  String toString() {
    return 'Departure{departureTime: $departureTime, estimatedArrival: $estimatedArrival, name: $name, tripId: $tripId, realTrip: $realTrip, delayed: $delayed, lineCode: $lineCode, destination: $destination, departureStop: $departureStop}';
  }

  /// Converts a JSON map to a [Departure] object.
  /// The [json] parameter is a map representing the JSON data.
  /// Returns a [Departure] object with the converted data.
  factory Departure.fromJson(Map json) {
    return Departure(
        departureTime: DateTime.parse(json['dt']),
        estimatedArrival: DateTime.parse(json['aet']),
        name: json['snam'],
        tripId: json['trip_id'],
        realTrip: json['realTrip'] != null
            ? RealTrip.fromJson(json['realTrip'])
            : null,
        delayed: json['dem'],
        lineCode: json['lcod'],
        destination: json['etn'],
        departureStop: json['et']);
  }

  /// Converts a [Departure] object to a JSON map.
  /// returns a map representing the JSON data.
  static Map toJson(Departure departure) {
    return {
      'dt': departure.departureTime.toIso8601String(),
      'aet': departure.estimatedArrival.toIso8601String(),
      'snam': departure.name,
      'trip_id': departure.tripId,
      'realTrip': departure.realTrip != null
          ? RealTrip.toJson(departure.realTrip!)
          : null,
      'dem': departure.delayed,
      'lcod': departure.lineCode,
      'etn': departure.destination,
      'et': departure.departureStop
    };
  }
}
