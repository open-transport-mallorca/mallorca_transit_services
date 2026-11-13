import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:mallorca_transit_services/mallorca_transit_services.dart';
import 'package:stream_channel/stream_channel.dart';

/// A [Tib] whose requests are answered by [handler], with a pinned config so
/// no config request is made.
Tib mockTib(Future<http.Response> Function(http.Request request) handler,
    {String entity = 'ctmr4'}) {
  return Tib(
      entity: entity,
      client: TibClient(
          config: TibConfig(
              apiKeyName: 'x-api-key',
              apiKey: 'test',
              sictmwsUrl: Uri.parse('https://api.tib.org/sictmws')),
          inner: MockClient(handler)));
}

/// [body] as JSON, encoded as UTF-8 like TIB's responses.
http.Response jsonResponse(Object? body) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), 200,
        headers: {'content-type': 'application/json; charset=utf-8'});

Map lineJson(String code, {bool active = true, int id = 1}) => {
      'act': active,
      'cod': code,
      'id': id,
      'nam': 'Line $code',
      'color': '#FF0000',
      'typ': 3,
      'sublines': []
    };

Map stationJson(String code) => {
      'cod': code,
      'id': 456,
      'lat': 39.5,
      'lon': 2.6,
      'nam': 'Station $code',
      'ref': 'Ref'
    };

