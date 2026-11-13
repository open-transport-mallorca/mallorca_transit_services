part of 'emt.dart';

class EmtTimetables {
  final Emt _emt;

  EmtTimetables._(this._emt);

  /// The current and upcoming timetables, one per [EmtDayType]. Empty if the
  /// subline has none.
  Future<List<EmtTimetable>> forSubline(EmtSubline subline,
      {Language language = Language.es}) async {
    final url = _emt.client.url(
        'schedule/', {'sublineCode': '${subline.id}', 'locale': language.name});
    final response = await _emt._getOrNull(url);
    if (response == null) return [];
    return [
      for (final Map timetable in Emt._json(response))
        EmtTimetable.fromJson(timetable)
    ];
  }
}
