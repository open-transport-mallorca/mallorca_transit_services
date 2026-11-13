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

  /// The lines stopping at the stop with [id], in EMT's display order.
  Future<List<EmtLine>> lines(int id) async {
    final url = _emt.client.url('agency/stops/$id/lines');
    final ids = {
      for (final Map line in Emt._json(await _emt._get(url))) line['id']
    };
    final lines = await _emt.lines.all();
    return lines.where((line) => ids.contains(line.id)).toList();
  }
}
