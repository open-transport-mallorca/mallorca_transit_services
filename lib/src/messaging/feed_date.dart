/// Parses a date as written in the tib.org feeds.
///
/// Accepts ISO 8601 (`2026-07-22T22:43:00Z`, used by `dc:date`) and RFC 822
/// (`Wed, 22 Jul 2026 22:43:00 GMT`, used by `pubDate`), which
/// [DateTime.tryParse] rejects. Note the feed writes `GMT` rather than a
/// numeric offset.
///
/// Returns a UTC [DateTime], or `null` when [value] is null, empty or in an
/// unrecognised format.
DateTime? parseFeedDate(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  final iso = DateTime.tryParse(trimmed);
  if (iso != null) return iso.toUtc();

  final match = _rfc822Pattern.firstMatch(trimmed);
  if (match == null) return null;
  final month = _monthsByAbbreviation[match.group(2)!.toLowerCase()];
  if (month == null) return null;

  // RFC 822 allows a two-digit year; RFC 2822 reads those as 19xx/20xx.
  int year = int.parse(match.group(3)!);
  if (year < 100) year += year < 50 ? 2000 : 1900;

  final local = DateTime.utc(
      year,
      month,
      int.parse(match.group(1)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6) ?? '0'));
  return local.subtract(_zoneOffset(match.group(7)));
}

Duration _zoneOffset(String? zone) {
  if (zone == null || zone.isEmpty) return Duration.zero;
  final numeric = RegExp(r'^([+-])(\d{2})(\d{2})$').firstMatch(zone);
  if (numeric != null) {
    final sign = numeric.group(1) == '-' ? -1 : 1;
    return Duration(
        hours: sign * int.parse(numeric.group(2)!),
        minutes: sign * int.parse(numeric.group(3)!));
  }
  // An unknown alphabetic zone means UTC, as RFC 2822 prescribes.
  return _namedZoneOffsets[zone.toUpperCase()] ?? Duration.zero;
}

final RegExp _rfc822Pattern = RegExp(r'^(?:[A-Za-z]{3,9},\s*)?'
    r'(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{2,4})\s+'
    r'(\d{1,2}):(\d{2})(?::(\d{2}))?'
    r'\s*([+-]\d{4}|[A-Za-z]{1,5})?$');

const Map<String, int> _monthsByAbbreviation = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};

const Map<String, Duration> _namedZoneOffsets = {
  'UT': Duration.zero,
  'UTC': Duration.zero,
  'GMT': Duration.zero,
  'Z': Duration.zero,
  'EST': Duration(hours: -5),
  'EDT': Duration(hours: -4),
  'CST': Duration(hours: -6),
  'CDT': Duration(hours: -5),
  'MST': Duration(hours: -7),
  'MDT': Duration(hours: -6),
  'PST': Duration(hours: -8),
  'PDT': Duration(hours: -7),
};
