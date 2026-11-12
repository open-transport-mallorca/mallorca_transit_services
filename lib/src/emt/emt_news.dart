part of 'emt.dart';

class EmtNews {
  final Emt _emt;

  EmtNews._(this._emt);

  /// Newest first. English and German articles are often in Spanish.
  Future<List<EmtArticle>> all({Language language = Language.es}) async {
    const pageSize = 100;
    final articles = <EmtArticle>[];
    // Pages start at 1. EMT's total is unreliable, so read until a page
    // comes back short.
    for (var page = 1;; page++) {
      final url = _emt.client.url('notice/', {
        'locale': language.name,
        'pageNumber': '$page',
        'elementsPerPage': '$pageSize',
      });
      final List data = Emt._json(await _emt._get(url))['data'];
      articles.addAll(
          [for (final Map article in data) EmtArticle.fromJson(article)]);
      if (data.length < pageSize) break;
    }
    return articles..sort((a, b) => b.published.compareTo(a.published));
  }
}
