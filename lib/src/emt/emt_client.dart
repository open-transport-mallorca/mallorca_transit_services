import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart';

/// A non-success response from an EMT endpoint.
class EmtException implements Exception {
  final int statusCode;
  final Uri url;

  /// EMT's error code, e.g. `NOT_EXISTS_STOP_BY_ID`.
  final String? code;

  final String? message;

  EmtException(this.statusCode, this.url, {this.code, this.message});

  @override
  String toString() =>
      'EmtException: $statusCode${code != null ? ' $code' : ''} for $url';
}

/// HTTP client that sends an EMT bearer token with every request.
///
/// Without a token, it creates an anonymous user once to get one.
class EmtClient extends BaseClient {
  static final Uri baseUrl = Uri.parse('https://www.emtpalma.cat/maas/api/v1/');

  final Client _inner;

  /// Called with each token the client creates, so it can be stored and
  /// passed back next time.
  final void Function(String token)? onToken;

  Future<String>? _token;

  /// Pass [token] to reuse a stored one, and [inner] to send the requests
  /// through another client.
  EmtClient({Client? inner, String? token, this.onToken})
      : _inner = inner ?? Client() {
    if (token != null) _token = Future.value(token);
  }

  /// The bearer token, created once if none was given.
  Future<String> get token => _token ??= _createToken().then((token) {
        onToken?.call(token);
        return token;
      }, onError: (Object e, StackTrace stackTrace) {
        _token = null;
        Error.throwWithStackTrace(e, stackTrace);
      });

  /// [path] under [baseUrl], e.g. `agency/stops`.
  Uri url(String path, [Map<String, String>? query]) =>
      baseUrl.resolve(path).replace(queryParameters: query);

  Future<String> _createToken() async {
    final url = this.url('user/create-user-anonimous');
    final random = Random.secure();
    final device = [
      for (var i = 0; i < 32; i++)
        random.nextInt(256).toRadixString(16).padLeft(2, '0')
    ].join();
    final response = await _inner.post(url,
        headers: {'content-type': 'application/json'},
        body: json.encode({
          'userTypeId': 1,
          'languageId': 1,
          'deviceTypeId': 3,
          'tokenDevice': device,
        }));
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw EmtException(response.statusCode, url);
    }
    return json.decode(utf8.decode(response.bodyBytes))['bearerToken'];
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final token = await this.token;
    request.headers['authorization'] = 'Bearer $token';
    final response = await _inner.send(request);
    if (response.statusCode != 401 || request is! Request) return response;

    // EMT may have deleted the user, so create a new one once and resend.
    if (await _token == token) _token = null;
    final fresh = await this.token;
    if (fresh == token) return response;
    await response.stream.drain<void>();
    return _inner
        .send(_copy(request)..headers['authorization'] = 'Bearer $fresh');
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
