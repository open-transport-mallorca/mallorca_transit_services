import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:mallorca_transit_services/mallorca_transit_services.dart';

void main() {
  group('Station', () {
    // Test fromJson and toJson methods
    test('fromJson and toJson should work correctly', () {
      final stationJson = {
        'cod': '123',
        'id': 456,
        'lat': 37.7749,
        'lon': -122.4194,
        'nam': 'Sample Station',
        'ref': 'Reference'
      };

      final station = Station.fromJson(stationJson);
      expect(station.code, '123');
      expect(station.id, 456);
      expect(station.lat, 37.7749);
      expect(station.long, -122.4194);
      expect(station.name, 'Sample Station');
      expect(station.ref, 'Reference');
      expect(station.pickupType, isNull);
      expect(station.dropoffType, isNull);
      expect(station.town, isNull);

      final json = Station.toJson(station);
      expect(json, {
        ...stationJson,
        'pickupType': null,
        'dropoffType': null,
        'parent': null
      });
    });

    // Test town parsing (comes from the 'parent' key)
    test('fromJson and toJson should map town to the parent key', () {
      final stationJson = {
        'cod': '51031',
        'id': 1821,
        'lat': 39.5867,
        'lon': 3.375763,
        'nam': 'Mare Selva 2',
        'ref': null,
        'pickupType': null,
        'dropoffType': null,
        'parent': 'sa Coma'
      };

      final station = Station.fromJson(stationJson);
      expect(station.town, 'sa Coma');

      expect(Station.toJson(station), stationJson);
      expect(station.toString(), contains('town: sa Coma'));
    });

    // Test pickup/drop-off type parsing (present on line/subline stops only)
    test('fromJson parses pickupType/dropoffType and derived getters', () {
      final dischargeOnly = Station.fromJson({
        'cod': '51031',
        'id': 1821,
        'lat': 39.5867,
        'lon': 3.375763,
        'nam': 'Mare Selva 2',
        'parent': 'sa Coma',
        'pickupType': 1,
        'dropoffType': 0
      });
      expect(dischargeOnly.town, 'sa Coma');
      expect(dischargeOnly.pickupType, 1);
      expect(dischargeOnly.dropoffType, 0);
      expect(dischargeOnly.isDischargeOnly, isTrue);
      expect(dischargeOnly.isPickupOnly, isFalse);

      // Pickup-only stop: pickup allowed, no drop-off
      final pickupOnly = Station.fromJson({
        'cod': '123',
        'id': 1,
        'lat': 0.0,
        'lon': 0.0,
        'nam': 'Pickup Only',
        'pickupType': 0,
        'dropoffType': 1
      });
      expect(pickupOnly.isPickupOnly, isTrue);
      expect(pickupOnly.isDischargeOnly, isFalse);

      // Normal stop with the fields omitted
      final normal = Station.fromJson(
          {'cod': '456', 'id': 2, 'lat': 0.0, 'lon': 0.0, 'nam': 'Normal'});
      expect(normal.pickupType, isNull);
      expect(normal.dropoffType, isNull);
      expect(normal.town, isNull);
      expect(normal.isDischargeOnly, isFalse);
      expect(normal.isPickupOnly, isFalse);
    });

    // Test getLines method for successful response
    test('getLines should return a list of RouteLines for a valid station code',
        () async {
      final mockClient = MockClient((request) async {
        final linesResponse = jsonEncode({
          'lines': [
            {'cod': '1'},
            {'cod': '2'}
          ]
        });

        return http.Response(linesResponse, 200);
      });

      final mockRouteLineClient = MockClient((request) async {
        final routeLineResponse = jsonEncode({
          'act': true,
          'cod': '1',
          'id': 1,
          'nam': 'Route Line 1',
          'color': '#FFFFFF',
          'typ': 1,
        });

        return http.Response(routeLineResponse, 200);
      });

      RouteLinesApi.httpClient = mockRouteLineClient;
      StationsApi.httpClient = mockClient;

      final lines = await StationsApi.getLines('123');
      expect(lines.length, 2);
      expect(lines[0].name, 'Route Line 1');
    });

    // Test getLines method for invalid station code
    test('getLines should throw FormatException for invalid station code',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response('Invalid station code', 400);
      });

      StationsApi.httpClient = mockClient;

      expect(
        () async => await StationsApi.getLines('999'),
        throwsA(isA<FormatException>()),
      );
    });

    // Test fromId method for successful response
    test('fromId should return a Station for a valid id', () async {
      final mockClient = MockClient((request) async {
        final stationResponse = jsonEncode({
          'cod': '123',
          'id': 456,
          'lat': 37.7749,
          'lon': -122.4194,
          'nam': 'Sample Station',
          'ref': 'Reference',
          'parent': 'Palma'
        });

        return http.Response(stationResponse, 200);
      });

      StationsApi.httpClient = mockClient;

      final station = await StationsApi.fromId(456);
      expect(station.code, '123');
      expect(station.id, 456);
      expect(station.lat, 37.7749);
      expect(station.long, -122.4194);
      expect(station.name, 'Sample Station');
      expect(station.ref, 'Reference');
      expect(station.town, 'Palma');
    });

    // Test fromId method for invalid id
    test('fromId should throw an exception for invalid id', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Station not found', 404);
      });

      StationsApi.httpClient = mockClient;

      expect(
        () async => await StationsApi.fromId(999),
        throwsA(isA<Exception>()),
      );
    });

    // Test getAllStations method for successful response
    test('getAllStations should return a list of Stations', () async {
      final mockClient = MockClient((request) async {
        final stationsResponse = jsonEncode({
          'stopsInfo': [
            {
              'cod': '123',
              'id': 456,
              'lat': 37.7749,
              'lon': -122.4194,
              'nam': 'Station 1',
              'ref': 'Ref 1'
            },
            {
              'cod': '789',
              'id': 101,
              'lat': 37.7750,
              'lon': -122.4195,
              'nam': 'Station 2',
              'ref': 'Ref 2'
            }
          ]
        });

        return http.Response(stationsResponse, 200);
      });

      StationsApi.httpClient = mockClient;

      final stations = await StationsApi.getAllStations(count: 2);
      expect(stations.length, 2);
      expect(stations[0].name, 'Station 1');
      expect(stations[1].name, 'Station 2');
    });

    // Test getAllStations method for a failure scenario
    test('getAllStations should throw an exception on failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Error fetching stations', 500);
      });

      StationsApi.httpClient = mockClient;

      expect(
        () async => await StationsApi.getAllStations(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
