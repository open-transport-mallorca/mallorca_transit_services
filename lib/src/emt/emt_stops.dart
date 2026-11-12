part of 'emt.dart';

class EmtStops {
  final Emt _emt;

  EmtStops._(this._emt);

  Future<List<EmtStop>> all() async {
    final url = _emt.client.url('agency/stops');
    return [
      for (final Map stop in Emt._json(await _emt._get(url)))
        EmtStop.fromJson(stop)
    ];
  }

  /// `null` if there is no stop with [id].
  Future<EmtStop?> byId(int id) async {
    final url = _emt.client.url('agency/stops/$id');
    final response = await _emt._getOrNull(url);
    return response == null ? null : EmtStop.fromJson(Emt._json(response));
  }
}
