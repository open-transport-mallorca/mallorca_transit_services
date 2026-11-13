import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mallorca_transit_services/mallorca_transit_services.dart';

String configBody(String key) => jsonEncode({
      'apiKeyName': 'x-api-key',
      'apiKeyVal': key,
      'sictmwsUrl': 'https://api.tib.org/sictmws',
    });

bool isConfigRequest(http.Request request) => request.url == TibConfig.url;

void main() {
  group('TibClient', () {
    test('sends the key from the config with every request', () async {
      final seenKeys = <String?>[];
      final client = TibClient(inner: MockClient((request) async {
        if (isConfigRequest(request)) {
          return http.Response(configBody('secret'), 200);
        }
        seenKeys.add(request.headers['x-api-key']);
        return http.Response('ok', 200);
      }));

      await client.get(Uri.parse('https://api.tib.org/sictmws/lines/ctmr4'));
      await client.get(Uri.parse('https://www.tib.org/o/manager/x'));

      expect(seenKeys, ['secret', 'secret']);
    });

    test('fetches the config once for concurrent requests', () async {
      var configFetches = 0;
      final client = TibClient(inner: MockClient((request) async {
        if (isConfigRequest(request)) {
          configFetches++;
          return http.Response(configBody('secret'), 200);
        }
        return http.Response('ok', 200);
      }));

      await Future.wait(List.generate(
          5, (_) => client.get(Uri.parse('https://api.tib.org/sictmws/a'))));

      expect(configFetches, 1);
    });

    test('uses a given config without fetching it', () async {
      final client = TibClient(
          config: TibConfig(
              apiKeyName: 'x-api-key',
              apiKey: 'pinned',
              sictmwsUrl: Uri.parse('https://api.tib.org/sictmws')),
          inner: MockClient((request) async {
            expect(isConfigRequest(request), isFalse);
            return http.Response(request.headers['x-api-key']!, 200);
          }));

      final response =
          await client.get(Uri.parse('https://api.tib.org/sictmws/a'));

      expect(response.body, 'pinned');
    });

    test('sends requests without the key when the config fetch fails',
        () async {
      var configFetches = 0;
      final client = TibClient(inner: MockClient((request) async {
        if (isConfigRequest(request)) {
          configFetches++;
          return http.Response('down', 503);
        }
        return http.Response('${request.headers['x-api-key']}', 200);
      }));

      final first = await client.get(Uri.parse('https://www.tib.org/o/a'));
      final second = await client.get(Uri.parse('https://www.tib.org/o/b'));

      expect(first.body, 'null');
      expect(second.body, 'null');
      // A failed fetch is not cached, so each request tries again.
      expect(configFetches, 2);
    });

    test('refetches the config and retries once on a 401', () async {
      var key = 'old';
      final seenKeys = <String?>[];
      final client = TibClient(inner: MockClient((request) async {
        if (isConfigRequest(request)) {
          return http.Response(configBody(key), 200);
        }
        seenKeys.add(request.headers['x-api-key']);
        return request.headers['x-api-key'] == 'new'
            ? http.Response('ok', 200)
            : http.Response('Unauthorized', 401);
      }));

      await client.get(Uri.parse('https://api.tib.org/sictmws/a'));
      key = 'new';
      final response =
          await client.get(Uri.parse('https://api.tib.org/sictmws/a'));

      expect(response.statusCode, 200);
      expect(seenKeys, ['old', 'old', 'new']);
    });

    test('returns the 401 when the refetched key is unchanged', () async {
      var requests = 0;
      final client = TibClient(inner: MockClient((request) async {
        if (isConfigRequest(request)) {
          return http.Response(configBody('same'), 200);
        }
        requests++;
        return http.Response('Unauthorized', 401);
      }));

      final response =
          await client.get(Uri.parse('https://api.tib.org/sictmws/a'));

      expect(response.statusCode, 401);
      expect(requests, 1);
    });

    test('builds SICTMWS URLs from the config', () async {
      final client = TibClient(
          config: TibConfig(
              apiKeyName: 'x-api-key',
              apiKey: 'k',
              sictmwsUrl: Uri.parse('https://example.org/sictmws/')),
          inner: MockClient((_) async => http.Response('', 200)));

      expect(
          await client.sictmws('lines/ctmr4/A42', {'dat': '2026-11-12'}),
          Uri.parse(
              'https://example.org/sictmws/lines/ctmr4/A42?dat=2026-11-12'));
    });

    test('falls back to the default SICTMWS URL without a config', () async {
      final client =
          TibClient(inner: MockClient((_) async => http.Response('down', 503)));

      expect(await client.sictmws('stops/ctmr4'),
          Uri.parse('https://api.tib.org/sictmws/stops/ctmr4'));
    });
  });
}
