import 'package:test/test.dart';
import 'package:mallorca_transit_services/mallorca_transit_services.dart';

void main() {
  group('RouteStationInfo', () {
    test('fromJson should correctly parse JSON data with multiple stops', () {
      final json = {
        'bus': {
          'pas': 10,
          'cap': 50,
          'cap_seated': 30,
          'cap_standing': 20
        }, // Sample passengers JSON data
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
      expect(routeStationInfo.passangers.seatedCapacity, 30);
      expect(routeStationInfo.passangers.standingCapacity, 20);

      // Test stops
      expect(routeStationInfo.stops.length, 2);
      final stationOnRoute1 = routeStationInfo.stops[0];
      expect(stationOnRoute1.stopId, 1);
      expect(stationOnRoute1.stopName, 'Station A');
      expect(stationOnRoute1.scheduledArrival.hour, 8);
      expect(stationOnRoute1.scheduledArrival.minute, 30);
      expect(stationOnRoute1.estimatedDistance, 2.5);
      expect(stationOnRoute1.estimatedArrival?.year, 2024);
      expect(stationOnRoute1.estimatedArrival?.month, 5);
      expect(stationOnRoute1.estimatedArrival?.day, 25);
      expect(stationOnRoute1.estimatedArrival?.hour, 8);
      expect(stationOnRoute1.estimatedArrival?.minute, 35);

      final stationOnRoute2 = routeStationInfo.stops[1];
      expect(stationOnRoute2.stopId, 2);
      expect(stationOnRoute2.stopName, 'Station B');
      expect(stationOnRoute2.scheduledArrival.hour, 9);
      expect(stationOnRoute2.scheduledArrival.minute, 0);
      expect(stationOnRoute2.estimatedDistance, 4.2);
      expect(stationOnRoute2.estimatedArrival?.year, 2024);
      expect(stationOnRoute2.estimatedArrival?.month, 5);
      expect(stationOnRoute2.estimatedArrival?.day, 25);
      expect(stationOnRoute2.estimatedArrival?.hour, 9);
      expect(stationOnRoute2.estimatedArrival?.minute, 5);
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

    test('fromJson should handle missing seated & standing capacity', () {
      final json = {
        'bus': {
          'pas': 10,
          'cap': 50,
        }, // Sample passengers JSON data
        'stops': [
          {
            'stop_id': 1,
            'stop_nam': 'Station A',
            'arr_t': '0830',
            'esta_dist': 2.5,
            'esta_time': '2024-05-25T08:35:00Z'
          },
        ]
      };

      final routeStationInfo = RouteStationInfo.fromJson(json);

      // Test passengers
      expect(routeStationInfo.passangers.inBus, 10); // Default value
      expect(routeStationInfo.passangers.totalCapacity, 50); // Default value
      expect(routeStationInfo.passangers.seatedCapacity, null); // Default value
      expect(
          routeStationInfo.passangers.standingCapacity, null); // Default value

      // Test stops
      expect(routeStationInfo.stops.length, 1);
      final stationOnRoute = routeStationInfo.stops[0];
      expect(stationOnRoute.stopId, 1);
      expect(stationOnRoute.stopName, 'Station A');
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
      expect(stationOnRoute.estimatedArrival?.year, 2024);
      expect(stationOnRoute.estimatedArrival?.month, 5);
      expect(stationOnRoute.estimatedArrival?.day, 25);
      expect(stationOnRoute.estimatedArrival?.hour, 8);
      expect(stationOnRoute.estimatedArrival?.minute, 35);
    });

    test('fromJson parses stopCode', () {
      final stationOnRoute = StationOnRoute.fromJson({
        'stop_id': 1740,
        'stop_code': '65002',
        'stop_nam': 'Vilafranca 1',
        'arr_t': '184500',
        'esta_time': '20260720 184920'
      });

      expect(stationOnRoute.stopId, 1740);
      expect(stationOnRoute.stopCode, '65002');
      expect(stationOnRoute.scheduledArrival.hour, 18);
      expect(stationOnRoute.scheduledArrival.minute, 45);
      expect(
          stationOnRoute.estimatedArrival, DateTime(2026, 7, 20, 18, 49, 20));
      // Absent from every captured live payload
      expect(stationOnRoute.estimatedDistance, isNull);
    });

    test('fromJson reads null for an absent stopCode', () {
      final stationOnRoute = StationOnRoute.fromJson(
          {'stop_id': 1, 'stop_nam': 'Station A', 'arr_t': '0830'});

      expect(stationOnRoute.stopCode, isNull);
    });
  });

  group('RouteStationInfo tripId & position', () {
    // Live payload shape
    final liveJson = {
      'type': 'esta-info',
      'rt_id': 9795766,
      'pos': {
        'lat': 39.5727,
        'lng': 3.1969,
        'vel': 48.33,
        'time': '20260720 184148'
      },
      'bus': {'pas': 37, 'cap': 50, 'cap_seated': 50, 'cap_standing': 44},
      'stops': [
        {
          'stop_id': 1740,
          'stop_code': '65002',
          'stop_nam': 'Vilafranca 1',
          'arr_t': '184500',
          'esta_time': '20260720 184920'
        }
      ]
    };

    test('fromJson parses tripId and the embedded position', () {
      final info = RouteStationInfo.fromJson(liveJson);

      expect(info.tripId, 9795766);
      expect(info.position, isNotNull);
      expect(info.position!.lat, 39.5727);
      expect(info.position!.long, 3.1969);
      expect(info.position!.speed, 48.33);
      expect(info.position!.timestamp, DateTime(2026, 7, 20, 18, 41, 48));
      expect(info.position!.recordedAt, isNull);
      // Taken from the enclosing message
      expect(info.position!.tripId, 9795766);

      expect(info.stops.single.stopCode, '65002');
      expect(info.passangers.inBus, 37);
    });

    test('fromJson reads null for an absent tripId and position', () {
      final info = RouteStationInfo.fromJson({
        'bus': {'pas': 10, 'cap': 50},
        'stops': []
      });

      expect(info.tripId, isNull);
      expect(info.position, isNull);
    });
  });

  test('fromJson should handle missing optional fields', () {
    final json = {
      'stop_id': 1,
      'stop_nam': 'Station A',
      'arr_t': '0830' // Scheduled arrival time in HHMM format
      // Missing estimated distance and estimated arrival time
    };

    final stationOnRoute = StationOnRoute.fromJson(json);

    expect(stationOnRoute.stopId, 1);
    expect(stationOnRoute.stopName, 'Station A');
    expect(stationOnRoute.scheduledArrival.hour, 8);
    expect(stationOnRoute.scheduledArrival.minute, 30);
    expect(stationOnRoute.estimatedDistance, isNull);
    expect(stationOnRoute.estimatedArrival, isNull);
  });
}
