import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:dart_rss/dart_rss.dart';
import 'package:http/http.dart';

/// An enum that represents the language of the RSS feed.
enum Language { ca, es, en, de }

/// A class that represents the RSS feed.
/// The feed has a list of items.
/// Each item is a warning or news article.
/// The [getWarningFeed] method returns the warning feed.
/// The [getNewsFeed] method returns the news feed.
class TransitRss {
  /// Get the warning feed from the RSS.
  /// Returns a [RssFeed] object with the warning feed.
  static Future<RssFeed> getWarningFeed(
      [Language language = Language.es]) async {
    final request = await get(Uri.parse(
        "https://www.tib.org/${language.name}/avisos/-/asset_publisher/MvaiWwqbYsHv/rss"));
    return RssFeed.parse(utf8.decode(request.bodyBytes));
  }

  /// Get the news feed from the RSS.
  /// Returns a [RssFeed] object with the news feed.
  ///
  /// The [language] parameter is the language of the feed.
  ///
  /// WARNING: Not all news are available in all languages.
  static Future<RssFeed> getNewsFeed([Language language = Language.es]) async {
    final request = await get(Uri.parse(
        "https://www.tib.org/${language.name}/noticias/-/asset_publisher/NIwXxcBhaMlh/rss"));
    return RssFeed.parse(utf8.decode(request.bodyBytes));
  }
}

/// A class that scrapes the warning feed.
/// The [scrapeWarningDescription] method scrapes the warning description.
/// The [scrapeAffectedLines] method scrapes the affected lines.
class TransitWarningScraper {
  /// Scrape the warning description from a warning item.
  /// The [rssItem] parameter is the warning item to scrape.
  /// Returns a string with the warning description.
  static Future<String?> scrapeWarningDescription(RssItem rssItem) async {
    try {
      final body = await get(Uri.parse(rssItem.link!));
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

  /// Scrape the affected lines from a warning item.
  /// The [rssItem] parameter is the warning item to scrape.
  /// Returns a list of strings with the affected lines.
  static Future<List<String?>> scrapeAffectedLines(RssItem rssItem) async {
    try {
      final body = await get(Uri.parse(rssItem.link!));
      if (body.statusCode != 200) {
        throw HttpException(
            'Failed to scrape warning description, ${body.statusCode}');
      }
      final parser = parse(utf8.decode(body.bodyBytes));
      List<Element> results =
          parser.getElementsByClassName('avisos-container-lines-body');
      List<String> lines = [];
      for (var value in results) {
        for (var element in parse(value.innerHtml).getElementsByTagName('a')) {
          if (element.text.isNotEmpty) {
            lines.add(element.text.trim());
          }
        }
      }

      return lines;
    } catch (e) {
      throw Exception('Failed to scrape affected lines');
    }
  }
}

/// A class that scrapes the news feed.
/// The [scrapeNewsDescription] method scrapes the news description.
/// The [scrapeNewsImage] method scrapes the news image.
class NewsScraper {
  /// Scrape the news description from a news item.
  /// The [rssItem] parameter is the news item to scrape.
  /// Returns a list of strings with the news description.
  static Future<List<String>?> scrapeNewsDescription(RssItem rssItem) async {
    try {
      final body = await get(Uri.parse(rssItem.link!));
      if (body.statusCode != 200) {
        throw HttpException(
            'Failed to scrape warning description, ${body.statusCode}');
      }
      final parser = parse(utf8.decode(body.bodyBytes));
      List<String> bodyText = [];
      final div =
          parser.getElementsByClassName('news-container-content-body').first;
      List<Element> results = div.querySelectorAll('p');
      for (var value in results) {
        bodyText.add(value.text.trim());
      }
      return bodyText;
    } catch (e) {
      throw Exception('Failed to scrape news description');
    }
  }

  /// Scrape the news image from a news item.
  /// The [rssItem] parameter is the news item to scrape.
  /// Returns a [Uint8List] with the news image.
  /// Throws an exception if the image cannot be scraped.
  static Future<Uint8List> scrapeNewsImage(RssItem rssItem) async {
    try {
      final body = await get(Uri.parse(rssItem.link!));
      if (body.statusCode != 200) {
        throw HttpException(
            'Failed to scrape warning description, ${body.statusCode}');
      }
      final parsed = parse(utf8.decode(body.bodyBytes));
      final parser = parsed.getElementsByTagName('img').first;
      List<Element> results = parser.getElementsByClassName('portada');
      final imageLink = await get(
          Uri.parse("https://tib.org/${results.first.attributes["src"]}"));
      return imageLink.bodyBytes;
    } catch (e) {
      throw Exception('Failed to scrape news image');
    }
  }
}
