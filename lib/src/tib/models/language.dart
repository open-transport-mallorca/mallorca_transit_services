/// Languages TIB publishes warnings and news in.
///
/// Items without a translation come in Catalan.
enum Language {
  ca('ca_ES'),
  es('es_ES'),
  en('en_GB'),
  de('de_DE');

  /// The locale TIB expects.
  final String locale;

  const Language(this.locale);
}
