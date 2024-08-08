import 'package:test/test.dart';
import 'package:mallorca_transit_services/mallorca_transit_services.dart';

void main() {
  group('RouteStationInfo', () {
    test('fromJson should correctly parse JSON data with multiple stops', () {
      final json = {
        'bus': {'pas': 10, 'cap': 50}, // Sample passengers JSON data
        'stops': [
          {
            'stop_id': 1,
            'stop_nam': 'Station A',
            'arr_t': '0830', // Scheduled arrival time in HHMM format
            'esta_dist': 2.5, // Estimated distance
            'esta_time': '2024-05-25T08:35:00Z' // Estimated arrival time
          },
          {
            'stop_id': 2,
            'stop_nam': 'Station B',
            'arr_t': '0900', // Scheduled arrival time in HHMM format
            'esta_dist': 4.2, // Estimated distance
            'esta_time': '2024-05-25T09:05:00Z' // Estimated arrival time
          },
        ]
      };

      final routeStationInfo = RouteStationInfo.fromJson(json);

      // Test passengers
      expect(routeStationInfo.passangers.inBus, 10);
      expect(routeStationInfo.passangers.totalCapacity, 50);

      // Test stops
      expect(routeStationInfo.stops.length, 2);
      final stationOnRoute1 = routeStationInfo.stops[0];
      expect(stationOnRoute1.stopId, 1);
      expect(stationOnRoute1.stopName, 'Station A');
      expect(stationOnRoute1.scheduledArrival.hour, 8);
      expect(stationOnRoute1.scheduledArrival.minute, 30);
      expect(stationOnRoute1.estimatedDistance, 2.5);
      expect(stationOnRoute1.estimatedArrival.year, 2024);
      expect(stationOnRoute1.estimatedArrival.month, 5);
      expect(stationOnRoute1.estimatedArrival.day, 25);
      expect(stationOnRoute1.estimatedArrival.hour, 8);
      expect(stationOnRoute1.estimatedArrival.minute, 35);

      final stationOnRoute2 = routeStationInfo.stops[1];
      expect(stationOnRoute2.stopId, 2);
      expect(stationOnRoute2.stopName, 'Station B');
      expect(stationOnRoute2.scheduledArrival.hour, 9);
      expect(stationOnRoute2.scheduledArrival.minute, 0);
      expect(stationOnRoute2.estimatedDistance, 4.2);
      expect(stationOnRoute2.estimatedArrival.year, 2024);
      expect(stationOnRoute2.estimatedArrival.month, 5);
      expect(stationOnRoute2.estimatedArrival.day, 25);
      expect(stationOnRoute2.estimatedArrival.hour, 9);
      expect(stationOnRoute2.estimatedArrival.minute, 5);
    });

    test('fromJson should handle empty stops array', () {
      final json = {
        'bus': {'pas': 10, 'cap': 50}, // Sample passengers JSON data
        'stops': [] // Empty stops array
      };

      final routeStationInfo = RouteStationInfo.fromJson(json);

      // Test passengers
      expect(routeStationInfo.passangers.inBus, 10);
      expect(routeStationInfo.passangers.totalCapacity, 50);

      // Test stops
      expect(routeStationInfo.stops, isEmpty);
    });
  });

  group('StationOnRoute', () {
    test('fromJson should correctly parse JSON data', () {
      final json = {
        'stop_id': 1,
        'stop_nam': 'Station A',
        'arr_t': '0830', // Scheduled arrival time in HHMM format
        'esta_dist': 2.5, // Estimated distance
        'esta_time': '2024-05-25T08:35:00Z' // Estimated arrival time
      };

      final stationOnRoute = StationOnRoute.fromJson(json);

      expect(stationOnRoute.stopId, 1);
      expect(stationOnRoute.stopName, 'Station A');
      expect(stationOnRoute.scheduledArrival.hour, 8);
      expect(stationOnRoute.scheduledArrival.minute, 30);
      expect(stationOnRoute.estimatedDistance, 2.5);
      expect(stationOnRoute.estimatedArrival.year, 2024);
      expect(stationOnRoute.estimatedArrival.month, 5);
      expect(stationOnRoute.estimatedArrival.day, 25);
      expect(stationOnRoute.estimatedArrival.hour, 8);
      expect(stationOnRoute.estimatedArrival.minute, 35);
    });
  });
}
