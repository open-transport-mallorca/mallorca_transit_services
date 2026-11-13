import 'package:mallorca_transit_services/src/tib/models/route_line.dart';

/// A departure on a bus or train station's board, with its bays.
class BayDeparture {
  /// See [Departure.tripId].
  final int tripId;

  /// See [RouteLine.code].
  final String lineCode;

  final LineType type;

  /// When it leaves.
  final DateTime time;

  /// Town it's heading to.
  final String destination;

  /// Main places on the way, e.g. `[Palma, Montuïri, Manacor, Cala Millor]`.
  final List<String> via;

  /// The bays it can leave from, e.g. `[14, 16]`, or a range like `1...10`
  /// for trains. Empty if the station has none.
  final List<String> bays;

  BayDeparture(
      {required this.tripId,
      required this.lineCode,
      required this.type,
      required this.time,
      required this.destination,
      this.via = const [],
      this.bays = const []});

  @override
  String toString() {
    return 'BayDeparture{tripId: $tripId, lineCode: $lineCode, type: $type, time: $time, destination: $destination, via: $via, bays: $bays}';
  }

  /// TIB sends the time only, so [date] is the day it leaves. Defaults to
  /// `dat`, which [toJson] writes.
  factory BayDeparture.fromJson(Map json, {DateTime? date}) {
    date ??= DateTime.parse(json['dat']);
    final time = DateTime.parse(json['horapas']);
    final String via = json['concatenacio_parades'] ?? '';
    final String bays = json['darsena'] ?? '';
    return BayDeparture(
        tripId: json['id_expedicio'],
        lineCode: json['codi_linia'],
        type: switch (json['tipus']) {
          'bus' => LineType.bus,
          'tren' => LineType.train,
          'metro' => LineType.metro,
          _ => LineType.unknown,
        },
        time: DateTime(date.year, date.month, date.day, time.hour, time.minute),
        destination: json['nom_nucli_arribada'],
        via: via.isEmpty ? const [] : via.split(' > '),
        bays: bays.isEmpty ? const [] : bays.split('<br>'));
  }

  Map<String, dynamic> toJson() {
    return {
      'id_expedicio': tripId,
      'codi_linia': lineCode,
      'tipus': switch (type) {
        LineType.train => 'tren',
        LineType.metro => 'metro',
        _ => 'bus',
      },
      'dat': DateTime(time.year, time.month, time.day).toIso8601String(),
      'horapas': DateTime(1970, 1, 1, time.hour, time.minute).toIso8601String(),
      'nom_nucli_arribada': destination,
      'concatenacio_parades': via.join(' > '),
      'darsena': bays.join('<br>'),
    };
  }
}
