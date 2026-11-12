part of 'emt.dart';

class EmtDepartures {
  final Emt _emt;

  EmtDepartures._(this._emt);

  /// The buses coming to the stop with [stopId], soonest first. Empty if
  /// none are coming or there is no such stop.
  Future<List<EmtDeparture>> next(int stopId) async {
    final url = _emt.client.url('agency/stops/$stopId/timestr');
    final response = await _emt._getOrNull(url);
    if (response == null) return [];

    final now = DateTime.now();
    return [
      for (final Map line in Emt._json(response))
        for (final Map vehicle in line['vehicles'])
          EmtDeparture.fromJson(
              {...vehicle, 'lineCode': line['lineCode'], 'head': line['head']},
              now: now)
    ]..sort((a, b) => a.arrival.compareTo(b.arrival));
  }
}
