part of 'tib.dart';

/// TIB's lines, their sublines and timetables.
class TibLines {
  final Tib _tib;

  TibLines._(this._tib);

  /// All lines. Pass [activeOnly] to skip the inactive ones.
  Future<List<RouteLine>> all({bool activeOnly = false}) async {
    final url = await _tib.client.sictmws('lines/${_tib.entity}');
    final body = Tib._json(await _tib._get(url));
    return [
      for (final Map line in body['linesInfo'])
        if (!activeOnly || line['act'] != false) RouteLine.fromJson(line)
    ];
  }

  /// The line with [code]. `null` if there is none.
  Future<RouteLine?> byCode(String code) async {
    final url = await _tib.client.sictmws('lines/${_tib.entity}/$code');
    final response = await _tib._getOrNull(url);
    return response == null ? null : RouteLine.fromJson(Tib._json(response));
  }

  /// The sublines of [line]. Pass [onlyActive] false to include inactive ones.
  Future<List<Subline>> sublines(RouteLine line,
      {bool onlyActive = true}) async {
    final url = await _tib.client.sictmws('lines/${_tib.entity}/${line.code}');
    final List body = Tib._json(await _tib._get(url))['sublines'];
    final sublines = [for (final Map s in body) Subline.fromJson(s, line)];
    if (onlyActive && body.length > 2) {
      sublines.removeWhere((subline) => subline.active == false);
    }
    return sublines;
  }

  /// The route [subline] drives on the map.
  Future<RoutePath> path(Subline subline) async {
    final url = await _tib.client.sictmws(
        'lines/${_tib.entity}/${subline.parentLine.code}/kmz/${subline.code}');
    final response = await _tib._get(url);
    return RoutePath.fromKmz(utf8.decode(response.bodyBytes), subline);
  }

  /// The latest PDF timetable of the line with [code]. `null` if there is none.
  Future<Uri?> pdfTimetable(String code, {int? lineId}) async {
    lineId ??= (await byCode(code))?.id;
    if (lineId == null) return null;

    final response = await _tib._get(Uri.parse(
        'https://www.tib.org/o/manager/schedules/$lineId?groupId=20124'));
    final List schedules = Tib._json(response);
    if (schedules.isEmpty) return null;

    final latest = schedules.reduce((a, b) {
      final dateA = a['JSONObject']['FechaDeInicioDeValidez'] as String;
      final dateB = b['JSONObject']['FechaDeInicioDeValidez'] as String;
      return dateA.compareTo(dateB) >= 0 ? a : b;
    });
    return Uri.parse(
        "https://www.tib.org${latest['JSONObject']['urlScheduleFile']}");
  }
}
