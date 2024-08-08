import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:mallorca_transit_services/mallorca_transit_services.dart';

void main() {
  group('RouteLine', () {
    test('fromJson creates a RouteLine object from JSON', () {
      final jsonMap = {
        "act": true,
        "cod": "401",
        "color": "#A5CFBA",
        "dem": false,
        "festius": [
          {"dat": "2024-08-15", "nam": "Assumpció de la Mare de Déu 2024"},
          {"dat": "2024-10-12", "nam": "Festa nacional 2024"},
          {"dat": "2024-11-01", "nam": "Tots Sants 2024"},
          {"dat": "2024-12-06", "nam": "Dia de la Constitució 2024"},
          {"dat": "2024-12-25", "nam": "Dia de Nadal 2024"}
        ],
        "id": 3066,
        "ini": "2020-12-09",
        "nam": "Cala Millor - Palma",
        "notices": [],
        "sec": "400",
        "sessions": [
          {
            "busTypeId": "I15",
            "cur": true,
            "end": "1972-12-31",
            "ini": "1972-01-01",
            "nam": "Cala Millor - Palma"
          }
        ],
        "sublines": [
          {
            "cod": "L401-1",
            "desc": "",
            "dir": "Anada",
            "distance": 75554,
            "id": 456,
            "lineid": 3066,
            "main": true,
            "nam": "Cala Millor - Palma",
            "stops": [
              {
                "cod": "51032",
                "id": 86,
                "lat": 39.601162,
                "lon": 3.381568,
                "nam": "Cala Millor centre",
                "parent": "Cala Millor"
              },
            ],
            "towns": [
              {"dis": 0, "id": 11432, "nam": "Cala Millor"},
              {"dis": 4, "id": 11431, "nam": "sa Coma"},
            ],
            "vis": true
          },
          {
            "cod": "L401-12",
            "desc": "",
            "dir": "Tornada",
            "distance": 65913,
            "id": 668,
            "lineid": 3066,
            "main": false,
            "nam": "Palma - Coves del Drac, exprés",
            "stops": [
              {
                "cod": "40036",
                "id": 984,
                "lat": 39.576298,
                "lon": 2.6541128,
                "nam": "Estació Intermodal",
                "parent": "Palma"
              },
            ],
            "towns": [
              {"dis": 0, "id": 11167, "nam": "Palma"},
              {"dis": 1, "id": 11427, "nam": "Portocristo"}
            ],
            "vis": false,
          },
        ],
        "summ": false,
        "typ": 3,
        "zoneTransport": [
          {"id": 5}
        ]
      };

      final routeLine = RouteLine.fromJson(jsonMap);

      expect(routeLine.active, true);
      expect(routeLine.code, '401');
      expect(routeLine.id, 3066);
      expect(routeLine.name, 'Cala Millor - Palma');
      expect(routeLine.color, 0xFFA5CFBA);
      expect(routeLine.type, LineType.bus);
      expect(routeLine.sublines, isNotNull);
      expect(routeLine.sublines!.length, 2);
      expect(routeLine.sublines![0].code, 'L401-1');
    });

    test('fromJson handles null sublines', () {
      final jsonMap = {
        'act': true,
        'cod': 'B42',
        'id': 1,
        'nam': 'Bus 42',
        'color': '#FF0000',
        'typ': 3,
        'sublines': null
      };

      final routeLine = RouteLine.fromJson(jsonMap);

      expect(routeLine.active, true);
      expect(routeLine.code, 'B42');
      expect(routeLine.id, 1);
      expect(routeLine.name, 'Bus 42');
      expect(routeLine.color, 0xFFFF0000);
      expect(routeLine.type, LineType.bus);
      expect(routeLine.sublines, isNull);
    });

    test('getAllLines fetches all route lines', () async {
      final mockClient = MockClient((request) async {
        final responsePayload = json.encode({
          "linesInfo": [
            {
              "act": true,
              "cod": "B42",
              "id": 1,
              "nam": "Bus 42",
              "color": "#FF0000",
              "typ": 3,
              "sublines": []
            }
          ]
        });
        return http.Response(responsePayload, 200);
      });

      RouteLine.httpClient = mockClient;

      final lines = await RouteLine.getAllLines();

      expect(lines, isNotEmpty);
      expect(lines[0].code, 'B42');
    });

    test('getLine fetches a specific route line', () async {
      final mockClient = MockClient((request) async {
        final responsePayload = json.encode({
          "act": true,
          "cod": "B42",
          "id": 1,
          "nam": "Bus 42",
          "color": "#FF0000",
          "typ": 3,
          "sublines": []
        });
        return http.Response(responsePayload, 200);
      });

      RouteLine.httpClient = mockClient;

      final line = await RouteLine.getLine('B42');

      expect(line.code, 'B42');
    });

    test('getPdfTimetable fetches the PDF timetable URL', () async {
      final mockClient = MockClient((request) async {
        final htmlResponse = '''
        <div class="ctm-line-schedule-link">
          <a href="https://www.tib.org/pdftimetable.pdf">Timetable PDF</a>
        </div>
        ''';
        return http.Response(htmlResponse, 200);
      });

      RouteLine.httpClient = mockClient;

      final pdfUri = await RouteLine.getPdfTimetable('B42');

      expect(pdfUri, isNotNull);
      expect(pdfUri.toString(), 'https://www.tib.org/pdftimetable.pdf');
    });
  });
}
