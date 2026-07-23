import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:dart_rss/dart_rss.dart';
import 'package:http/http.dart';
import 'package:mallorca_transit_services/src/messaging/feed_date.dart'
    as feed_date;
import 'package:mallorca_transit_services/src/models/transit_news.dart';
import 'package:mallorca_transit_services/src/models/transit_warning.dart';

/// Supported feed languages.
enum Language { ca, es, en, de }

/// Warnings and news published on tib.org.
///
/// [getWarnings] and [getNews] return package-owned models and are the
/// recommended entry points. [getWarningFeed] and [getNewsFeed] expose the raw
/// `dart_rss` feed for consumers that need fields the models do not carry.
class TransitRss {
  static Client httpClient = Client();

  /// The service warnings, most recent first.
  ///
  /// Items without a link are skipped: they carry no identity and no page to
  /// fetch details from.
  static Future<List<TransitWarning>> getWarnings(
      [Language language = Language.es]) async {
    final feed = await getWarningFeed(language);
    return feed.items
        .map(TransitWarning.fromRssItem)
        .whereType<TransitWarning>()
        .toList();
  }

  /// The news items, most recent first.
  ///
  /// WARNING: Not all news are available in all languages.
  static Future<List<TransitNews>> getNews(
      [Language language = Language.es]) async {
    final feed = await getNewsFeed(language);
    return feed.items
        .map(TransitNews.fromRssItem)
        .whereType<TransitNews>()
        .toList();
  }

  /// The raw warning feed. Prefer [getWarnings].
  static Future<RssFeed> getWarningFeed(
      [Language language = Language.es]) async {
    final request = await httpClient.get(Uri.parse(
        "https://www.tib.org/${language.name}/avisos/-/asset_publisher/MvaiWwqbYsHv/rss"));
    return RssFeed.parse(utf8.decode(request.bodyBytes));
  }

  /// The raw news feed. Prefer [getNews].
  ///
  /// WARNING: Not all news are available in all languages.
  static Future<RssFeed> getNewsFeed([Language language = Language.es]) async {
    final request = await httpClient.get(Uri.parse(
        "https://www.tib.org/${language.name}/noticias/-/asset_publisher/NIwXxcBhaMlh/rss"));
    return RssFeed.parse(utf8.decode(request.bodyBytes));
  }

  /// Parses a date as written in the feeds, which [DateTime.tryParse] rejects:
  /// `Wed, 22 Jul 2026 22:43:00 GMT`. Returns UTC.
  ///
  /// The models parse their own dates; this is for consumers reading
  /// [RssItem.pubDate] off [getWarningFeed] directly.
  static DateTime? parseFeedDate(String? value) =>
      feed_date.parseFeedDate(value);
}

/// Scrapes warning detail pages, given the page URL.
class TransitWarningScraper {
  static Client httpClient = Client();

  /// The warning's full text, or `null` when the page has no description block.
  ///
  /// [url] is a warning page URL, i.e. [TransitWarning.link].
  static Future<String?> description(String url) async {
    return _parseDescription(await _fetchDocument(url));
  }

  /// The codes of the lines a warning affects, in page order and without
  /// duplicates.
  ///
  /// The codes are normalised by [normaliseLineCode], so they can be compared
  /// directly against [RouteLine.code] and [Departure.lineCode]. Returns an
  /// empty list when the warning affects no specific line.
  ///
  /// [url] is a warning page URL, i.e. [TransitWarning.link].
  static Future<List<String>> affectedLines(String url) async {
    return _parseAffectedLines(await _fetchDocument(url));
  }

  /// URL of the document (usually a PDF) attached to the warning, resolved
  /// against [url]. Returns `null` when the page has no such attachment.
  ///
  /// [url] is a warning page URL, i.e. [TransitWarning.link].
  static Future<String?> documentUrl(String url) async {
    return _parseDocumentUrl(await _fetchDocument(url), url);
  }

