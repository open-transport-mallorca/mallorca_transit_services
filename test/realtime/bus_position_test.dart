import 'package:test/test.dart';
import 'package:mallorca_transit_services/mallorca_transit_services.dart';

void main() {
  group('BusPosition', () {
    test('fromJson should correctly parse JSON data', () {
      final json = {
        'lat': 42.1234, // Sample latitude
        'lng': -71.5678, // Sample longitude
        'vel': 35.5, // Sample speed
        'upd': '2024-05-25T08:30:00Z' // Sample timestamp
      };

      final busPosition = BusPosition.fromJson(json);

      // Test attributes
      expect(busPosition.lat, 42.1234);
      expect(busPosition.long, -71.5678);
      expect(busPosition.speed, 35.5);
      expect(busPosition.timestamp.year, 2024);
      expect(busPosition.timestamp.month, 5);
      expect(busPosition.timestamp.day, 25);
      expect(busPosition.timestamp.hour, 8);
      expect(busPosition.timestamp.minute, 30);
    });

    // Live payload shape
    test('fromJson parses tripId and recordedAt from a live position message',
        () {
      final busPosition = BusPosition.fromJson({
        'type': 'position',
        'rt_id': 9795766,
        'upd': '20260720 184104',
        'date': '20260720 184103',
        'lat': 39.5741,
        'lng': 3.2015,
        'vel': 15.37
      });

      expect(busPosition.tripId, 9795766);
      expect(busPosition.timestamp, DateTime(2026, 7, 20, 18, 41, 4));
      expect(busPosition.recordedAt, DateTime(2026, 7, 20, 18, 41, 3));
      expect(busPosition.lat, 39.5741);
      expect(busPosition.long, 3.2015);
      expect(busPosition.speed, 15.37);
    });

    test('fromJson reads null for absent tripId and recordedAt', () {
      final busPosition = BusPosition.fromJson({
        'lat': 42.1234,
        'lng': -71.5678,
        'vel': 35.5,
        'upd': '2024-05-25T08:30:00Z'
      });

      expect(busPosition.tripId, isNull);
      expect(busPosition.recordedAt, isNull);
    });

    test('fromJson reads the esta-info pos object via timestampKey', () {
      final busPosition = BusPosition.fromJson({
        'lat': 39.5727,
        'lng': 3.1969,
        'vel': 48.33,
        'time': '20260720 184148'
      }, timestampKey: 'time', tripId: 9795766);

      expect(busPosition.tripId, 9795766);
      expect(busPosition.timestamp, DateTime(2026, 7, 20, 18, 41, 48));
      expect(busPosition.recordedAt, isNull);
      expect(busPosition.speed, 48.33);
    });

    test('fromJson coerces integer lat, lng and vel', () {
      final busPosition = BusPosition.fromJson(
          {'lat': 39, 'lng': 3, 'vel': 0, 'upd': '20260720 184104'});

      expect(busPosition.lat, 39.0);
      expect(busPosition.long, 3.0);
      expect(busPosition.speed, 0.0);
    });
  });
}
