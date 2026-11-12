import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:mallorca_transit_services/src/tib/models/departure.dart';
import 'package:mallorca_transit_services/src/tib/models/realtime/bus_position.dart';
import 'package:mallorca_transit_services/src/tib/models/realtime/bus_stopped.dart';
import 'package:mallorca_transit_services/src/tib/models/realtime/connection_close.dart';
import 'package:mallorca_transit_services/src/tib/models/realtime/station_info.dart';
import 'package:mallorca_transit_services/src/tib/models/route_line.dart';
import 'package:mallorca_transit_services/src/tib/models/station.dart';
import 'package:mallorca_transit_services/src/tib/tib_client.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'tib_departures.dart';
part 'tib_lines.dart';
part 'tib_realtime.dart';
part 'tib_stations.dart';

/// Entry point to TIB, Mallorca's interurban buses.
///
/// Create one and share it, as each instance fetches the API key.
class Tib {
  final TibClient client;

  /// The transport entity requests are made for. `ctmr4` is Mallorca.
  final String entity;

  /// Opens the realtime WebSocket. Replaceable for tests.
  final StreamChannel Function(Uri url) connectSocket;

  late final TibStations stations = TibStations._(this);
  late final TibLines lines = TibLines._(this);
  late final TibDepartures departures = TibDepartures._(this);
  late final TibRealtime realtime = TibRealtime._(this);

  Tib(
      {TibClient? client,
      this.entity = 'ctmr4',
      this.connectSocket = WebSocketChannel.connect})
      : client = client ?? TibClient();

  /// Closes the HTTP client.
  void close() => client.close();

  /// Throws [TibException] on a non-2xx response.
  Future<Response> _get(Uri url) async {
    final response = await client.get(url);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TibException(response.statusCode, url);
    }
    return response;
  }

  /// Like [_get], but returns `null` on a 404.
  Future<Response?> _getOrNull(Uri url) async {
    try {
      return await _get(url);
    } on TibException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  static dynamic _json(Response response) =>
      json.decode(utf8.decode(response.bodyBytes));
}
