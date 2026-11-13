part of 'tib.dart';

/// TIB's service warnings.
class TibWarnings {
  final Tib _tib;

  TibWarnings._(this._tib);

  /// The current warnings.
  Future<List<TransitWarning>> all({Language language = Language.es}) async {
    final url = await _tib.client
        .sictmws('notices/${_tib.entity}', {'lng': language.locale});
    final (response, documents) =
        await (_tib._get(url), _documents(language)).wait;
    return [
      for (final Map json in Tib._json(response))
        _withDocument(TransitWarning.fromJson(json), documents)
    ];
  }

  /// The warning with [id], see [TransitWarning.id]. `null` if there is none.
  Future<TransitWarning?> byId(String id,
      {Language language = Language.es}) async {
    final url =
        await _tib.client.sictmws('notices/id/$id', {'lng': language.locale});
    final (response, documents) =
        await (_tib._getOrNull(url), _documents(language)).wait;
    if (response == null) return null;
    return _withDocument(
        TransitWarning.fromJson(Tib._json(response)), documents);
  }

  static TransitWarning _withDocument(
          TransitWarning warning, Map<String, Uri> documents) =>
      warning.copyWith(documentUrl: documents[warning.link.path]);

  /// The attached PDFs by page path, from TIB's web backend, as SICTMWS
  /// doesn't send them. Empty if that fails.
  Future<Map<String, Uri>> _documents(Language language) async {
    try {
      final response =
          await _tib._get(Uri.https('www.tib.org', '/o/ce/notices', {
        'groupId': '20124',
        'entity': _tib.entity,
        'langId': language.locale,
      }));
      return {
        for (final Map notice in Tib._json(response))
          if (_documentPath(notice) case final path?)
            notice['url']: Uri.https('www.tib.org', path)
      };
    } catch (_) {
      return {};
    }
  }

  /// The attachment's path, without the query that makes it an image preview.
  static String? _documentPath(Map notice) {
    final attachment = notice['attachedFileNotice'];
    if (attachment is! String || attachment.isEmpty) return null;
    final url = json.decode(attachment)['url'];
    if (url is! String || url.isEmpty) return null;
    return Uri.parse(url).path;
  }
}
