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

  /// The station with [id], see [Station.id]. `null` if there is none.
  Future<Station?> byId(int id) async {
    final url = await _tib.client.sictmws('stops/id/$id');
    final response = await _tib._getOrNull(url);
    return response == null ? null : Station.fromJson(Tib._json(response));
  }

  /// The stations inside the rectangle between [southWest] and [northEast].
  Future<List<Station>> inArea(LatLng southWest, LatLng northEast) async {
    final url = await _tib.client.sictmws('stops/${_tib.entity}/between', {
      'latSW': '${southWest.latitude}',
      'lngSW': '${southWest.longitude}',
      'latNE': '${northEast.latitude}',
      'lngNE': '${northEast.longitude}',
      'res': '-1',
    });
    final body = Tib._json(await _tib._get(url));
    return [
      for (final Map station in body['stopsInfo']) Station.fromJson(station)
    ];
  }

  /// The stations within [radius] metres of [point], nearest first.
  Future<List<Station>> near(LatLng point, {double radius = 500}) async {
    // Degrees of latitude are about 111 km everywhere; longitude shrinks
    // towards the poles.
    final latDelta = radius / 111320;
    final lngDelta = radius / (111320 * cos(point.latitudeInRad));
    final stations = await inArea(
        LatLng(point.latitude - latDelta, point.longitude - lngDelta),
        LatLng(point.latitude + latDelta, point.longitude + lngDelta));

    const distance = Distance();
    final distances = {
      for (final station in stations)
        station: distance(point, LatLng(station.lat, station.long))
    };
    return stations.where((station) => distances[station]! <= radius).toList()
      ..sort((a, b) => distances[a]!.compareTo(distances[b]!));
  }

  /// The JPEG photo of the station with [id]. `null` if it has none.
  Future<Uint8List?> photo(int id) async {
    final url = await _tib.client.sictmws('stops/id/$id/photo');
    return (await _tib._getOrNull(url))?.bodyBytes;
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
