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
}
