part of 'tib.dart';

/// TIB's news.
class TibNews {
  final Tib _tib;

  TibNews._(this._tib);

  /// All articles, newest first.
  Future<List<TransitNews>> all({Language language = Language.es}) async {
    final news = <TransitNews>[];
    // Paged, and requesting past the last page fails.
    for (var page = 1; page != -1;) {
      final url = await _tib.client.sictmws('news/${_tib.entity}',
          {'lng': language.locale, 'res': '100', 'pag': '$page'});
      final body = Tib._json(await _tib._get(url));
      news.addAll([
        for (final Map article in body['newsInfos'])
          TransitNews.fromJson(article)
      ]);
      page = body['pag']?['nxt'] ?? -1;
    }
    // Not sent in order.
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    return news
      ..sort((a, b) => (b.published ?? epoch).compareTo(a.published ?? epoch));
  }
}