  /// Fills [TransitWarning.description], [TransitWarning.affectedLines] and
  /// [TransitWarning.documentUrl] from the warning's page, in a single
  /// request, and returns the same warning.
  ///
  /// Throws only on a transport failure; a page whose layout no longer matches
  /// leaves the description null and the lines empty.
  static Future<TransitWarning> fetchDetails(TransitWarning warning) async {
    final document = await _fetchDocument(warning.link);
    warning.description = _parseDescription(document);
    warning.affectedLines = _parseAffectedLines(document);
    warning.documentUrl = _parseDocumentUrl(document, warning.link);
    return warning;
  }

  /// Strips the leading `L` that warning pages print in front of every line
  /// code.
  static String normaliseLineCode(String code) {
    final trimmed = code.trim();
    if (trimmed.length > 1 && trimmed.startsWith('L')) {
      return trimmed.substring(1);
    }
    return trimmed;
  }

  /// Superseded by [description], which takes a URL instead of an [RssItem] and
  /// returns `null` rather than throwing when the page layout changes.
  @Deprecated('Use TransitWarningScraper.description(url). Removed in 3.0.0.')
  static Future<String?> scrapeWarningDescription(RssItem rssItem) async {
    try {
      final body = await httpClient.get(Uri.parse(rssItem.link!));
      if (body.statusCode != 200) {
        throw HttpException(
            'Failed to scrape warning description, ${body.statusCode}');
      }
      final parser = parse(utf8.decode(body.bodyBytes));
      final results =
          parser.getElementsByClassName('avisos-container-content-body');
      return results[0].text.trim();
    } catch (e) {
      throw Exception('Failed to scrape warning description, $e');
    }
  }

  /// Superseded by [affectedLines].
  ///
  /// This returns the codes as printed on the page, with the `L` prefix
  /// (`L231`, `LA32`), which matches nothing in [RouteLine.code] or
  /// [Departure.lineCode]. [affectedLines] normalises them; [normaliseLineCode]
  /// does the same to a value from here.
  @Deprecated('Use TransitWarningScraper.affectedLines(url), which returns '
      'codes without the L prefix. Removed in 3.0.0.')
  static Future<List<String?>> scrapeAffectedLines(RssItem rssItem) async {
    try {
      final body = await httpClient.get(Uri.parse(rssItem.link!));
      if (body.statusCode != 200) {
        throw HttpException(
            'Failed to scrape affected lines, ${body.statusCode}');
      }
      final document = parse(utf8.decode(body.bodyBytes));
      final lines = <String>[];
      for (final container
          in document.getElementsByClassName('avisos-container-lines-body')) {
        for (final anchor in container.querySelectorAll('a')) {
          if (anchor.text.trim().isNotEmpty) {
            lines.add(anchor.text.trim());
          }
        }
      }
      return lines;
    } catch (e) {
      throw Exception('Failed to scrape affected lines');
    }
  }

  static String? _parseDescription(Document document) {
    final results =
        document.getElementsByClassName('avisos-container-content-body');
    if (results.isEmpty) return null;
    return results.first.text.trim();
  }

  static List<String> _parseAffectedLines(Document document) {
    final lines = <String>[];
    for (final container
        in document.getElementsByClassName('avisos-container-lines-body')) {
      for (final anchor in container.querySelectorAll('a')) {
        // The href carries the canonical code (`/-/linia/A32`); the anchor text
        // is the `L`-prefixed label. Prefer the former, fall back to the latter.
        final code = _codeFromHref(anchor.attributes['href']) ?? anchor.text;
        final normalised = normaliseLineCode(code);
        if (normalised.isNotEmpty && !lines.contains(normalised)) {
          lines.add(normalised);
        }
      }
    }
    return lines;
  }

  /// The first link on the page whose path has a segment ending in `.pdf`,
  /// resolved against [pageUrl]. The `.pdf` segment is not necessarily the end
  /// of the path (Liferay appends `/<uuid>?t=<ts>` after it), and the anchor
  /// text is localised, so neither can be used to find it.
  static String? _parseDocumentUrl(Document document, String pageUrl) {
    for (final anchor in document.querySelectorAll('a')) {
      final href = anchor.attributes['href'];
      if (href == null || href.isEmpty) continue;
      final segments = Uri.tryParse(href)?.pathSegments;
      if (segments == null) continue;
      if (segments.any((segment) => segment.toLowerCase().endsWith('.pdf'))) {
        return Uri.parse(pageUrl).resolve(href).toString();
      }
    }
    return null;
  }

