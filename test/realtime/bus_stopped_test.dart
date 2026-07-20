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
      expect(busStopped.actualTime!.year, 2024);
      expect(busStopped.actualTime!.month, 5);
      expect(busStopped.actualTime!.day, 25);
      expect(busStopped.actualTime!.hour, 8);
      expect(busStopped.actualTime!.minute, 32);
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

    test('fromJson should handle nullable fields being absent', () {
      final json = {
        'upd': '2024-05-25T08:30:00Z',
        'lat': 42.1234,
        'lng': -71.5678,
        'vel': 35.5,
        'del': null,
        'pass': 20,
        'stop_nam': 'Sample Stop',
        'arr_t': '0830',
        'arr_rt': null,
        'stp_rt': null,
        'dep_rt': null,
      };

      final busStopped = BusStopped.fromJson(json);

      expect(busStopped.delay, isNull);
      expect(busStopped.actualTime, isNull);
      expect(busStopped.stopTime, isNull);
      expect(busStopped.leaveTime, isNull);
    });

    // Live payload shape
    test('fromJson parses stopId, stopCode, tripId and recordedAt', () {
      final busStopped = BusStopped.fromJson({
        'type': 'stop',
        'rt_id': 9795766,
        'upd': '20260720 184059',
        'date': '20260720 184056',
        'lat': 39.5728,
        'lng': 3.2023,
        'vel': 0.0,
        'del': 5,
        'pass': 37,
        'stop_id': 1599,
        'stop_code': '33004',
        'stop_nam': 'Sa Mora',
        'arr_t': '183500'
      });

      expect(busStopped.stopId, 1599);
      expect(busStopped.stopCode, '33004');
      expect(busStopped.tripId, 9795766);
      expect(busStopped.timestamp, DateTime(2026, 7, 20, 18, 40, 59));
      expect(busStopped.recordedAt, DateTime(2026, 7, 20, 18, 40, 56));
      expect(busStopped.scheduledTime.hour, 18);
      expect(busStopped.scheduledTime.minute, 35);
    });

    test('fromJson reads null for absent stopId, stopCode, tripId, recordedAt',
        () {
      final busStopped = BusStopped.fromJson({
        'upd': '2024-05-25T08:30:00Z',
        'lat': 42.1234,
        'lng': -71.5678,
        'vel': 35.5,
        'pass': 20,
        'stop_nam': 'Sample Stop',
        'arr_t': '0830'
      });

      expect(busStopped.stopId, isNull);
      expect(busStopped.stopCode, isNull);
      expect(busStopped.tripId, isNull);
      expect(busStopped.recordedAt, isNull);
    });
  });
}
