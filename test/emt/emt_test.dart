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
    id: 958,
    lineId: 4,
    sublineId: 851,
    direction: Way.way,
    headsign: 'Illetes');

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
                direction: Way.back,
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

  group('EmtDepartures', () {
    Map vehicle(int code, int seconds, {bool arriving = false}) => {
          'code': code,
          'destination': 'Illetes',
          'seconds': seconds,
          'atStop': false,
          'arriving': arriving,
          'coordinateX': 0.0,
          'coordinateY': 0.0,
          'meters': 0,
        };

    test('next flattens the lines and sorts by arrival', () async {
      final emt = mockEmt((request) async {
        expect(request.url.path, '/maas/api/v1/agency/stops/401/timestr');
        return jsonResponse([
          {
            'lineCode': '4',
            'head': false,
            'vehicles': [vehicle(739, 291), vehicle(723, 2091)],
          },
          {
            'lineCode': '14',
            'head': true,
            'vehicles': [vehicle(116, 69, arriving: true)],
          },
        ]);
      });

      final before = DateTime.now();
      final departures = await emt.departures.next(401);

      expect(departures.map((d) => d.busNumber), [116, 739, 723]);
      final first = departures.first;
      expect(first.lineCode, '14');
      expect(first.destination, 'Illetes');
      expect(first.arriving, isTrue);
      expect(first.atStop, isFalse);
      expect(first.startsHere, isTrue);
      expect(departures[1].startsHere, isFalse);
      expect(
          first.arrival.difference(before).inSeconds, inInclusiveRange(69, 70));
    });

    test('next is empty when nothing is coming', () async {
      final emt = mockEmt((_) async =>
          jsonResponse({'codigo': 'NOT_EXISTS_LINESTOPTIME_BY_STOP_ID'}, 404));

      expect(await emt.departures.next(5), isEmpty);
    });

    test('fromJson counts seconds from now', () {
      final now = DateTime(2026, 11, 12, 23);
      final departure = EmtDeparture.fromJson(
          {...vehicle(739, 90), 'lineCode': '4'},
          now: now);

      expect(departure.arrival, DateTime(2026, 11, 12, 23, 1, 30));
      expect(departure.startsHere, isFalse);
    });

    test('fromJson(toJson(x)) keeps every field', () {
      final departure = EmtDeparture.fromJson(
          {...vehicle(739, 90, arriving: true), 'lineCode': '4', 'head': true},
          now: DateTime(2026, 11, 12, 23));

      expect(EmtDeparture.fromJson(departure.toJson()).toString(),
          departure.toString());
    });
  });

  group('EmtTimetables', () {
    final subline =
        EmtSubline(id: 1394, lineId: 17, name: '', shortName: '', number: 1);

    Map timetableJson() => {
          'id': 2711,
          'sublineCode': 1394,
          'dayTypeConfiguration': {
            'code': 'NOC',
            'description': 'Viernes, sábados y vísperas de festivo',
            'monday': false,
            'tuesday': false,
            'wednesday': false,
            'thursday': false,
            'friday': true,
            'saturday': true,
            'sunday': false,
            'publicHoliday': false,
            'publicHolidayEve': true,
            'order': 9,
          },
          'startPublishDate': '2026-11-04',
          'endPublishDate': null,
          'startValidityDate': '2026-11-09',
          'endValidityDate': null,
          'morningInterval': '15',
          'afternoonInterval': null,
          'timeTableCode': '00403-NOC',
          'outgoingComment': 'Referència de pas per pl. Espanya.',
          'returnComment': '',
          'timeTables': [
            {
              'routeCode': 1559,
              'direction': {'code': 1, 'name': 'Anada'},
              'trips': [
                {
                  'fromStopCode': 796,
                  'toStopCode': 93,
                  'numberOfTrips': 4,
                  'departureTimes': ['23:18', '23:38', '00:07', '03:30'],
                },
              ],
            },
            {
              'routeCode': 1562,
              'direction': {'code': 2, 'name': 'Tornada'},
              'trips': [
                {
                  'fromStopCode': 93,
                  'toStopCode': 796,
                  'numberOfTrips': 1,
                  'departureTimes': ['06:00'],
                },
                {
                  'fromStopCode': 50,
                  'toStopCode': 796,
                  'numberOfTrips': 1,
                  'departureTimes': ['06:10'],
                },
              ],
            },
          ],
        };

    test('forSubline sends the subline and language', () async {
      final emt = mockEmt((request) async {
        expect(request.url.path, '/maas/api/v1/schedule/');
        expect(request.url.queryParameters,
            {'sublineCode': '1394', 'locale': 'ca'});
        return jsonResponse([timetableJson()]);
      });

      final timetable =
          (await emt.timetables.forSubline(subline, language: Language.ca))
              .single;

      expect(timetable.id, 2711);
      expect(timetable.sublineId, 1394);
      expect(timetable.startDate, DateTime(2026, 11, 9));
      expect(timetable.endDate, isNull);
      expect(timetable.morningInterval, const Duration(minutes: 15));
      expect(timetable.afternoonInterval, isNull);

      final days = timetable.days;
      expect(days.code, 'NOC');
      expect(days.name, 'Viernes, sábados y vísperas de festivo');
      expect(days.weekdays, {DateTime.friday, DateTime.saturday});
      expect(days.holidays, isFalse);
      expect(days.holidayEves, isTrue);

      final [outbound, back] = timetable.directions;
      expect(outbound.routeId, 1559);
      expect(outbound.direction, Way.way);
      expect(outbound.comment, 'Referència de pas per pl. Espanya.');
      expect(back.direction, Way.back);
      expect(back.comment, isNull);
      expect(back.runs.map((r) => r.fromStopId), [93, 50]);
      expect(outbound.runs.single.toStopId, 93);
    });

    test('departures after midnight are past 24 hours', () async {
      final emt = mockEmt((_) async => jsonResponse([timetableJson()]));

      final timetable = (await emt.timetables.forSubline(subline)).single;

      expect(timetable.directions.first.runs.single.departures, const [
        Duration(hours: 23, minutes: 18),
        Duration(hours: 23, minutes: 38),
        Duration(hours: 24, minutes: 7),
        Duration(hours: 27, minutes: 30),
      ]);
    });

    test('forSubline is empty when the subline has no timetable', () async {
      final emt = mockEmt((_) async => jsonResponse([], 404));

      expect(await emt.timetables.forSubline(subline), isEmpty);
    });

    test('fromJson(toJson(x)) keeps every field', () {
      final timetable = EmtTimetable.fromJson(timetableJson());

      expect(EmtTimetable.fromJson(timetable.toJson()).toString(),
          timetable.toString());
    });
  });

  group('EmtAlerts', () {
    Map alertJson() => {
          'idAlerta': 79080,
          'idAgencia': 1,
          'alertStopId': null,
          'paradas': [
            {'idParada': 16, 'idNombre': 'rotonda de Portopí'},
          ],
          'lineas': [
            {'idLinea': 30, 'nombreLinea': 'Marivent', 'tripId': 0},
          ],
          'fechas': [
            {'horaInicio': '15/11/2026 06:00', 'horaFin': '15/11/2026 15:30'},
            {'horaInicio': '22/11/2026 06:00', 'horaFin': null},
          ],
          'titulo': 'Línea  Sin servicio carrera ',
          'descripcion': 'La línea 30 queda sin servicio.\n',
          'createdAt': '10/11/2026 08:12',
          'updatedAt': '12/11/2026 23:42',
          'files': [1783],
          'priority': {'name': 'Ordinaria', 'order': 3},
        };

    test('all parses alerts in the language', () async {
      final emt = mockEmt((request) async {
        expect(request.url.path, '/maas/api/v1/alert/');
        expect(request.url.queryParameters, {'locale': 'en'});
        return jsonResponse([alertJson()]);
      });

      final alert = (await emt.alerts.all(language: Language.en)).single;

      expect(alert.id, 79080);
      expect(alert.title, 'Línea Sin servicio carrera');
      expect(alert.description, 'La línea 30 queda sin servicio.');
      expect(alert.lineIds, [30]);
      expect(alert.stopIds, [16]);
      expect(alert.periods, [
        (start: DateTime(2026, 11, 15, 6), end: DateTime(2026, 11, 15, 15, 30)),
        (start: DateTime(2026, 11, 22, 6), end: null),
      ]);
      expect(alert.published, DateTime(2026, 11, 10, 8, 12));
      expect(alert.attachmentIds, [1783]);
    });

    test('byId returns null when EMT sends no alert', () async {
      final emt = mockEmt((request) async {
        expect(request.url.path, '/maas/api/v1/alert/1');
        return jsonResponse([]);
      });

      expect(await emt.alerts.byId(1), isNull);
    });

    test('attachment downloads the file', () async {
      final emt = mockEmt((request) async {
        expect(request.url.path, '/maas/api/v1/alert/downloadFile');
        expect(request.url.queryParameters['announceId'], '79080');
        expect(request.url.queryParameters['attachmentId'], '1783');
        return http.Response.bytes([37, 80, 68, 70], 200);
      });

      final bytes =
          await emt.alerts.attachment(EmtAlert.fromJson(alertJson()), 1783);

      expect(bytes, [37, 80, 68, 70]);
    });

    test('fromJson(toJson(x)) keeps every field', () {
      final alert = EmtAlert.fromJson(alertJson());

      expect(EmtAlert.fromJson(alert.toJson()).toString(), alert.toString());
    });
  });

  group('EmtNews', () {
    Map articleJson(int id, String published) => {
          'id': id,
          'agencyOriginId': 29,
          'language': {'id': 1, 'label': 'Castellano', 'locale': 'es'},
          'title': 'Article $id ',
          'summary': 'Summary $id',
          'description': '<p>First</p><p>Second</p>',
          'link': null,
          'publishedAt': published,
          'image': 366,
          'categories': [],
        };

    test('all reads pages until a short one and sorts newest first', () async {
      final pages = <String?>[];
      final emt = mockEmt((request) async {
        expect(request.url.path, '/maas/api/v1/notice/');
        expect(request.url.queryParameters['locale'], 'ca');
        final page = request.url.queryParameters['pageNumber'];
        pages.add(page);
        final size = int.parse(request.url.queryParameters['elementsPerPage']!);
        return jsonResponse({
          'pagination': {'total': 999, 'page': int.parse(page!)},
          'data': page == '1'
              ? [
                  for (var i = 0; i < size; i++)
                    articleJson(i, '2026-01-01T00:00:00')
                ]
              : [articleJson(1000, '2026-11-10T00:00:00')],
        });
      });

      final news = await emt.news.all(language: Language.ca);

      expect(pages, ['1', '2']);
      expect(news.length, 101);
      expect(news.first.id, 1000);
      expect(news.first.title, 'Article 1000');
      expect(news.first.summary, 'Summary 1000');
      expect(news.first.published, DateTime(2026, 11, 10));
      expect(news.first.paragraphs, ['First', 'Second']);
      expect(news.first.imageUrl.toString(),
          'https://www.emtpalma.cat/maas/api/v1/image/download/366');
    });

    test('fromJson(toJson(x)) keeps every field', () {
      final article =
          EmtArticle.fromJson(articleJson(1, '2026-11-10T00:00:00'));

      expect(EmtArticle.fromJson(article.toJson()).toJson(), article.toJson());
    });
  });
}
