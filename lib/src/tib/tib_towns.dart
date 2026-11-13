part of 'tib.dart';

class TibTowns {
  final Tib _tib;

  TibTowns._(this._tib);

  Future<List<Town>> all() async {
    final url = await _tib.client.sictmws('towns/${_tib.entity}');
    final body = Tib._json(await _tib._get(url));
    return [for (final Map town in body['town']) Town.fromJson(town)];
  }

  /// TIB's stations in the town with [townId]. Empty if there is no such town.
  ///
  /// The town's other stops, e.g. EMT's in Palma, are left out.
  Future<List<Station>> stations(int townId) async {
    final url = await _tib.client.sictmws('towns/${_tib.entity}/$townId');
    final (response, stations) =
        await (_tib._getOrNull(url), _tib.stations.all()).wait;
    if (response == null) return [];

    // Town stops have no id, so they're matched with the full stations.
    final byCode = {for (final station in stations) station.code: station};
    return [
      for (final Map stop in Tib._json(response)['stops'] ?? [])
        if (byCode[stop['cod']] case final station?) station
    ];
  }
}