  static String? _codeFromHref(String? href) {
    if (href == null) return null;
    final segments = Uri.tryParse(href)?.pathSegments;
    if (segments == null) return null;
    final index = segments.indexOf('linia');
    if (index == -1 || index + 1 >= segments.length) return null;
    final code = segments[index + 1].trim();
    return code.isEmpty ? null : code;
  }

  static Future<Document> _fetchDocument(String url) =>
      _fetch(httpClient, url, 'warning');
}

/// Scrapes news detail pages, given the page URL.
class NewsScraper {
  static Client httpClient = Client();

  /// The paragraphs of the article body, or `null` when the page has no body
  /// block.
  ///
  /// [url] is a news page URL, i.e. [TransitNews.link].
  static Future<List<String>?> description(String url) async {
    return _parseDescription(await _fetchDocument(url));
  }

  /// The URL of the article's cover image, or `null` when it has none.
  static Future<Uri?> imageUrl(String url) async {
    return _parseImageUrl(await _fetchDocument(url), url);
  }

  /// The bytes of the article's cover image, or `null` when it has none.
  static Future<Uint8List?> image(String url) async {
    final source = await imageUrl(url);
    if (source == null) return null;
    return _fetchImage(source);
  }

  /// Fills [TransitNews.paragraphs] and [TransitNews.imageUrl] from the news
  /// page, in a single request, and returns the same item.
  ///
  /// Throws only on a transport failure; a page whose layout no longer matches
  /// leaves both null.
  static Future<TransitNews> fetchDetails(TransitNews news) async {
    final document = await _fetchDocument(news.link);
    news.paragraphs = _parseDescription(document);
    news.imageUrl = _parseImageUrl(document, news.link);
    return news;
  }

  /// Superseded by [description], which takes a URL instead of an [RssItem].
  @Deprecated('Use NewsScraper.description(url). Removed in 3.0.0.')
  static Future<List<String>?> scrapeNewsDescription(RssItem rssItem) async {
    try {
      return await description(rssItem.link!);
    } catch (e) {
      throw Exception('Failed to scrape news description');
    }
  }

  /// Superseded by [image], which takes a URL and returns `null` for an article
  /// with no cover image rather than throwing.
  @Deprecated('Use NewsScraper.image(url). Removed in 3.0.0.')
  static Future<Uint8List> scrapeNewsImage(RssItem rssItem) async {
    try {
      final source = await imageUrl(rssItem.link!);
      if (source == null) {
        throw const HttpException('The article has no cover image');
      }
      return await _fetchImage(source);
    } catch (e) {
      throw Exception('Failed to scrape news image');
    }
  }

  static Future<Uint8List> _fetchImage(Uri source) async {
    final response = await httpClient.get(source);
    if (response.statusCode != 200) {
      throw HttpException('Failed to fetch news image, ${response.statusCode}',
          uri: source);
    }
    return response.bodyBytes;
  }

  static List<String>? _parseDescription(Document document) {
    final results =
        document.getElementsByClassName('news-container-content-body');
    if (results.isEmpty) return null;
    return results.first
        .querySelectorAll('p')
        .map((paragraph) => paragraph.text.trim())
        .toList();
  }

  static Uri? _parseImageUrl(Document document, String pageUrl) {
    final image = document.querySelector('img.portada');
    final source = image?.attributes['src'];
    if (source == null || source.isEmpty) return null;
    // The src is root-relative, e.g. `/documents/20124/...`.
    return Uri.parse(pageUrl).resolve(source);
  }

  static Future<Document> _fetchDocument(String url) =>
      _fetch(httpClient, url, 'news');
}

Future<Document> _fetch(Client client, String url, String what) async {
  final uri = Uri.parse(url);
  final response = await client.get(uri);
  if (response.statusCode != 200) {
    throw HttpException('Failed to fetch $what page, ${response.statusCode}',
        uri: uri);
  }
  return parse(utf8.decode(response.bodyBytes));
}
