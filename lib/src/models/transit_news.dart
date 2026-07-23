import 'package:dart_rss/dart_rss.dart';
import 'package:mallorca_transit_services/src/messaging/feed_date.dart';

/// A news item published on tib.org.
class TransitNews {
  /// Stable identifier: the feed item's `guid`, or its `link` when absent.
  final String id;

  final String? title;

  /// URL of the news page on tib.org, and the argument the [NewsScraper]
  /// methods take.
  final String link;

  /// Publication time, in UTC. See [TransitWarning.published].
  final DateTime? published;

  /// The item's summary as published in the feed, if any.
  final String? summary;

  /// The paragraphs of the article body. `null` until
  /// [NewsScraper.fetchDetails] has run, and after it when the page has no body
  /// block.
  List<String>? paragraphs;

  /// The article's cover image. `null` until [NewsScraper.fetchDetails] has
  /// run, and after it when the page carries no cover image.
  Uri? imageUrl;

  TransitNews(
      {required this.id,
      required this.link,
      this.title,
      this.published,
      this.summary,
      this.paragraphs,
      this.imageUrl});

  /// Returns `null` for an item without a link. See
  /// [TransitWarning.fromRssItem].
  static TransitNews? fromRssItem(RssItem item) {
    final link = item.link;
    if (link == null || link.isEmpty) return null;
    return TransitNews(
        id: item.guid ?? link,
        link: link,
        title: item.title,
        summary: item.description,
        published: parseFeedDate(item.dc?.date ?? item.pubDate));
  }

  factory TransitNews.fromJson(Map json) {
    return TransitNews(
        id: json['id'],
        link: json['link'],
        title: json['title'],
        published: json['published'] != null
            ? DateTime.tryParse(json['published'])
            : null,
        summary: json['summary'],
        paragraphs: (json['paragraphs'] as List?)?.cast<String>(),
        imageUrl:
            json['imageUrl'] != null ? Uri.tryParse(json['imageUrl']) : null);
  }

  static Map toJson(TransitNews news) {
    return {
      'id': news.id,
      'link': news.link,
      'title': news.title,
      'published': news.published?.toIso8601String(),
      'summary': news.summary,
      'paragraphs': news.paragraphs,
      'imageUrl': news.imageUrl?.toString(),
    };
  }

  @override
  String toString() {
    return 'TransitNews{id: $id, title: $title, link: $link, published: $published, summary: $summary, paragraphs: $paragraphs, imageUrl: $imageUrl}';
  }
}
