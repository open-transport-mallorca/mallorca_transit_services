part of 'tib.dart';

/// Departures from TIB's stations.
class TibDepartures {
  final Tib _tib;

  TibDepartures._(this._tib);

  /// The next [count] departures from the station with [stationCode].
  ///
  /// Uses TIB's web backend, the only one with [Departure.realTrip].
  Future<List<Departure>> next(String stationCode, {int count = 10}) async {
    final response = await _tib._get(Uri.parse(
        'https://www.tib.org/o/manager/stop-code/$stationCode/departures/${_tib.entity}?res=$count'));
    return [for (final Map d in Tib._json(response)) Departure.fromJson(d)];
  }

  /// The [count] departures from the station with [stationCode] scheduled
  /// from [time] until the end of that day. Pass [lineCodes] to keep only
  /// those lines.
  ///
  /// From the timetable, so without [Departure.realTrip] or
  /// [Departure.lineColor].
  Future<List<Departure>> at(String stationCode, DateTime time,
      {int count = 25, List<String>? lineCodes}) async {
    final url = await _tib.client
        .sictmws('stops/${_tib.entity}/$stationCode/next-departures', {
      'ts': '${time.millisecondsSinceEpoch}',
      'res': '$count',
      if (lineCodes != null) 'lin': lineCodes,
    });
    final response = await _tib._getOrNull(url);
    if (response == null) return [];
    return [
      for (final Map d in Tib._json(response)['nextDeparturesInfo'])
        Departure.fromJson(d)
    ];
  }

  /// The next [count] departures from a bus or train station with
  /// [stationCode], with their bays, from [at] or now until the end of that
  /// day.
  ///
  /// At other stops, the bays are those at the trip's starting station.
  Future<List<BayDeparture>> withBays(String stationCode,
      {DateTime? at, int count = 50}) async {
    final time = at ?? DateTime.now();
    final url = await _tib.client.sictmws(
        'stops/${_tib.entity}/$stationCode/next-departures-dock',
        {'ts': '${time.millisecondsSinceEpoch}', 'res': '$count'});
    return [
      for (final Map d in Tib._json(await _tib._get(url)))
        BayDeparture.fromJson(d, date: time)
    ];
  }
}
