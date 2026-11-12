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
}
