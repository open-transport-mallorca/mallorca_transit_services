import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mallorca_transit_services/mallorca_transit_services.dart';

void main() {
  group('DeparturesApi.getDepartures', () {
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

      DeparturesApi.httpClient = mockHttpClient;

      final departures = await DeparturesApi.getDepartures(
          stationCode: "123", numberOfDepartures: 2);

      expect(departures, isA<List<Departure>>());
      expect(departures.length, 2);
      expect(departures[0].name, 'Departure 1');
    });

    test('throws FormatException when the station code is invalid', () async {
      final mockHttpClient = MockClient((request) async {
        throw FormatException("Invalid format");
      });

      DeparturesApi.httpClient = mockHttpClient;

      expect(
          () async => await DeparturesApi.getDepartures(
              stationCode: "123", numberOfDepartures: 2),
          throwsA(isA<FormatException>()));
    });

    test('throws Exception when there are no departures found', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response('[]', 200);
      });

      DeparturesApi.httpClient = mockHttpClient;

      expect(
          () async => await DeparturesApi.getDepartures(
              stationCode: "123", numberOfDepartures: 2),
          throwsA(isA<Exception>()));
    });
  });

  group('RealTrip', () {
    test('fromJson creates a RealTrip object from JSON', () {
      final jsonMap = {
        'aet': '2024-05-24T08:30:00Z',
        'lastCoords': {'lat': 40.712776, 'lng': -74.005974},
        'id': '1',
        'bus': {'passengers': 10, 'placesSeated': 20, 'placesStanding': 30}
      };

      final realTrip = RealTrip.fromJson(jsonMap);

      expect(realTrip.estimatedArrival, DateTime.parse('2024-05-24T08:30:00Z'));
      expect(realTrip.lat, 40.712776);
      expect(realTrip.long, -74.005974);
      expect(realTrip.id, 1);
      expect(realTrip.stats?.passengers, 10);
      expect(realTrip.stats?.placesToSit, 20);
      expect(realTrip.stats?.placesToStand, 30);
    });

    test('fromJson handles null estimatedArrival', () {
      final jsonMap = {
        'aet': null,
        'lastCoords': {'lat': 40.712776, 'lng': -74.005974},
        'id': '2',
        'bus': {'passengers': 10, 'placesSeated': 20, 'placesStanding': 30}
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
          id: 1,
          stats: RealTripBusStats(
              passengers: 10, placesToSit: 20, placesToStand: 30));

      final jsonString = RealTrip.toJson(realTrip);
      final jsonMap = jsonDecode(jsonString);

      expect(jsonMap['aet'], '2024-05-24T08:30:00.000Z');
      expect(jsonMap['lastCoords']['lat'], 40.712776);
      expect(jsonMap['lastCoords']['lng'], -74.005974);
      expect(jsonMap['id'], 1);
      expect(jsonMap['bus']['passengers'], 10);
      expect(jsonMap['bus']['placesSeated'], 20);
      expect(jsonMap['bus']['placesStanding'], 30);
    });

    test('toJson handles null estimatedArrival', () {
      final realTrip = RealTrip(
          estimatedArrival: null,
          lat: 40.712776,
          long: -74.005974,
          id: 2,
          stats: RealTripBusStats(
              passengers: 10, placesToSit: 20, placesToStand: 30));

      final jsonString = RealTrip.toJson(realTrip);
      final jsonMap = jsonDecode(jsonString);

      expect(jsonMap['aet'], null);
      expect(jsonMap['lastCoords']['lat'], 40.712776);
      expect(jsonMap['lastCoords']['lng'], -74.005974);
      expect(jsonMap['id'], 2);
      expect(jsonMap['bus']['passengers'], 10);
      expect(jsonMap['bus']['placesSeated'], 20);
      expect(jsonMap['bus']['placesStanding'], 30);
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
          'id': '1',
          'bus': {'passengers': 10, 'placesSeated': 20, 'placesStanding': 30}
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
      expect(departure.realTrip!.estimatedArrival,
          DateTime.parse('2024-05-24T09:00:00Z'));
      expect(departure.realTrip!.lat, 40.712776);
      expect(departure.realTrip!.long, -74.005974);
      expect(departure.realTrip!.id, 1);
      expect(departure.realTrip!.stats?.passengers, 10);
      expect(departure.realTrip!.stats?.placesToSit, 20);
      expect(departure.realTrip!.stats?.placesToStand, 30);
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
          id: 1,
          stats: RealTripBusStats(
              passengers: 10, placesToSit: 20, placesToStand: 30));
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

    // Live payload shape
    test('fromJson parses lineColor, originStop and endTime', () {
      final departure = Departure.fromJson({
        'dt': '1970-01-01T18:40:00',
        'et': '1970-01-01T19:25:00',
        'etn': 'Campos',
        'dtn': 'Palma',
        'aet': '2026-07-20T18:40:00',
        'lcod': 'A51',
        'trip_id': 659865,
        'snam': 'A51',
        'dem': false,
        'lineColor': '#28689D'
      });

      expect(departure.lineColor, '#28689D');
      expect(departure.lineColorValue, 0xFF28689D);
      expect(departure.originStop, 'Palma');
      expect(departure.endTime, DateTime.parse('1970-01-01T19:25:00'));
      expect(departure.destination, 'Campos');
      // The deprecated field keeps its old (misparsed) behaviour.
      expect(departure.departureStop, '1970-01-01T19:25:00');
    });

    test('fromJson reads null for absent lineColor, originStop and endTime',
        () {
      final departure = Departure.fromJson({
        'dt': '1970-01-01T18:40:00',
        'aet': '2026-07-20T18:40:00',
        'snam': 'A51',
        'trip_id': 659865,
        'dem': false,
        'lcod': 'A51',
      });

      expect(departure.lineColor, isNull);
      expect(departure.lineColorValue, isNull);
      expect(departure.originStop, isNull);
      expect(departure.endTime, isNull);
      expect(departure.departureStop, isNull);
    });

    test('lineColorValue returns null for a non-hex lineColor', () {
      final departure = Departure.fromJson({
        'dt': '1970-01-01T18:40:00',
        'aet': '2026-07-20T18:40:00',
        'snam': 'A51',
        'trip_id': 659865,
        'dem': false,
        'lcod': 'A51',
        'lineColor': '401'
      });

      expect(departure.lineColor, '401');
      expect(departure.lineColorValue, isNull);
    });

    test('toJson writes lineColor, originStop and endTime', () {
      final departure = Departure(
          departureTime: DateTime.parse('1970-01-01T18:40:00'),
          estimatedArrival: DateTime.parse('2026-07-20T18:40:00'),
          name: 'A51',
          tripId: 659865,
          delayed: false,
          lineCode: 'A51',
          destination: 'Campos',
          lineColor: '#28689D',
          originStop: 'Palma',
          endTime: DateTime.parse('1970-01-01T19:25:00'));

      final jsonMap = Departure.toJson(departure);

      expect(jsonMap['lineColor'], '#28689D');
      expect(jsonMap['dtn'], 'Palma');
      expect(jsonMap['et'], '1970-01-01T19:25:00.000');
    });

    test('toJson falls back to departureStop when endTime is unset', () {
      final departure = Departure(
          departureTime: DateTime.parse('2024-05-24T08:30:00Z'),
          estimatedArrival: DateTime.parse('2024-05-24T09:00:00Z'),
          name: 'Bus 42',
          tripId: 1,
          delayed: false,
          lineCode: 'B42',
          departureStop: 'Main Street');

      expect(Departure.toJson(departure)['et'], 'Main Street');
    });

    test('fromJson(toJson(x)) preserves every field', () {
      final original = Departure.fromJson({
        'dt': '1970-01-01T18:40:00.000',
        'et': '1970-01-01T19:25:00.000',
        'etn': 'Campos',
        'dtn': 'Palma',
        'aet': '2026-07-20T18:40:00.000',
        'lcod': 'A51',
        'trip_id': 659865,
        'snam': 'A51',
        'dem': true,
        'lineColor': '#28689D',
        'realTrip': {
          'aet': '2026-07-20T18:45:00.000Z',
          'lastCoords': {'lat': 39.5741, 'lng': 3.2015},
          'id': '9795766',
          'bus': {'passengers': 37, 'placesSeated': 50, 'placesStanding': 44}
        }
      });

      final roundTripped = Departure.fromJson(Departure.toJson(original));

      expect(roundTripped.departureTime, original.departureTime);
      expect(roundTripped.estimatedArrival, original.estimatedArrival);
      expect(roundTripped.name, original.name);
      expect(roundTripped.tripId, original.tripId);
      expect(roundTripped.delayed, original.delayed);
      expect(roundTripped.lineCode, original.lineCode);
      expect(roundTripped.destination, original.destination);
      expect(roundTripped.lineColor, original.lineColor);
      expect(roundTripped.originStop, original.originStop);
      expect(roundTripped.endTime, original.endTime);
      expect(roundTripped.departureStop, original.departureStop);
      expect(roundTripped.realTrip!.id, original.realTrip!.id);
      expect(roundTripped.realTrip!.lat, original.realTrip!.lat);
      expect(roundTripped.realTrip!.long, original.realTrip!.long);
      expect(roundTripped.realTrip!.estimatedArrival,
          original.realTrip!.estimatedArrival);
      expect(roundTripped.realTrip!.stats!.passengers,
          original.realTrip!.stats!.passengers);
      expect(roundTripped.toString(), original.toString());
    });
  });
}
