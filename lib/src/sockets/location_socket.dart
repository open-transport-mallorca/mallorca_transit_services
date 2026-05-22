import 'package:mallorca_transit_services/src/models/realtime/bus_position.dart';
import 'package:mallorca_transit_services/src/models/realtime/bus_stopped.dart';
import 'package:mallorca_transit_services/src/models/realtime/connection_close.dart';
import 'package:mallorca_transit_services/src/models/realtime/station_info.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket client for real-time bus tracking.
class LocationWebSocket {
  static WebSocketChannel locationChannel(int id) {
    final url = Uri.parse("wss://sae.tib.org/saews/public-events/$id");
    final channel = WebSocketChannel.connect(url);
    return channel;
  }

  static Stream locationStream(int id) {
    return locationChannel(id).stream;
  }

  /// Parses a WebSocket message into the appropriate model.
  /// Types: `position` → [BusPosition], `esta-info` → [RouteStationInfo],
  /// `stop` → [BusStopped], `close` → [ConnectionClose].
  static Object locationParser(Map json) {
    if (json["type"] == "position") {
      return BusPosition.fromJson(json);
    } else if (json["type"] == "esta-info") {
      return RouteStationInfo.fromJson(json);
    } else if (json["type"] == "stop") {
      return BusStopped.fromJson(json);
    } else if (json["type"] == "close") {
      return ConnectionClose();
    } else {
      throw UnimplementedError("Unknown type: ${json["type"]}");
    }
  }
}
