import 'dart:convert';
import 'package:http/http.dart';

/// TIB's public client config, which holds the API key.
class TibConfig {
  static final Uri url =
      Uri.parse('https://www.tib.org/o/ctm-ws-configuration/get-config');

  /// Used when the config can't be fetched.
  static final Uri defaultSictmwsUrl = Uri.parse('https://api.tib.org/sictmws');

  final String apiKeyName;
  final String apiKey;
  final Uri sictmwsUrl;

  TibConfig(
      {required this.apiKeyName,
      required this.apiKey,
      required this.sictmwsUrl});

  factory TibConfig.fromJson(Map json) {
    return TibConfig(
        apiKeyName: json['apiKeyName'],
        apiKey: json['apiKeyVal'],
        sictmwsUrl: Uri.parse(json['sictmwsUrl']));
  }

  /// Throws on a non-200 response or an unexpected body.
  static Future<TibConfig> fetch(Client client) async {
    final response = await client.get(url);
    if (response.statusCode != 200) {
      throw ClientException(
          'Failed to fetch the TIB config: ${response.statusCode}', url);
    }
    return TibConfig.fromJson(json.decode(utf8.decode(response.bodyBytes)));
  }

  @override
  String toString() {
    return 'TibConfig{apiKeyName: $apiKeyName, sictmwsUrl: $sictmwsUrl}';
  }
}

/// A non-success response from a TIB endpoint.
class TibException implements Exception {
  final int statusCode;
  final Uri url;

  TibException(this.statusCode, this.url);

  @override
  String toString() => 'TibException: $statusCode for $url';
}

/// HTTP client that sends TIB's API key with every request.
class TibClient extends BaseClient {
  final Client _inner;
  Future<TibConfig?>? _config;

  /// Pass [inner] to send the requests through another client.
  TibClient({Client? inner, TibConfig? config}) : _inner = inner ?? Client() {
    if (config != null) _config = Future.value(config);
  }

  /// The config, fetched once. `null` if the fetch failed.
  Future<TibConfig?> get config => _config ??= TibConfig.fetch(_inner)
          .then<TibConfig?>((config) => config, onError: (Object _) {
        _config = null;
        return null;
      });

  /// [path] under the SICTMWS base URL, e.g. `lines/ctmr4/A42`.
  Future<Uri> sictmws(String path, [Map<String, String>? query]) async {
    final base = (await config)?.sictmwsUrl ?? TibConfig.defaultSictmwsUrl;
    final basePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    return base.replace(path: '$basePath/$path', queryParameters: query);
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final config = await this.config;
    if (config != null) {
      request.headers[config.apiKeyName] = config.apiKey;
    }
    final response = await _inner.send(request);
    if (response.statusCode != 401 || request is! Request) return response;

    // The key may have rotated, so refetch it once and resend.
    _config = null;
    final fresh = await this.config;
    if (fresh == null || fresh.apiKey == config?.apiKey) return response;
    await response.stream.drain<void>();
    return _inner
        .send(_copy(request)..headers[fresh.apiKeyName] = fresh.apiKey);
  }

  /// A request can only be sent once, so a retry needs a copy.
  static Request _copy(Request request) {
    return Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..bodyBytes = request.bodyBytes
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection;
  }

  @override
  void close() => _inner.close();
}
