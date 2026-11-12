import 'dart:convert';
import 'package:http/http.dart';
import 'package:latlong2/latlong.dart';
import 'package:mallorca_transit_services/src/emt/emt_client.dart';
import 'package:mallorca_transit_services/src/emt/models/emt_departure.dart';
import 'package:mallorca_transit_services/src/emt/models/emt_line.dart';
import 'package:mallorca_transit_services/src/emt/models/emt_stop.dart';

part 'emt_departures.dart';
part 'emt_lines.dart';
part 'emt_stops.dart';

/// Entry point to EMT, Palma's city buses.
///
/// Create one and share it. Store the token from [EmtClient.onToken] and pass
/// it back, so a new anonymous user isn't created on every start.
class Emt {
  final EmtClient client;

  late final EmtStops stops = EmtStops._(this);
  late final EmtLines lines = EmtLines._(this);
  late final EmtDepartures departures = EmtDepartures._(this);

  Emt({EmtClient? client}) : client = client ?? EmtClient();

  /// Closes the HTTP client.
  void close() => client.close();

  /// Throws [EmtException] on a non-2xx response.
  Future<Response> _get(Uri url) async {
    final response = await client.get(url);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      Map? body;
      try {
        body = _json(response);
      } catch (_) {}
      throw EmtException(response.statusCode, url,
          code: body?['codigo'], message: body?['mensaje']);
    }
    return response;
  }

  /// Like [_get], but returns `null` on a 404.
  Future<Response?> _getOrNull(Uri url) async {
    try {
      return await _get(url);
    } on EmtException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  static dynamic _json(Response response) =>
      json.decode(utf8.decode(response.bodyBytes));
}
