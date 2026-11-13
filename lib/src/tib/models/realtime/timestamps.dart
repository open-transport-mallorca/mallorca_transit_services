/// Parses a realtime timestamp like `20261105 205146`. `null` if invalid.
DateTime? parseSocketTimestamp(Object? value) {
  if (value is DateTime) return value;
  if (value is! String) return null;
  return DateTime.tryParse(value);
}
