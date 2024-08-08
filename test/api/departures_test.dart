import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mallorca_transit_services/mallorca_transit_services.dart';

void main() {
  group('Departures.getDepartures', () {
    test('returns list of departures when the API call is successful',
        () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response(
            jsonEncode([
              {
                "dt": "1970-01-01T10:12:00",
                "aet": "2024-05-24T11:39:00",
                "snam": "Departure 1",
                "trip_id": 558719,
                "lineColor": "401",
                "dem": false,
                "lcod": "401",
                "etn": "Manacor",
                "dtn": null,
                "et": "1970-01-01T11:55:00"
              },
              {
                "dt": "1970-01-01T11:20:00",
                "aet": "2024-05-24T11:42:00",
                "snam": "Departure 2",
                "trip_id": 554303,
                "lineColor": "424",
                "dem": false,
                "lcod": "424",
                "etn": "Cala Rajada",
                "dtn": null,
                "et": "1970-01-01T12:45:00"
              }
            ]),
            200);
      });

      Departures.httpClient = mockHttpClient;

      final departures = await Departures.getDepartures(
          stationCode: 123, numberOfDepartures: 2);

      expect(departures, isA<List<Departure>>());
      expect(departures.length, 2);
      expect(departures[0].name, 'Departure 1');
    });

    test('throws FormatException when the station code is invalid', () async {
      final mockHttpClient = MockClient((request) async {
        throw FormatException("Invalid format");
      });

      Departures.httpClient = mockHttpClient;

      expect(
          () async => await Departures.getDepartures(
              stationCode: 123, numberOfDepartures: 2),
          throwsA(isA<FormatException>()));
    });

    test('throws Exception when there are no departures found', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response('[]', 200);
      });

      Departures.httpClient = mockHttpClient;

      expect(
          () async => await Departures.getDepartures(
              stationCode: 123, numberOfDepartures: 2),
          throwsA(isA<Exception>()));
    });
  });

  group('RealTrip', () {
    test('fromJson creates a RealTrip object from JSON', () {
      final jsonMap = {
        'aet': '2024-05-24T08:30:00Z',
        'lastCoords': {'lat': 40.712776, 'lng': -74.005974},
        'id': '1'
      };

      final realTrip = RealTrip.fromJson(jsonMap);

      expect(realTrip.estimatedArrival, DateTime.parse('2024-05-24T08:30:00Z'));
      expect(realTrip.lat, 40.712776);
      expect(realTrip.long, -74.005974);
      expect(realTrip.id, 1);
    });

    test('fromJson handles null estimatedArrival', () {
      final jsonMap = {
        'aet': null,
        'lastCoords': {'lat': 40.712776, 'lng': -74.005974},
        'id': '2'
      };

      final realTrip = RealTrip.fromJson(jsonMap);

      expect(realTrip.estimatedArrival, isNull);
      expect(realTrip.lat, 40.712776);
      expect(realTrip.long, -74.005974);
      expect(realTrip.id, 2);
    });

    test('toJson converts a RealTrip object back to JSON', () {
      final realTrip = RealTrip(
          estimatedArrival: DateTime.parse('2024-05-24T08:30:00Z'),
          lat: 40.712776,
          long: -74.005974,
          id: 1);

      final jsonString = RealTrip.toJson(realTrip);
      final jsonMap = jsonDecode(jsonString);

      expect(jsonMap['aet'], '2024-05-24T08:30:00.000Z');
      expect(jsonMap['lastCoords']['lat'], 40.712776);
      expect(jsonMap['lastCoords']['lng'], -74.005974);
      expect(jsonMap['id'], 1);
    });

    test('toJson handles null estimatedArrival', () {
      final realTrip = RealTrip(
          estimatedArrival: null, lat: 40.712776, long: -74.005974, id: 2);

      final jsonString = RealTrip.toJson(realTrip);
      final jsonMap = jsonDecode(jsonString);

      expect(jsonMap['aet'], null);
      expect(jsonMap['lastCoords']['lat'], 40.712776);
      expect(jsonMap['lastCoords']['lng'], -74.005974);
      expect(jsonMap['id'], 2);
    });
  });

  group('Departure', () {
    test('fromJson creates a Departure object from JSON', () {
      final jsonMap = {
        'dt': '2024-05-24T08:30:00Z',
        'aet': '2024-05-24T09:00:00Z',
        'snam': 'Bus 42',
        'trip_id': 1,
        'realTrip': {
          'aet': '2024-05-24T09:00:00Z',
          'lastCoords': {'lat': 40.712776, 'lng': -74.005974},
          'id': '1'
        },
        'dem': true,
        'lcod': 'B42',
        'etn': 'Central Station',
        'et': 'Main Street'
      };

      final departure = Departure.fromJson(jsonMap);

      expect(departure.departureTime, DateTime.parse('2024-05-24T08:30:00Z'));
      expect(
          departure.estimatedArrival, DateTime.parse('2024-05-24T09:00:00Z'));
      expect(departure.name, 'Bus 42');
      expect(departure.tripId, 1);
      expect(departure.realTrip, isA<RealTrip>());
      expect(departure.delayed, true);
      expect(departure.lineCode, 'B42');
      expect(departure.destination, 'Central Station');
      expect(departure.departureStop, 'Main Street');
    });

    test('fromJson handles null optional fields', () {
      final jsonMap = {
        'dt': '2024-05-24T08:30:00Z',
        'aet': '2024-05-24T09:00:00Z',
        'snam': 'Bus 42',
        'trip_id': 1,
        'realTrip': null,
        'dem': false,
        'lcod': 'B42',
        'etn': null,
        'et': null
      };

      final departure = Departure.fromJson(jsonMap);

      expect(departure.departureTime, DateTime.parse('2024-05-24T08:30:00Z'));
      expect(
          departure.estimatedArrival, DateTime.parse('2024-05-24T09:00:00Z'));
      expect(departure.name, 'Bus 42');
      expect(departure.tripId, 1);
      expect(departure.realTrip, isNull);
      expect(departure.delayed, false);
      expect(departure.lineCode, 'B42');
      expect(departure.destination, isNull);
      expect(departure.departureStop, isNull);
    });

    test('toJson converts a Departure object to JSON', () {
      final realTrip = RealTrip(
          estimatedArrival: DateTime.parse('2024-05-24T09:00:00Z'),
          lat: 40.712776,
          long: -74.005974,
          id: 1);
      final departure = Departure(
          departureTime: DateTime.parse('2024-05-24T08:30:00Z'),
          estimatedArrival: DateTime.parse('2024-05-24T09:00:00Z'),
          name: 'Bus 42',
          tripId: 1,
          realTrip: realTrip,
          delayed: true,
          lineCode: 'B42',
          destination: 'Central Station',
          departureStop: 'Main Street');

      final jsonMap = Departure.toJson(departure);

      expect(jsonMap['dt'], '2024-05-24T08:30:00.000Z');
      expect(jsonMap['aet'], '2024-05-24T09:00:00.000Z');
      expect(jsonMap['snam'], 'Bus 42');
      expect(jsonMap['trip_id'], 1);
      expect(jsonMap['realTrip'], isA<String>());
      expect(
          jsonDecode(jsonMap['realTrip'])['aet'], '2024-05-24T09:00:00.000Z');
      expect(jsonMap['dem'], true);
      expect(jsonMap['lcod'], 'B42');
      expect(jsonMap['etn'], 'Central Station');
      expect(jsonMap['et'], 'Main Street');
    });

    test('toJson handles null optional fields', () {
      final departure = Departure(
          departureTime: DateTime.parse('2024-05-24T08:30:00Z'),
          estimatedArrival: DateTime.parse('2024-05-24T09:00:00Z'),
          name: 'Bus 42',
          tripId: 1,
          realTrip: null,
          delayed: false,
          lineCode: 'B42',
          destination: null,
          departureStop: null);

      final jsonMap = Departure.toJson(departure);

      expect(jsonMap['dt'], '2024-05-24T08:30:00.000Z');
      expect(jsonMap['aet'], '2024-05-24T09:00:00.000Z');
      expect(jsonMap['snam'], 'Bus 42');
      expect(jsonMap['trip_id'], 1);
      expect(jsonMap['realTrip'], isNull);
      expect(jsonMap['dem'], false);
      expect(jsonMap['lcod'], 'B42');
      expect(jsonMap['etn'], isNull);
      expect(jsonMap['et'], isNull);
    });
  });
}
