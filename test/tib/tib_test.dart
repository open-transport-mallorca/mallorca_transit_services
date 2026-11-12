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

    test('pdfTimetable picks the most recent timetable', () async {
      final tib = mockTib((request) async {
        if (request.url.host == 'api.tib.org') {
          return http.Response(jsonEncode(lineJson('B42', id: 3066)), 200);
        }
        expect(request.url.path, '/o/manager/schedules/3066');
        return http.Response(
            jsonEncode([
              for (final (date, file) in [
                ('2025-04-01', 'old'),
                ('2026-03-27', 'latest'),
                ('2025-11-01', 'middle'),
              ])
                {
                  'JSONObject': {
                    'FechaDeInicioDeValidez': date,
                    'urlScheduleFile': '/documents/20124/$file.pdf',
                  }
                }
            ]),
            200);
      });

      expect((await tib.lines.pdfTimetable('B42')).toString(),
          'https://www.tib.org/documents/20124/latest.pdf');
    });

    test('pdfTimetable returns null without timetables', () async {
      final tib = mockTib((_) async => http.Response('[]', 200));

      expect(await tib.lines.pdfTimetable('B42', lineId: 3066), isNull);
    });

    test('pdfTimetable returns null for an unknown line', () async {
      final tib = mockTib((_) async => http.Response('', 404));

      expect(await tib.lines.pdfTimetable('ZZZ'), isNull);
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

    test('next returns an empty list when there are none', () async {
      final tib = mockTib((_) async => http.Response('[]', 200));

      expect(await tib.departures.next('999'), isEmpty);
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
