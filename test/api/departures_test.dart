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
      'line_id': 3121,
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
      expect(departure.lineId, 3121);
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

    test('fromJson parses the SICTMWS date format', () {
      final departure = Departure.fromJson({
        'aet': '2026-11-12 21:25:00',
        'dem': false,
        'dt': '1970-01-01 20:25:00',
        'lcod': '401',
        'line_id': 3066,
        'snam': 'Palma - Cala Millor',
        'trip_id': 710148,
      });

      expect(departure.scheduledArrival, DateTime(2026, 11, 12, 21, 25));
      expect(departure.tripDepartureTime, DateTime(1970, 1, 1, 20, 25));
    });
  });

  group('BayDeparture', () {
    final json = {
      'codi_linia': '401',
      'concatenacio_parades': 'Palma > Montuïri > Manacor > Cala Millor',
      'darsena': '14<br>16',
      'horapas': '1970-01-01T08:05:00',
      'id_expedicio': 710146,
      'nom_nucli_arribada': 'Cala Millor',
      'tipus': 'bus',
    };

    test('fromJson maps every field onto the date', () {
      final departure =
          BayDeparture.fromJson(json, date: DateTime(2026, 11, 13, 7));

      expect(departure.tripId, 710146);
      expect(departure.lineCode, '401');
      expect(departure.type, LineType.bus);
      expect(departure.time, DateTime(2026, 11, 13, 8, 5));
      expect(departure.destination, 'Cala Millor');
      expect(departure.via, ['Palma', 'Montuïri', 'Manacor', 'Cala Millor']);
      expect(departure.bays, ['14', '16']);
    });

    test('fromJson reads trains and a missing bay', () {
      final departure = BayDeparture.fromJson(
          {...json, 'tipus': 'tren', 'darsena': null},
          date: DateTime(2026, 11, 13));

      expect(departure.type, LineType.train);
      expect(departure.bays, isEmpty);
    });

    test('fromJson(toJson(x)) keeps every field without a date', () {
      final departure =
          BayDeparture.fromJson(json, date: DateTime(2026, 11, 13));

      expect(BayDeparture.fromJson(departure.toJson()).toString(),
          departure.toString());
    });
  });
}
