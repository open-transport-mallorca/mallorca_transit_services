import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mallorca_transit_services/mallorca_transit_services.dart';

Emt mockEmt(Future<http.Response> Function(http.Request request) handler) =>
    Emt(client: EmtClient(token: 'test', inner: MockClient(handler)));

http.Response jsonResponse(Object? body, [int statusCode = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), statusCode,
        headers: {'content-type': 'application/json; charset=utf-8'});

bool isCreateUser(http.Request request) =>
    request.url.path.endsWith('/user/create-user-anonimous');

http.Response userResponse(String token) =>
    jsonResponse({'id': 1, 'bearerToken': token}, 201);

Map stopJson(int id, {int wheelchair = 0}) => {
      'id': id,
      'stopCode': '$id',
      'stopName': 'Sindicat - Àrea d\'intercanvi Sindicat',
      'stopDesc': 'Sindicat - Àrea d\'intercanvi Sindicat',
      'stopLat': 39.57164100632657,
      'stopLon': 2.6555629997220387,
      'stopWheelchairBoarding': wheelchair,
    };

Map lineJson(int id, String code, {String color = 'DEB926'}) => {
      'id': id,
      'code': code,
      'name': 'Line $code',
      'routeColor': color,
      'routeSortOrder': 10,
    };

final line4 = EmtLine(id: 4, code: '4', name: 'Line 4', color: 0xFF993636);
final route958 = EmtRoute(
    id: 958, lineId: 4, sublineId: 851, direction: 1, headsign: 'Illetes');

