import 'package:test/test.dart';
import 'package:mallorca_transit_services/mallorca_transit_services.dart';

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
      expect(station.code, '123');
      expect(station.id, 456);
      expect(station.lat, 37.7749);
      expect(station.long, -122.4194);
      expect(station.name, 'Sample Station');
      expect(station.ref, 'Reference');
      expect(station.pickupType, isNull);
      expect(station.dropoffType, isNull);
      expect(station.town, isNull);

      final json = station.toJson();
      expect(json, {
        ...stationJson,
        'pickupType': null,
        'dropoffType': null,
        'parent': null
      });
    });

    // Test town parsing (comes from the 'parent' key)
    test('fromJson and toJson should map town to the parent key', () {
      final stationJson = {
        'cod': '51031',
        'id': 1821,
        'lat': 39.5867,
        'lon': 3.375763,
        'nam': 'Mare Selva 2',
        'ref': null,
        'pickupType': null,
        'dropoffType': null,
        'parent': 'sa Coma'
      };

      final station = Station.fromJson(stationJson);
      expect(station.town, 'sa Coma');

      expect(station.toJson(), stationJson);
      expect(station.toString(), contains('town: sa Coma'));
    });

    // Test pickup/drop-off type parsing (present on line/subline stops only)
    test('fromJson parses pickupType/dropoffType and derived getters', () {
      final dischargeOnly = Station.fromJson({
        'cod': '51031',
        'id': 1821,
        'lat': 39.5867,
        'lon': 3.375763,
        'nam': 'Mare Selva 2',
        'parent': 'sa Coma',
        'pickupType': 1,
        'dropoffType': 0
      });
      expect(dischargeOnly.town, 'sa Coma');
      expect(dischargeOnly.pickupType, PickupDropoffType.notAvailable);
      expect(dischargeOnly.dropoffType, PickupDropoffType.regular);
      expect(dischargeOnly.isDischargeOnly, isTrue);
      expect(dischargeOnly.isPickupOnly, isFalse);

      // Pickup-only stop: pickup allowed, no drop-off
      final pickupOnly = Station.fromJson({
        'cod': '123',
        'id': 1,
        'lat': 0.0,
        'lon': 0.0,
        'nam': 'Pickup Only',
        'pickupType': 0,
        'dropoffType': 1
      });
      expect(pickupOnly.isPickupOnly, isTrue);
      expect(pickupOnly.isDischargeOnly, isFalse);

      // Normal stop with the fields omitted
      final normal = Station.fromJson(
          {'cod': '456', 'id': 2, 'lat': 0.0, 'lon': 0.0, 'nam': 'Normal'});
      expect(normal.pickupType, isNull);
      expect(normal.dropoffType, isNull);
      expect(normal.town, isNull);
      expect(normal.isDischargeOnly, isFalse);
      expect(normal.isPickupOnly, isFalse);
    });

    test('fromJson parses the arranged types and keeps their values', () {
      final json = {
        'cod': '1',
        'id': 1,
        'lat': 0.0,
        'lon': 0.0,
        'nam': 'Arranged',
        'ref': null,
        'parent': null,
        'pickupType': 2,
        'dropoffType': 3
      };

      final station = Station.fromJson(json);

      expect(station.pickupType, PickupDropoffType.phoneAgency);
      expect(station.dropoffType, PickupDropoffType.coordinateWithDriver);
      expect(station.isDischargeOnly, isFalse);
      expect(station.isPickupOnly, isFalse);
      expect(station.toJson(), json);
    });

    test('fromJson reads an unexpected value as unknown', () {
      final station = Station.fromJson({
        'cod': '1',
        'id': 1,
        'lat': 0.0,
        'lon': 0.0,
        'nam': 'Odd',
        'pickupType': 7
      });

      expect(station.pickupType, PickupDropoffType.unknown);
    });
  });
}
