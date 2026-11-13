/// Languages TIB and EMT publish in.
///
/// TIB items without a translation come in Catalan.
enum Language {
  ca('ca_ES'),
  es('es_ES'),
  en('en_GB'),
  de('de_DE');

  /// The locale TIB expects. EMT takes [name].
  final String locale;

  const Language(this.locale);
}
