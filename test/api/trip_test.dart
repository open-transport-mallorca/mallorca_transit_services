import 'package:test/test.dart';
import 'package:mallorca_transit_services/mallorca_transit_services.dart';

Map stop(int seq, String time, {String code = '40036'}) => {
      'dem': false,
      'dep_t': time,
      'lat': 39.576298,
      'lng': 2.6541128,
      'nam': 'Stop $seq',
      'nt': 12376,
      'seq': seq,
      'stop_cod': code,
      'stop_id': 984,
      'town': 'Palma',
    };

void main() {
  final day = DateTime(2026, 11, 12);

  group('Trip', () {
    test('fromJson parses a trip from the day list', () {
      final trip = Trip.fromJson({
        'dem': false,
        'dep_t': '07:35:00',
        'route': {'codi': '401', 'nom': 'Cala Millor - Palma'},
        'stp_cod': '40036',
        'stp_nam': 'Estació Intermodal',
        'sublinea': 'L401-6',
        'trip_id': 710119,
      }, date: day);

      expect(trip.id, 710119);
      expect(trip.departureTime, DateTime(2026, 11, 12, 7, 35));
      expect(trip.onDemand, isFalse);
      expect(trip.lineCode, '401');
      expect(trip.lineName, 'Cala Millor - Palma');
      expect(trip.sublineCode, 'L401-6');
      expect(trip.firstStopCode, '40036');
      expect(trip.firstStopName, 'Estació Intermodal');
      expect(trip.stops, isNull);
    });

    test('fromJson parses the stops', () {
      final trip = Trip.fromJson({
        'dem': false,
        'dep_t': '07:35:00',
        'trip_id': 710119,
        'stops': [stop(0, '07:35:00'), stop(2, '08:00:00', code: '4008')],
      }, date: day);

      final second = trip.stops![1];
      expect(second.stopCode, '4008');
      expect(second.stopId, 984);
      expect(second.name, 'Stop 2');
      expect(second.town, 'Palma');
      expect(second.time, DateTime(2026, 11, 12, 8));
      expect(second.lat, 39.576298);
      expect(second.long, 2.6541128);
      expect(second.sequence, 2);
      expect(second.fareZoneId, 12376);
    });

    test('fromJson moves stops past midnight to the next day', () {
      final trip = Trip.fromJson({
        'dep_t': '23:30:00',
        'trip_id': 1,
        'stops': [
          stop(0, '23:30:00'),
          stop(1, '23:58:00'),
          stop(2, '00:00:00'),
          stop(3, '00:20:00'),
        ],
      }, date: day);

      expect(trip.stops!.map((s) => s.time), [
        DateTime(2026, 11, 12, 23, 30),
        DateTime(2026, 11, 12, 23, 58),
        DateTime(2026, 11, 13),
        DateTime(2026, 11, 13, 0, 20),
      ]);
    });

    test('fromJson(toJson(x)) keeps every field without a date', () {
      final trip = Trip.fromJson({
        'dem': true,
        'dep_t': '23:30:00',
        'route': {'codi': '401', 'nom': 'Cala Millor - Palma'},
        'sublinea': 'L401-6',
        'stp_cod': '40036',
        'stp_nam': 'Estació Intermodal',
        'trip_id': 1,
        'stops': [stop(0, '23:30:00'), stop(1, '00:10:00')],
      }, date: day);

      expect(Trip.fromJson(trip.toJson()).toString(), trip.toString());
    });
  });
}
