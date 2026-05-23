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

      expect(routeLine.summerOnly, false);
      expect(routeLine.onDemand, false);

      expect(routeLine.holidays, isNotNull);
      expect(routeLine.holidays!.length, 5);
      expect(routeLine.holidays![0].name, 'Assumpció de la Mare de Déu 2024');
      expect(routeLine.holidays![0].date, DateTime.parse('2024-08-15'));

      expect(routeLine.sessions, isNotNull);
      expect(routeLine.sessions!.length, 1);
      expect(routeLine.sessions![0].busTypeId, 'I15');
      expect(routeLine.sessions![0].current, true);
      expect(routeLine.sessions![0].name, 'Cala Millor - Palma');

      expect(routeLine.zoneIds, [5]);

      expect(routeLine.sublines![0].main, true);
      expect(routeLine.sublines![0].distance, 75554);
      expect(routeLine.sublines![0].way, Way.way);
      expect(routeLine.sublines![0].towns, isNotNull);
      expect(routeLine.sublines![0].towns!.length, 2);
      expect(routeLine.sublines![0].towns![0].name, 'Cala Millor');

      expect(routeLine.sublines![1].main, false);
      expect(routeLine.sublines![1].way, Way.back);
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

      RouteLinesApi.httpClient = mockClient;

      final lines = await RouteLinesApi.getAllLines();

      expect(lines, isNotEmpty);
      expect(lines[0].code, 'B42');
    });

    test('getAllLines with activeOnly filters inactive lines', () async {
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
            },
            {
              "act": false,
              "cod": "B99",
              "id": 2,
              "nam": "Bus 99",
              "color": "#00FF00",
              "typ": 3,
              "sublines": []
            }
          ]
        });
        return http.Response(responsePayload, 200);
      });

      RouteLinesApi.httpClient = mockClient;

      final lines = await RouteLinesApi.getAllLines(activeOnly: true);

      expect(lines.length, 1);
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

      RouteLinesApi.httpClient = mockClient;

      final line = await RouteLinesApi.getLine('B42');

      expect(line.code, 'B42');
    });

    test('getPdfTimetable fetches the most recent PDF timetable URL', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'ws.tib.org') {
          return http.Response('{"id": 3066}', 200);
        }

        if (request.url.host == 'www.tib.org') {
          final schedules = jsonEncode([
            {
              "JSONObject": {
                "FechaDeInicioDeValidez": "2025-04-01",
                "urlScheduleFile": "/documents/20124/old.pdf",
              }
            },
            {
              "JSONObject": {
                "FechaDeInicioDeValidez": "2026-03-27",
                "urlScheduleFile": "/documents/20124/latest.pdf",
              }
            },
            {
              "JSONObject": {
                "FechaDeInicioDeValidez": "2025-11-01",
                "urlScheduleFile": "/documents/20124/middle.pdf",
              }
            },
          ]);
          return http.Response(schedules, 200);
        }

        return http.Response('Not found', 404);
      });

      RouteLinesApi.httpClient = mockClient;

      final pdfUri = await RouteLinesApi.getPdfTimetable('B42');

      expect(pdfUri, isNotNull);
      expect(
          pdfUri.toString(), 'https://www.tib.org/documents/20124/latest.pdf');
    });
  });
}
