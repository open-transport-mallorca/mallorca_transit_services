part of 'tib.dart';

/// Live tracking of TIB's buses.
class TibRealtime {
  final Tib _tib;

  TibRealtime._(this._tib);

  /// Live events of the trip with [tripId], see [RealTrip.id].
  ///
  /// Cancelling the subscription closes the socket. Unknown events are skipped.
  Stream<Object> track(int tripId) {
    StreamChannel? channel;
    StreamSubscription? subscription;
    late final StreamController<Object> controller;

    controller = StreamController<Object>(
      onListen: () {
        channel = _tib.connectSocket(
            Uri.parse('wss://sae.tib.org/saews/public-events/$tripId'));
        subscription = channel!.stream.listen(
          (message) {
            try {
              final event = parse(json.decode(message as String));
              if (event != null) controller.add(event);
            } catch (e, stackTrace) {
              controller.addError(e, stackTrace);
            }
          },
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      onCancel: () {
        // Not awaited, as closing waits for the server.
        unawaited(channel?.sink.close());
        return subscription?.cancel();
      },
    );
    return controller.stream;
  }

  /// Parses a WebSocket message. `null` for an unknown type.
  static Object? parse(Map json) {
    return switch (json['type']) {
      'position' => BusPosition.fromJson(json),
      'esta-info' => RouteStationInfo.fromJson(json),
      'stop' => BusStopped.fromJson(json),
      'close' => ConnectionClose(),
      _ => null,
    };
  }
}
