part of 'emt.dart';

class EmtLines {
  final Emt _emt;

  EmtLines._(this._emt);

  /// In EMT's display order.
  Future<List<EmtLine>> all() async {
    final url = _emt.client.url('agency/lines/');
    return [
      for (final Map line in Emt._json(await _emt._get(url)))
        EmtLine.fromJson(line)
    ];
  }

  /// `null` if there is no line with [id].
  Future<EmtLine?> byId(int id) async {
    final url = _emt.client.url('agency/lines/$id');
    final response = await _emt._getOrNull(url);
    return response == null ? null : EmtLine.fromJson(Emt._json(response));
  }

  Future<List<EmtSubline>> sublines(EmtLine line) async {
    final url = _emt.client.url('agency/lines/${line.id}/sublines');
    return [
      for (final Map subline in Emt._json(await _emt._get(url)))
        EmtSubline.fromJson(subline)
    ];
  }

  Future<List<EmtRoute>> routes(EmtSubline subline) async {
    final url = _emt.client
        .url('agency/lines/directions-subline', {'subLineId': '${subline.id}'});
    return [
      for (final Map route in Emt._json(await _emt._get(url)))
        EmtRoute.fromJson(route, lineId: subline.lineId, sublineId: subline.id)
    ];
  }

  /// In driving order.
  Future<List<EmtStop>> stops(EmtRoute route) async {
    final url = _emt.client.url('agency/lines/${route.lineId}/stops', {
      'tripId': '${route.id}',
      'isLine': '1',
      'isLineNearStop': '0',
      'both': '0',
    });
    final List stops = Emt._json(await _emt._get(url));
    stops.sort((a, b) => a['stopSecuence'].compareTo(b['stopSecuence']));
    return [for (final Map stop in stops) EmtStop.fromJson(stop)];
  }

  Future<List<LatLng>> path(EmtRoute route) async {
    final url = _emt.client
        .url('agency/lines/${route.lineId}/shape', {'tripId': '${route.id}'});
    final List points = Emt._json(await _emt._get(url));
    points.sort((a, b) => a['order'].compareTo(b['order']));
    return [
      for (final Map point in points)
        LatLng(
            double.parse(point['latitude']), double.parse(point['longitude']))
    ];
  }
}
