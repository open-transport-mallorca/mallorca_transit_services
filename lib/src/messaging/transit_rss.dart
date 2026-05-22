import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:dart_rss/dart_rss.dart';
import 'package:http/http.dart';

/// Supported feed languages.
enum Language { ca, es, en, de }

class TransitRss {
  static Future<RssFeed> getWarningFeed(
      [Language language = Language.es]) async {
    final request = await get(Uri.parse(
        "https://www.tib.org/${language.name}/avisos/-/asset_publisher/MvaiWwqbYsHv/rss"));
    return RssFeed.parse(utf8.decode(request.bodyBytes));
  }

  /// WARNING: Not all news are available in all languages.
  static Future<RssFeed> getNewsFeed([Language language = Language.es]) async {
    final request = await get(Uri.parse(
        "https://www.tib.org/${language.name}/noticias/-/asset_publisher/NIwXxcBhaMlh/rss"));
    return RssFeed.parse(utf8.decode(request.bodyBytes));
  }
}

/// Scrapes warning detail pages from [RssItem] links.
class TransitWarningScraper {
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

/// Scrapes news detail pages from [RssItem] links.
class NewsScraper {
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
