import 'package:test/test.dart';
import 'package:mallorca_transit_services/mallorca_transit_services.dart';

/// A departure as sent by `/o/manager`.
Map<String, dynamic> departureJson({Map? realTrip}) => {
      'dt': '1970-01-01T18:40:00.000',
      'et': '1970-01-01T19:25:00.000',
      'etn': 'Campos',
      'dtn': 'Palma',
      'aet': '2026-07-20T18:55:00.000',
      'lcod': 'A51',
      'trip_id': 659865,
      'snam': 'Palma - Campos',
      'dem': true,
      'lineColor': '#28689D',
      if (realTrip != null) 'realTrip': realTrip,
    };

final realTripJson = {
  'aet': '2026-07-20T19:01:00.000',
  'id': '9795766',
  'lastCoords': {'lat': 39.5741, 'lng': 3.2015},
};

void main() {
  group('RealTrip', () {
    test('fromJson parses the live estimate and position', () {
      final realTrip = RealTrip.fromJson(realTripJson);

      expect(realTrip.id, 9795766);
      expect(realTrip.estimatedArrival, DateTime.parse('2026-07-20T19:01:00'));
      expect(realTrip.lat, 39.5741);
      expect(realTrip.long, 3.2015);
    });

    test('fromJson handles a null estimate', () {
      final realTrip = RealTrip.fromJson({...realTripJson, 'aet': null});

      expect(realTrip.estimatedArrival, isNull);
    });

    test('toJson writes the wire format', () {
      expect(RealTrip.fromJson(realTripJson).toJson(), realTripJson);
    });
  });

  group('Departure', () {
    test('fromJson maps every field', () {
      final departure =
          Departure.fromJson(departureJson(realTrip: realTripJson));

      expect(departure.scheduledArrival, DateTime.parse('2026-07-20T18:55:00'));
      expect(
          departure.tripDepartureTime, DateTime.parse('1970-01-01T18:40:00'));
      expect(departure.tripArrivalTime, DateTime.parse('1970-01-01T19:25:00'));
      expect(departure.name, 'Palma - Campos');
      expect(departure.tripId, 659865);
      expect(departure.onDemand, isTrue);
      expect(departure.lineCode, 'A51');
      expect(departure.origin, 'Palma');
      expect(departure.destination, 'Campos');
      expect(departure.lineColor, '#28689D');
      expect(departure.lineColorValue, 0xFF28689D);
      expect(departure.realTrip!.id, 9795766);
    });

    test('fromJson reads null for absent optional fields', () {
      final departure = Departure.fromJson({
        'dt': '1970-01-01T18:40:00',
        'aet': '2026-07-20T18:40:00',
        'snam': 'A51',
        'trip_id': 659865,
        'dem': false,
        'lcod': 'A51',
      });

      expect(departure.tripArrivalTime, isNull);
      expect(departure.realTrip, isNull);
      expect(departure.origin, isNull);
      expect(departure.destination, isNull);
      expect(departure.lineColor, isNull);
      expect(departure.lineColorValue, isNull);
    });

    test('lineColorValue returns null for a non-hex lineColor', () {
      final departure =
          Departure.fromJson({...departureJson(), 'lineColor': '401'});

      expect(departure.lineColorValue, isNull);
    });

    test('toJson writes the wire format', () {
      final json = departureJson(realTrip: realTripJson);

      expect(Departure.fromJson(json).toJson(), json);
    });

    test('toJson writes null for an untracked departure', () {
      expect(Departure.fromJson(departureJson()).toJson()['realTrip'], isNull);
    });
  });
}
