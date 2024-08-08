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
  });
}
