import 'package:mallorca_transit_services/src/realtime/bus_position.dart';
import 'package:mallorca_transit_services/src/realtime/bus_stopped.dart';
import 'package:mallorca_transit_services/src/realtime/connection_close.dart';
import 'package:mallorca_transit_services/src/realtime/station_info.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A class that connects to the location socket and returns the stream of
/// messages.
///
/// The location socket provides real-time information about the buses on a
/// route.
class LocationWebSocket {
  /// Connects to the location socket and returns the stream of messages.
  ///
  /// The [id] is the ID of the route.
  static Future<Stream> locationStream(int id) async {
    final url = Uri.parse("wss://sae.tib.org/saews/public-events/$id");
    final channel = WebSocketChannel.connect(url);
    return channel.stream;
  }

  /// Parses the JSON message from the location socket and returns the
  /// appropriate object.
  ///
  /// The JSON message can be of three types:
  /// - `position`: A bus position
  /// - `esta-info`: Information about the stations on the route
  /// - `stop`: A bus stopped and gives its relevant information
  /// - `close`: The connection has been closed
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
      /// Throw error if the type received is unknown
      /// because we don't know how to handle it
      throw UnimplementedError("Unknown type: ${json["type"]}");
    }
  }
}
