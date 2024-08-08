import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:mallorca_transit_services/src/api/route_line.dart';
import 'package:mallorca_transit_services/src/api/stations.dart';

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
      expect(station.code, 123);
      expect(station.id, 456);
      expect(station.lat, 37.7749);
      expect(station.long, -122.4194);
      expect(station.name, 'Sample Station');
      expect(station.ref, 'Reference');

      final json = Station.toJson(station);
      expect(json, stationJson);
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

      RouteLine.httpClient = mockRouteLineClient;
      Station.httpClient = mockClient;

      final lines = await Station.getLines(123);
      expect(lines.length, 2);
      expect(lines[0].name, 'Route Line 1');
    });

    // Test getLines method for invalid station code
    test('getLines should throw FormatException for invalid station code',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response('Invalid station code', 400);
      });

      Station.httpClient = mockClient;

      expect(
        () async => await Station.getLines(999),
        throwsA(isA<FormatException>()),
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

      Station.httpClient = mockClient;

      final stations = await Station.getAllStations(count: 2);
      expect(stations.length, 2);
      expect(stations[0].name, 'Station 1');
      expect(stations[1].name, 'Station 2');
    });

    // Test getAllStations method for a failure scenario
    test('getAllStations should throw an exception on failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Error fetching stations', 500);
      });

      Station.httpClient = mockClient;

      expect(
        () async => await Station.getAllStations(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
