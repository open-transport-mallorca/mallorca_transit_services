/// Parses the timestamps used by the location WebSocket, returning `null` for
/// a `null` or unparseable input.
///
/// The wire format is the ISO 8601 *basic* form `yyyyMMdd HHmmss`, which
/// [DateTime.tryParse] accepts as-is alongside the extended form.
///
/// Internal: not exported from the library.
DateTime? parseSocketTimestamp(Object? value) {
  if (value is DateTime) return value;
  if (value is! String) return null;
  return DateTime.tryParse(value);
}
