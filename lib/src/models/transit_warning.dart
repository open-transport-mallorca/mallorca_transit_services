import 'package:dart_rss/dart_rss.dart';
import 'package:mallorca_transit_services/src/messaging/feed_date.dart';

/// A service warning published on tib.org.
class TransitWarning {
  /// Stable identifier: the feed item's `guid`, or its `link` when absent.
  final String id;

  final String? title;

  /// URL of the warning's page on tib.org, and the argument the
  /// [TransitWarningScraper] methods take.
  final String link;

  /// Publication time, in UTC. `null` when the feed omits the date or writes it
  /// in a format that cannot be parsed.
  final DateTime? published;

  /// The warning's full text. `null` until
  /// [TransitWarningScraper.fetchDetails] has run, and after it when the page
  /// has no description block.
  String? description;

  /// Codes of the affected lines, directly comparable to [RouteLine.code] and
  /// [Departure.lineCode] - see [TransitWarningScraper.affectedLines].
  ///
  /// `null` until [TransitWarningScraper.fetchDetails] has run; empty when the
  /// warning affects no specific line.
  List<String>? affectedLines;

  TransitWarning(
      {required this.id,
      required this.link,
      this.title,
      this.published,
      this.description,
      this.affectedLines});

  /// Returns `null` for an item without a link, which has neither an identity
  /// nor a page to scrape.
  static TransitWarning? fromRssItem(RssItem item) {
    final link = item.link;
    if (link == null || link.isEmpty) return null;
    return TransitWarning(
        id: item.guid ?? link,
        link: link,
        title: item.title,
        published: parseFeedDate(item.dc?.date ?? item.pubDate));
  }

  factory TransitWarning.fromJson(Map json) {
    return TransitWarning(
        id: json['id'],
        link: json['link'],
        title: json['title'],
        published: json['published'] != null
            ? DateTime.tryParse(json['published'])
            : null,
        description: json['description'],
        affectedLines: (json['affectedLines'] as List?)?.cast<String>());
  }

  static Map toJson(TransitWarning warning) {
    return {
      'id': warning.id,
      'link': warning.link,
      'title': warning.title,
      'published': warning.published?.toIso8601String(),
      'description': warning.description,
      'affectedLines': warning.affectedLines,
    };
  }

  @override
  String toString() {
    return 'TransitWarning{id: $id, title: $title, link: $link, published: $published, affectedLines: $affectedLines, description: $description}';
  }
}
