part of 'tib.dart';

/// TIB's PDF timetables.
class TibTimetables {
  final Tib _tib;

  TibTimetables._(this._tib);

  /// The timetables of every line. Pass [includeOld] to include expired ones.
  Future<List<Timetable>> all({bool includeOld = false}) async {
    final url = await _tib.client
        .sictmws('timetables/${_tib.entity}', _query(includeOld));
    return _parse(await _tib._get(url));
  }

  /// The timetables of the line with [lineId], newest first. Pass [includeOld]
  /// to include expired ones.
  Future<List<Timetable>> forLine(int lineId, {bool includeOld = false}) async {
    final url = await _tib.client
        .sictmws('timetables', {'lid': '$lineId', ..._query(includeOld)});
    return _parse(await _tib._get(url))
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  /// The timetable of the line with [lineId] in force [at] a time, now by
  /// default. `null` if the line doesn't run then, e.g. out of season.
  Future<Timetable?> current(int lineId, {DateTime? at}) async {
    final day = at ?? DateTime.now();
    // Newest first, so the first one in force replaces the older ones.
    // Expired ones too, as [at] may be in the past.
    for (final timetable in await forLine(lineId, includeOld: true)) {
      final end = timetable.endDate;
      if (timetable.startDate.isAfter(day)) continue;
      if (end != null && !day.isBefore(end.add(const Duration(days: 1)))) {
        continue;
      }
      return timetable;
    }
    return null;
  }

  static Map<String, String> _query(bool includeOld) =>
      {'cur': 'true', 'fut': 'true', 'old': '$includeOld'};

  static List<Timetable> _parse(Response response) =>
      [for (final Map t in Tib._json(response)) Timetable.fromJson(t)];
}