void main() {
  group('EmtClient', () {
    test('sends a given token without creating a user', () async {
      final client = EmtClient(
          token: 'stored',
          inner: MockClient((request) async {
            expect(isCreateUser(request), isFalse);
            return http.Response(request.headers['authorization']!, 200);
          }));

      final response = await client.get(client.url('agency/stops'));

      expect(response.body, 'Bearer stored');
    });

    test('creates one user for concurrent requests and reports its token',
        () async {
      var creations = 0;
      final tokens = <String>[];
      final client = EmtClient(
          onToken: tokens.add,
          inner: MockClient((request) async {
            if (isCreateUser(request)) {
              creations++;
              final body = jsonDecode(request.body);
              expect(body['tokenDevice'], matches(RegExp(r'^[0-9a-f]{64}$')));
              expect(body['deviceTypeId'], 3);
              return userResponse('created');
            }
            expect(request.headers['authorization'], 'Bearer created');
            return http.Response('ok', 200);
          }));

      await Future.wait(
          List.generate(5, (_) => client.get(client.url('agency/stops'))));

      expect(creations, 1);
      expect(tokens, ['created']);
    });

    test('replaces a rejected token once and resends', () async {
      final tokens = <String>[];
      final client = EmtClient(
          token: 'deleted',
          onToken: tokens.add,
          inner: MockClient((request) async {
            if (isCreateUser(request)) return userResponse('fresh');
            return request.headers['authorization'] == 'Bearer fresh'
                ? http.Response('ok', 200)
                : http.Response('', 401);
          }));

      final response = await client.get(client.url('agency/stops'));

      expect(response.statusCode, 200);
      expect(tokens, ['fresh']);
    });

    test('throws if the user cannot be created, and retries later', () async {
      var fail = true;
      final client = EmtClient(inner: MockClient((request) async {
        if (isCreateUser(request)) {
          return fail ? http.Response('', 500) : userResponse('later');
        }
        return http.Response('ok', 200);
      }));

      await expectLater(client.token, throwsA(isA<EmtException>()));
      fail = false;
      expect(await client.token, 'later');
    });

    test('builds URLs under the API', () {
      final client = EmtClient(token: 't');

      expect(client.url('agency/stops/1', {'locale': 'es'}).toString(),
          'https://www.emtpalma.cat/maas/api/v1/agency/stops/1?locale=es');
    });
  });

  group('Emt', () {
    test('throws EmtException with EMT\'s error code', () async {
      final emt = mockEmt((_) async => jsonResponse({
            'estado': 'INTERNAL_SERVER_ERROR',
            'mensaje': 'Error en Base de Datos',
            'codigo': 'INTERNAL_SERVER_ERROR',
          }, 500));

      expect(
          emt.stops.all(),
          throwsA(isA<EmtException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.code, 'code', 'INTERNAL_SERVER_ERROR')
              .having((e) => e.message, 'message', 'Error en Base de Datos')));
    });
  });

  group('EmtStops', () {
    test('all parses every stop', () async {
      final emt = mockEmt((request) async {
        expect(request.url.path, '/maas/api/v1/agency/stops');
        return jsonResponse([stopJson(1), stopJson(2, wheelchair: 1)]);
      });

      final stops = await emt.stops.all();

      expect(stops.map((s) => s.id), [1, 2]);
      expect(stops.first.name, 'Sindicat - Àrea d\'intercanvi Sindicat');
      expect(stops.first.lat, 39.57164100632657);
      expect(stops.first.long, 2.6555629997220387);
      expect(stops.first.wheelchairAccessible, isNull);
      expect(stops.last.wheelchairAccessible, isTrue);
    });

    test('byId returns null for an unknown stop', () async {
      final emt = mockEmt((_) async => jsonResponse({
            'estado': 'NOT_FOUND',
            'codigo': 'NOT_EXISTS_STOP_BY_ID',
          }, 404));

      expect(await emt.stops.byId(99999), isNull);
    });

    test('fromJson(toJson(x)) keeps every field', () {
      for (final wheelchair in [0, 1, 2]) {
        final stop = EmtStop.fromJson(stopJson(1, wheelchair: wheelchair));
        expect(EmtStop.fromJson(stop.toJson()).toString(), stop.toString());
      }
    });
  });

  group('EmtLines', () {
    test('all parses lines with their colour', () async {
      final emt = mockEmt((request) async {
        expect(request.url.path, '/maas/api/v1/agency/lines/');
        return jsonResponse(
            [lineJson(17, 'A1'), lineJson(2, 'CC', color: 'd91e5d')]);
      });

      final lines = await emt.lines.all();

      expect(lines.map((l) => l.code), ['A1', 'CC']);
      expect(lines.first.id, 17);
      expect(lines.first.name, 'Line A1');
      expect(lines.first.color, 0xFFDEB926);
      expect(lines.last.color, 0xFFD91E5D);
    });

    test('byId returns null for an unknown line', () async {
      final emt = mockEmt(
          (_) async => jsonResponse({'codigo': 'NOT_EXISTS_LINE_BY_ID'}, 404));

      expect(await emt.lines.byId(9999), isNull);
    });

    test('sublines parses the variants', () async {
      final emt = mockEmt((request) async {
        expect(request.url.path, '/maas/api/v1/agency/lines/4/sublines');
        return jsonResponse([
          {
            'subLineId': 851,
            'longName': 'Nou Llevant - Ses Illetes',
            'shortName': 'Nou Llevant-Illetes',
            'externalCode': 1,
            'label': null,
            'lineId': 4,
          }
        ]);
      });

      final subline = (await emt.lines.sublines(line4)).single;

      expect(subline.id, 851);
      expect(subline.lineId, 4);
      expect(subline.name, 'Nou Llevant - Ses Illetes');
      expect(subline.shortName, 'Nou Llevant-Illetes');
      expect(subline.number, 1);
    });

    test('routes carries the line and subline ids', () async {
      final emt = mockEmt((request) async {
        expect(request.url.queryParameters, {'subLineId': '851'});
        return jsonResponse([
          {'tripId': 958, 'headSign': 'Illetes', 'directionId': 1},
          {'tripId': 961, 'headSign': 'Nou Llevant', 'directionId': 2},
        ]);
      });
      final subline =
          EmtSubline(id: 851, lineId: 4, name: '', shortName: '', number: 1);

      final routes = await emt.lines.routes(subline);

      expect(routes.map((r) => r.toString()), [
        route958.toString(),
        EmtRoute(
                id: 961,
                lineId: 4,
                sublineId: 851,
                direction: 2,
                headsign: 'Nou Llevant')
            .toString(),
      ]);
    });

    test('stops asks for the route and sorts by sequence', () async {
      final emt = mockEmt((request) async {
        expect(request.url.path, '/maas/api/v1/agency/lines/4/stops');
        expect(request.url.queryParameters['tripId'], '958');
        return jsonResponse([
          {...stopJson(401), 'stopSecuence': 2},
          {...stopJson(796), 'stopSecuence': 1},
        ]);
      });

      final stops = await emt.lines.stops(route958);

      expect(stops.map((s) => s.id), [796, 401]);
    });

    test('path parses the points in order', () async {
      final emt = mockEmt((request) async {
        expect(request.url.path, '/maas/api/v1/agency/lines/4/shape');
        expect(request.url.queryParameters, {'tripId': '958'});
        return jsonResponse([
          {'id': 958, 'order': 2, 'latitude': '39.5', 'longitude': '2.6'},
          {'id': 958, 'order': 1, 'latitude': '39.4', 'longitude': '2.5'},
        ]);
      });

      final path = await emt.lines.path(route958);

      expect(path.map((p) => [p.latitude, p.longitude]), [
        [39.4, 2.5],
        [39.5, 2.6],
      ]);
    });

    test('fromJson(toJson(x)) keeps every field', () {
      final line = EmtLine.fromJson(lineJson(2, 'CC', color: '0a0B0c'));
      expect(EmtLine.fromJson(line.toJson()).toString(), line.toString());
      final subline =
          EmtSubline(id: 851, lineId: 4, name: 'a', shortName: 'b', number: 3);
      expect(
          EmtSubline.fromJson(subline.toJson()).toString(), subline.toString());
      expect(
          EmtRoute.fromJson(route958.toJson()).toString(), route958.toString());
    });
  });

  test('EmtStops.lines keeps the lines serving the stop', () async {
    final emt = mockEmt((request) async => switch (request.url.path) {
          '/maas/api/v1/agency/stops/1/lines' => jsonResponse([
              {'id': 47, 'routeSortOrder': null},
              {'id': 46, 'routeSortOrder': null},
            ]),
          '/maas/api/v1/agency/lines/' => jsonResponse(
              [lineJson(17, 'A1'), lineJson(46, '46'), lineJson(47, '47')]),
          _ => http.Response('', 404),
        });

    final lines = await emt.stops.lines(1);

    expect(lines.map((l) => l.code), ['46', '47']);
  });
}
