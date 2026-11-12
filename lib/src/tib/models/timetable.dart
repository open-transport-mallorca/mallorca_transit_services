/// A line's PDF timetable.
class Timetable {
  final String id;

  /// File name, e.g. `L401, des de 2026.11.01`.
  final String name;

  /// See [RouteLine.id].
  final int lineId;

  /// See [RouteLine.code].
  final String lineCode;

  /// When the timetable takes effect.
  final DateTime startDate;

  /// Last day of a seasonal timetable. Otherwise `null`, and the timetable
  /// lasts until a newer one starts.
  final DateTime? endDate;

  /// Whether it's a special timetable, e.g. for a holiday.
  final bool special;

  /// The PDF.
  final Uri url;

  final DateTime? created;
  final DateTime? modified;

  Timetable(
      {required this.id,
      required this.name,
      required this.lineId,
      required this.lineCode,
      required this.startDate,
      this.endDate,
      this.special = false,
      required this.url,
      this.created,
      this.modified});

  @override
  String toString() {
    return 'Timetable{id: $id, name: $name, lineId: $lineId, lineCode: $lineCode, startDate: $startDate, endDate: $endDate, special: $special, url: $url}';
  }

  factory Timetable.fromJson(Map json) {
    return Timetable(
        id: json['id'],
        name: json['name'],
        lineId: json['lineId'],
        lineCode: json['lineCode'],
        startDate: DateTime.parse(json['startDate']),
        endDate: _date(json['endDate']),
        special: json['special'] ?? false,
        url: Uri.parse(json['url']),
        created: _date(json['creationDate']),
        modified: _date(json['modificationDate']));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lineId': lineId,
      'lineCode': lineCode,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'special': special,
      'url': url.toString(),
      'creationDate': created?.toIso8601String(),
      'modificationDate': modified?.toIso8601String(),
    };
  }

  static DateTime? _date(String? value) =>
      value != null ? DateTime.tryParse(value) : null;
}
