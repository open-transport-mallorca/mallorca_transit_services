part of 'tib.dart';

/// TIB's stations.
class TibStations {
  final Tib _tib;

  TibStations._(this._tib);

  /// All stations. Pass [count] to limit the results.
  Future<List<Station>> all({int? count}) async {
    final url = await _tib.client
        .sictmws('stops/${_tib.entity}', {'res': '${count ?? -1}'});
    final body = Tib._json(await _tib._get(url));
    return [
      for (final Map station in body['stopsInfo']) Station.fromJson(station)
    ];
  }

  /// The station with [code], see [Station.code]. `null` if there is none.
  Future<Station?> byCode(String code) async {
    final url = await _tib.client.sictmws('stops/${_tib.entity}/$code');
    final response = await _tib._getOrNull(url);
    return response == null ? null : Station.fromJson(Tib._json(response));
  }

  /// The lines stopping at the station with [code].
  Future<List<RouteLine>> lines(String code) async {
    final url = await _tib.client.sictmws('stops/${_tib.entity}/$code');
    final body = Tib._json(await _tib._get(url));
    final lines = await Future.wait(
        [for (final Map line in body['lines']) _tib.lines.byCode(line['cod'])]);
    return lines.nonNulls.toList();
  }
}