void main() {
  group('Tib', () {
    test('requests the configured entity', () async {
      final urls = <Uri>[];
      final tib = mockTib((request) async {
        urls.add(request.url);
        return http.Response(jsonEncode({'linesInfo': []}), 200);
      }, entity: 'cime');

      await tib.lines.all();

      expect(urls.single.path, '/sictmws/lines/cime');
    });

    test('throws TibException on an error response', () async {
      final tib = mockTib((_) async => http.Response('boom', 500));

      expect(
          tib.lines.all(),
          throwsA(isA<TibException>()
              .having((e) => e.statusCode, 'statusCode', 500)));
    });
  });

  group('TibStations', () {
    test('all returns every station', () async {
      final tib = mockTib((request) async {
        expect(request.url.toString(),
            'https://api.tib.org/sictmws/stops/ctmr4?res=-1');
        return http.Response(
            jsonEncode({
              'stopsInfo': [stationJson('1'), stationJson('2')]
            }),
            200);
      });

      final stations = await tib.stations.all();

      expect(stations.map((s) => s.code), ['1', '2']);
    });

    test('all passes count', () async {
      final tib = mockTib((request) async {
        expect(request.url.queryParameters['res'], '2');
        return http.Response(jsonEncode({'stopsInfo': []}), 200);
      });

      await tib.stations.all(count: 2);
    });

    test('byCode returns the station', () async {
      final tib = mockTib((request) async {
        expect(request.url.path, '/sictmws/stops/ctmr4/123');
        return http.Response(jsonEncode(stationJson('123')), 200);
      });

      final station = await tib.stations.byCode('123');

      expect(station!.name, 'Station 123');
    });

    test('byCode returns null for an unknown code', () async {
      final tib = mockTib((_) async => http.Response('', 404));

      expect(await tib.stations.byCode('999'), isNull);
    });

    test('lines fetches each line of the station', () async {
      final tib = mockTib((request) async {
        return switch (request.url.path) {
          '/sictmws/stops/ctmr4/123' => http.Response(
              jsonEncode({
                'lines': [
                  {'cod': 'A'},
                  {'cod': 'B'}
                ]
              }),
              200),
          final path =>
            http.Response(jsonEncode(lineJson(path.split('/').last)), 200),
        };
      });

      final lines = await tib.stations.lines('123');

      expect(lines.map((l) => l.code), ['A', 'B']);
    });
  });

  group('TibStations by id, area and photo', () {
    test('byId returns the station', () async {
      final tib = mockTib((request) async {
        expect(request.url.path, '/sictmws/stops/id/456');
        return http.Response(jsonEncode(stationJson('123')), 200);
      });

      expect((await tib.stations.byId(456))!.code, '123');
    });

    test('byId returns null for an unknown id', () async {
      final tib = mockTib((_) async => http.Response('', 404));

      expect(await tib.stations.byId(9999999), isNull);
    });

    test('inArea requests every station in the rectangle', () async {
      final tib = mockTib((request) async {
        expect(request.url.path, '/sictmws/stops/ctmr4/between');
        expect(request.url.queryParameters, {
          'latSW': '39.56',
          'lngSW': '2.64',
          'latNE': '39.58',
          'lngNE': '2.66',
          'res': '-1',
        });
        return http.Response(
            jsonEncode({
              'stopsInfo': [stationJson('1')]
            }),
            200);
      });

      final stations =
          await tib.stations.inArea(LatLng(39.56, 2.64), LatLng(39.58, 2.66));

      expect(stations.single.code, '1');
    });

    test('near returns the stations within the radius, nearest first',
        () async {
      Map at(String code, double lat, double lng) =>
          {...stationJson(code), 'lat': lat, 'lon': lng};
      final tib = mockTib((request) async {
        final query = request.url.queryParameters;
        // About 500 m either way of the point.
        expect(double.parse(query['latSW']!), closeTo(39.5655, 0.0005));
        expect(double.parse(query['latNE']!), closeTo(39.5745, 0.0005));
        expect(double.parse(query['lngSW']!), closeTo(2.6442, 0.0005));
        expect(double.parse(query['lngNE']!), closeTo(2.6558, 0.0005));
        return http.Response(
            jsonEncode({
              'stopsInfo': [
                at('far', 39.5735, 2.6500), // ~390 m
                at('corner', 39.5740, 2.6555), // in the box, ~650 m
                at('close', 39.5705, 2.6500), // ~55 m
              ]
            }),
            200);
      });

      final stations = await tib.stations.near(LatLng(39.57, 2.65));

      expect(stations.map((s) => s.code), ['close', 'far']);
    });

    test('photo returns the image bytes', () async {
      final tib = mockTib((request) async {
        expect(request.url.path, '/sictmws/stops/id/1600/photo');
        return http.Response.bytes([0xFF, 0xD8, 0xFF], 200,
            headers: {'content-type': 'image/jpeg'});
      });

      expect(await tib.stations.photo(1600),
          Uint8List.fromList([0xFF, 0xD8, 0xFF]));
    });

    test('photo returns null for a station without one', () async {
      final tib = mockTib((_) async => http.Response('', 404));

      expect(await tib.stations.photo(1821), isNull);
    });
  });

  group('TibLines', () {
    test('all returns every line', () async {
      final tib = mockTib((_) async => http.Response(
          jsonEncode({
            'linesInfo': [lineJson('A'), lineJson('B', active: false)]
          }),
          200));

      expect((await tib.lines.all()).map((l) => l.code), ['A', 'B']);
    });

    test('all with activeOnly skips inactive lines', () async {
      final tib = mockTib((_) async => http.Response(
          jsonEncode({
            'linesInfo': [lineJson('A'), lineJson('B', active: false)]
          }),
          200));

      final lines = await tib.lines.all(activeOnly: true);

      expect(lines.map((l) => l.code), ['A']);
    });

    test('byCode returns the line', () async {
      final tib = mockTib((request) async {
        expect(request.url.path, '/sictmws/lines/ctmr4/B42');
        return http.Response(jsonEncode(lineJson('B42')), 200);
      });

      expect((await tib.lines.byCode('B42'))!.code, 'B42');
    });

    test('byCode returns null for an unknown code', () async {
      final tib = mockTib((_) async => http.Response('Line not found', 404));

      expect(await tib.lines.byCode('ZZZ'), isNull);
    });
  });

  group('TibTimetables', () {
    Map timetable(String start, {String? end}) => {
          'id': 'dxp-ctmr4-$start',
          'name': 'L401, des de $start',
          'lineId': 3066,
          'lineCode': '401',
          'startDate': '${start}T00:00:00',
          if (end != null) 'endDate': '${end}T00:00:00',
          'special': false,
          'url': 'https://www.tib.org/documents/$start.pdf',
          'creationDate': '2026-01-01T12:00:00',
          'modificationDate': '2026-01-01T12:00:00',
        };

    test('all requests the entity without old timetables', () async {
      final tib = mockTib((request) async {
        expect(request.url.path, '/sictmws/timetables/ctmr4');
        expect(request.url.queryParameters,
            {'cur': 'true', 'fut': 'true', 'old': 'false'});
        return http.Response(jsonEncode([timetable('2026-11-01')]), 200);
      });

      expect((await tib.timetables.all()).single.lineCode, '401');
    });

    test('forLine returns the line\'s timetables newest first', () async {
      final tib = mockTib((request) async {
        expect(request.url.path, '/sictmws/timetables');
        expect(request.url.queryParameters['lid'], '3066');
        expect(request.url.queryParameters['old'], 'true');
        return http.Response(
            jsonEncode([timetable('2025-11-01'), timetable('2026-11-01')]),
            200);
      });

      final timetables = await tib.timetables.forLine(3066, includeOld: true);

      expect(timetables.map((t) => t.startDate),
          [DateTime(2026, 11, 1), DateTime(2025, 11, 1)]);
    });

    group('current', () {
      Tib tibWith(List<Map> timetables) =>
          mockTib((_) async => http.Response(jsonEncode(timetables), 200));

      test('picks the newest started timetable', () async {
        final tib = tibWith([
          timetable('2025-11-01'),
          timetable('2026-11-01'),
          timetable('2027-01-01'),
        ]);

        final current =
            await tib.timetables.current(3066, at: DateTime(2026, 11, 12));

        expect(current!.startDate, DateTime(2026, 11, 1));
      });

      test('includes the last day of a seasonal timetable', () async {
        final tib = tibWith([timetable('2026-03-27', end: '2026-10-31')]);

        final current =
            await tib.timetables.current(3066, at: DateTime(2026, 10, 31, 23));

        expect(current, isNotNull);
      });

      test('falls back past an ended seasonal timetable', () async {
        final tib = tibWith([
          timetable('2025-11-01'),
          timetable('2026-03-27', end: '2026-10-31'),
        ]);

        final current =
            await tib.timetables.current(3066, at: DateTime(2026, 11, 12));

        expect(current!.startDate, DateTime(2025, 11, 1));
      });

      test('finds a timetable in the past', () async {
        final tib = mockTib((request) async {
          expect(request.url.queryParameters['old'], 'true');
          return http.Response(
              jsonEncode([timetable('2026-03-27', end: '2026-10-31')]), 200);
        });

        final current =
            await tib.timetables.current(3066, at: DateTime(2026, 7, 1));

        expect(current, isNotNull);
      });

      test('returns null out of season', () async {
        final tib = tibWith([timetable('2026-03-27', end: '2026-10-31')]);

        expect(await tib.timetables.current(3066, at: DateTime(2026, 11, 12)),
            isNull);
      });
    });
  });

  group('TibTowns', () {
    test('all returns every town', () async {
      final tib = mockTib((request) async {
        expect(request.url.path, '/sictmws/towns/ctmr4');
        return jsonResponse({
          'town': [
            {'id': 114, 'nam': 'Alaró'},
            {'id': 98, 'nam': 'Alcúdia'}
          ]
        });
      });

      final towns = await tib.towns.all();

      expect(
          towns.map((t) => (t.id, t.name)), [(114, 'Alaró'), (98, 'Alcúdia')]);
    });

    test('stations returns the town\'s TIB stations only', () async {
      final tib = mockTib((request) async => switch (request.url.path) {
            '/sictmws/towns/ctmr4/1' => http.Response(
                jsonEncode({
                  'id': 1,
                  'nam': 'Palma',
                  'stops': [
                    {'cod': '2', 'nam': 'Station 2'},
                    {'cod': 'E929', 'nam': 'Parc de la Mar'},
                    {'cod': '1', 'nam': 'Station 1'},
                  ]
                }),
                200),
            _ => http.Response(
                jsonEncode({
                  'stopsInfo': [stationJson('1'), stationJson('2')]
                }),
                200),
          });

      final stations = await tib.towns.stations(1);

      expect(stations.map((s) => s.code), ['2', '1']);
    });

    test('stations returns an empty list for an unknown town', () async {
      final tib = mockTib((request) async =>
          request.url.path.startsWith('/sictmws/towns')
              ? http.Response('', 404)
              : http.Response(jsonEncode({'stopsInfo': []}), 200));

      expect(await tib.towns.stations(999999), isEmpty);
    });
  });

  group('TibTrips', () {
    Map trip(int id, String time, String line) => {
          'dem': false,
          'dep_t': time,
          'route': {'codi': line, 'nom': 'Line $line'},
          'stp_cod': '40036',
          'stp_nam': 'Estació Intermodal',
          'sublinea': 'L$line-1',
          'trip_id': id,
        };

    test('all requests the date and sorts by departure', () async {
      final tib = mockTib((request) async {
        expect(request.url.path, '/sictmws/trips/ctmr4');
        expect(request.url.queryParameters, {'dat': '2026-11-05'});
        return jsonResponse(
            [trip(2, '09:00:00', '401'), trip(1, '07:00:00', '102')]);
      });

      final trips = await tib.trips.all(date: DateTime(2026, 11, 5, 18));

      expect(trips.map((t) => t.id), [1, 2]);
      expect(trips.first.departureTime, DateTime(2026, 11, 5, 7));
    });

    test('forLine keeps the line\'s trips', () async {
      final tib = mockTib((_) async => jsonResponse([
            trip(1, '07:00:00', '401'),
            trip(2, '08:00:00', '102'),
            trip(3, '09:00:00', '401'),
          ]));

      final trips = await tib.trips.forLine('401');

      expect(trips.map((t) => t.id), [1, 3]);
    });

    test('forSubline requests the subline', () async {
      final tib = mockTib((request) async {
        expect(request.url.path, '/sictmws/trips/ctmr4/L401-1');
        return jsonResponse([trip(1, '13:40:00', '401')]);
      });

      expect((await tib.trips.forSubline('L401-1')).single.id, 1);
    });

    test('byId returns the trip', () async {
      final tib = mockTib((request) async {
        expect(request.url.path, '/sictmws/trips/id/710119');
        return jsonResponse(
            {'dep_t': '07:35:00', 'trip_id': 710119, 'stops': []});
      });

      expect((await tib.trips.byId(710119))!.stops, isEmpty);
    });

    test('byId returns null for an unknown id', () async {
      final tib = mockTib((_) async => http.Response('', 404));

      expect(await tib.trips.byId(1), isNull);
    });
  });

  group('TibDepartures', () {
    test('next returns the departures', () async {
      final tib = mockTib((request) async {
        expect(request.url.toString(),
            'https://www.tib.org/o/manager/stop-code/123/departures/ctmr4?res=2');
        return http.Response(
            jsonEncode([
              for (final name in ['Departure 1', 'Departure 2'])
                {
                  'dt': '1970-01-01T10:12:00',
                  'aet': '2024-05-24T11:39:00',
                  'snam': name,
                  'trip_id': 558719,
                  'dem': false,
                  'lcod': '401',
                  'etn': 'Manacor',
                  'dtn': null,
                  'et': '1970-01-01T11:55:00'
                }
            ]),
            200);
      });

      final departures = await tib.departures.next('123', count: 2);

      expect(departures.map((d) => d.name), ['Departure 1', 'Departure 2']);
    });

    test('at requests the time and lines', () async {
      final time = DateTime(2026, 11, 13, 8);
      final tib = mockTib((request) async {
        expect(request.url.path, '/sictmws/stops/ctmr4/33008/next-departures');
        expect(request.url.queryParametersAll, {
          'ts': ['${time.millisecondsSinceEpoch}'],
          'res': ['5'],
          'lin': ['411', '417'],
        });
        return jsonResponse({
          'nextDeparturesInfo': [
            {
              'aet': '2026-11-13 08:33:00',
              'dem': false,
              'dt': '1970-01-01 08:00:00',
              'lcod': '417',
              'line_id': 3072,
              'snam': 'Son Carrió - Manacor - Porreres',
              'trip_id': 682153,
            }
          ],
          'pag': {'cur': 1, 'nxt': 2},
        });
      });

      final departures = await tib.departures
          .at('33008', time, count: 5, lineCodes: ['411', '417']);

      expect(departures.single.scheduledArrival, DateTime(2026, 11, 13, 8, 33));
      expect(departures.single.lineId, 3072);
    });

    test('at returns an empty list for an unknown station', () async {
      final tib =
          mockTib((_) async => http.Response('Entitat no trobada', 404));

      expect(await tib.departures.at('9999999', DateTime.now()), isEmpty);
    });

    test('withBays returns the board on the given day', () async {
      final time = DateTime(2026, 11, 13, 7);
      final tib = mockTib((request) async {
        expect(request.url.path,
            '/sictmws/stops/ctmr4/40036/next-departures-dock');
        expect(request.url.queryParameters['ts'],
            '${time.millisecondsSinceEpoch}');
        return jsonResponse([
          {
            'codi_linia': '202',
            'concatenacio_parades': 'Palma > Esporles',
            'darsena': '5',
            'horapas': '1970-01-01T08:00:00',
            'id_expedicio': 579923,
            'nom_nucli_arribada': 'Esporles',
            'tipus': 'bus',
          }
        ]);
      });

      final board = await tib.departures.withBays('40036', at: time);

      expect(board.single.time, DateTime(2026, 11, 13, 8));
      expect(board.single.bays, ['5']);
    });

    test('next returns an empty list when there are none', () async {
      final tib = mockTib((_) async => http.Response('[]', 200));

      expect(await tib.departures.next('999'), isEmpty);
    });
  });

  group('TibWarnings', () {
    Map notice(String id, String path) => {
          'abs': '',
          'afl': [3066],
          'id': id,
          'mdt': '2026-11-12',
          'pdt': '2026-11-12',
          'tit': 'Notice $id',
          'txt': '<p>Text</p>',
          'url': 'https://www.tib.org/$path',
        };

    Map webNotice(String path, String? document) => {
          'url': path,
          'attachedFileNotice': document == null
              ? '{}'
              : jsonEncode({
                  'extension': 'pdf',
                  'url': '$document?previewFileIndex=1',
                }),
        };

    test('all joins the attached PDFs by page', () async {
      final tib = mockTib((request) async {
        if (request.url.host == 'api.tib.org') {
          expect(request.url.path, '/sictmws/notices/ctmr4');
          expect(request.url.queryParameters['lng'], 'en_GB');
          return http.Response(
              jsonEncode([notice('a', '/-/avis-a'), notice('b', '-/avis-b')]),
              200);
        }
        expect(request.url.path, '/o/ce/notices');
        expect(request.url.queryParameters,
            {'groupId': '20124', 'entity': 'ctmr4', 'langId': 'en_GB'});
        return http.Response(
            jsonEncode([
              webNotice('/-/avis-a', '/documents/d/ctm/avis-a'),
              webNotice('/-/avis-b', null),
            ]),
            200);
      });

      final warnings = await tib.warnings.all(language: Language.en);

      expect(warnings.map((w) => w.id), ['a', 'b']);
      expect(warnings[0].documentUrl.toString(),
          'https://www.tib.org/documents/d/ctm/avis-a');
      expect(warnings[1].documentUrl, isNull);
    });

    test('all still returns the warnings when the PDFs fail', () async {
      final tib = mockTib((request) async => request.url.host == 'api.tib.org'
          ? http.Response(jsonEncode([notice('a', '-/avis-a')]), 200)
          : http.Response('down', 503));

      final warnings = await tib.warnings.all();

      expect(warnings.single.documentUrl, isNull);
    });

    test('byId returns the warning with its PDF', () async {
      final tib = mockTib((request) async {
        if (request.url.host == 'api.tib.org') {
          expect(request.url.path, '/sictmws/notices/id/a');
          return http.Response(jsonEncode(notice('a', '-/avis-a')), 200);
        }
        return http.Response(
            jsonEncode([webNotice('/-/avis-a', '/documents/d/ctm/avis-a')]),
            200);
      });

      final warning = await tib.warnings.byId('a');

      expect(warning!.documentUrl.toString(),
          'https://www.tib.org/documents/d/ctm/avis-a');
    });

    test('byId returns null for an unknown id', () async {
      final tib = mockTib((request) async => request.url.host == 'api.tib.org'
          ? http.Response('', 404)
          : http.Response('[]', 200));

      expect(await tib.warnings.byId('nope'), isNull);
    });
  });

  group('TibNews', () {
    Map article(int id, String? date) => {
          'abs': '',
          'id': id,
          'mdt': '2026-01-01',
          'tit': 'News $id',
          'txt': '<p>Text</p>',
          'url': 'https://www.tib.org/-/news-$id',
          if (date != null) 'dat': date,
        };

    test('all reads every page and sorts newest first', () async {
      final pages = <String?>[];
      final tib = mockTib((request) async {
        final query = request.url.queryParameters;
        pages.add(query['pag']);
        expect(query['lng'], 'de_DE');
        return query['pag'] == '1'
            ? http.Response(
                jsonEncode({
                  'pag': {'cur': 1, 'nxt': 2},
                  'newsInfos': [article(1, '2025-05-01'), article(2, null)]
                }),
                200)
            : http.Response(
                jsonEncode({
                  'pag': {'cur': 2, 'nxt': -1},
                  'newsInfos': [article(3, '2026-11-01')]
                }),
                200);
      });

      final news = await tib.news.all(language: Language.de);

      expect(pages, ['1', '2']);
      // Article 2 has no date, so its modification date counts.
      expect(news.map((n) => n.id), [3, 2, 1]);
    });
  });

  group('TibRealtime', () {
    late StreamChannelController<dynamic> socket;
    late List<Uri> connected;
    late Tib tib;

    setUp(() {
      socket = StreamChannelController();
      connected = [];
      tib = Tib(
          client: TibClient(
              config: TibConfig(
                  apiKeyName: 'x-api-key',
                  apiKey: 'test',
                  sictmwsUrl: Uri.parse('https://api.tib.org/sictmws'))),
          connectSocket: (url) {
            connected.add(url);
            return socket.local;
          });
    });

    test('connects only once listened to', () async {
      final stream = tib.realtime.track(11415348);
      expect(connected, isEmpty);

      final subscription = stream.listen((_) {});
      expect(connected.single.toString(),
          'wss://sae.tib.org/saews/public-events/11415348');
      await subscription.cancel();
    });

    test('emits parsed events and skips unknown types', () async {
      final events = <Object>[];
      final subscription = tib.realtime.track(1).listen(events.add);

      socket.foreign.sink
        ..add(jsonEncode({'type': 'mystery'}))
        ..add(jsonEncode({'type': 'close'}));
      await pumpEventQueue();

      expect(events, [isA<ConnectionClose>()]);
      await subscription.cancel();
    });

    test('emits a parse failure as an error and keeps going', () async {
      final events = <Object>[];
      final errors = <Object>[];
      final subscription =
          tib.realtime.track(1).listen(events.add, onError: errors.add);

      socket.foreign.sink
        ..add('not json')
        ..add(jsonEncode({'type': 'close'}));
      await pumpEventQueue();

      expect(errors, [isA<FormatException>()]);
      expect(events, [isA<ConnectionClose>()]);
      await subscription.cancel();
    });

    test('closes the socket when the subscription is cancelled', () async {
      final closed = Completer<void>();
      socket.foreign.stream.listen(null, onDone: closed.complete);

      await tib.realtime.track(1).listen((_) {}).cancel();

      await closed.future.timeout(const Duration(seconds: 1));
    });

    test('is done when the server closes the socket', () async {
      final done = Completer<void>();
      tib.realtime.track(1).listen((_) {}, onDone: done.complete);

      await socket.foreign.sink.close();

      await done.future.timeout(const Duration(seconds: 1));
    });
  });
}
