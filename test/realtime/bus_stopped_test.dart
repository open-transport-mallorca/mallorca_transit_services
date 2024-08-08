import 'package:test/test.dart';
import 'package:mallorca_transit_services/mallorca_transit_services.dart';

void main() {
  group('BusStopped', () {
    test('fromJson should correctly parse JSON data', () {
      final json = {
        'upd': '2024-05-25T08:30:00Z', // Sample timestamp
        'lat': 42.1234, // Sample latitude
        'lng': -71.5678, // Sample longitude
        'vel': 35.5, // Sample speed
        'del': 5, // Sample delay
        'pass': 20, // Sample passengers
        'stop_nam': 'Sample Stop', // Sample stop name
        'arr_t': '0830', // Sample scheduled time (HHmm format)
        'arr_rt': '2024-05-25T08:32:00Z', // Sample actual time
        'stp_rt': '2024-05-25T08:33:00Z', // Sample stop time
        'dep_rt': '2024-05-25T08:35:00Z' // Sample leave time
      };

      final busStopped = BusStopped.fromJson(json);

      // Test attributes
      expect(busStopped.timestamp.year, 2024);
      expect(busStopped.timestamp.month, 5);
      expect(busStopped.timestamp.day, 25);
      expect(busStopped.timestamp.hour, 8);
      expect(busStopped.timestamp.minute, 30);
      expect(busStopped.lat, 42.1234);
      expect(busStopped.long, -71.5678);
      expect(busStopped.speed, 35.5);
      expect(busStopped.delay, 5);
      expect(busStopped.passangers, 20);
      expect(busStopped.stopName, 'Sample Stop');
      expect(busStopped.scheduledTime.hour, 8);
      expect(busStopped.scheduledTime.minute, 30);
      expect(busStopped.actualTime.year, 2024);
      expect(busStopped.actualTime.month, 5);
      expect(busStopped.actualTime.day, 25);
      expect(busStopped.actualTime.hour, 8);
      expect(busStopped.actualTime.minute, 32);
      expect(busStopped.stopTime!.year, 2024);
      expect(busStopped.stopTime!.month, 5);
      expect(busStopped.stopTime!.day, 25);
      expect(busStopped.stopTime!.hour, 8);
      expect(busStopped.stopTime!.minute, 33);
      expect(busStopped.leaveTime!.year, 2024);
      expect(busStopped.leaveTime!.month, 5);
      expect(busStopped.leaveTime!.day, 25);
      expect(busStopped.leaveTime!.hour, 8);
      expect(busStopped.leaveTime!.minute, 35);
    });
  });
}
