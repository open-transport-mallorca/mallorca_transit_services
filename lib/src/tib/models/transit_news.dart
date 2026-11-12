import 'package:mallorca_transit_services/src/tib/models/html_text.dart';

/// A news article from TIB.
class TransitNews {
  final int id;

  final String title;

  /// Short summary as HTML.
  final String summary;

  /// The article as HTML.
  final String html;

  /// Falls back to [modified] for articles without a date.
  final DateTime? published;
  final DateTime? modified;

  /// Whether TIB features the article.
  final bool featured;

  /// The cover image.
  final Uri? imageUrl;

  /// A smaller image for lists.
  final Uri? thumbnailUrl;

  /// The article's page on tib.org.
  final Uri link;

  TransitNews(
      {required this.id,
      required this.title,
      this.summary = '',
      required this.html,
      this.published,
      this.modified,
      this.featured = false,
      this.imageUrl,
      this.thumbnailUrl,
      required this.link});

  /// [html] as plain-text paragraphs.
  List<String> get paragraphs => htmlParagraphs(html);

  /// [summary] as plain-text paragraphs.
  List<String> get summaryParagraphs => htmlParagraphs(summary);

  @override
  String toString() {
    return 'TransitNews{id: $id, title: $title, published: $published, modified: $modified, featured: $featured, imageUrl: $imageUrl, thumbnailUrl: $thumbnailUrl, link: $link}';
  }

  factory TransitNews.fromJson(Map json) {
    final modified = _date(json['mdt']);
    return TransitNews(
        id: json['id'],
        title: json['tit'],
        summary: json['abs'] ?? '',
        html: json['txt'] ?? '',
        published: _date(json['dat']) ?? modified,
        modified: modified,
        featured: json['imp'] ?? false,
        imageUrl: _url(json['img']),
        thumbnailUrl: _url(json['imga']),
        link: Uri.parse(json['url']));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tit': title,
      'abs': summary,
      'txt': html,
      'dat': published?.toIso8601String(),
      'mdt': modified?.toIso8601String(),
      'imp': featured,
      'img': imageUrl?.toString(),
      'imga': thumbnailUrl?.toString(),
      'url': link.toString(),
    };
  }

  static DateTime? _date(String? value) =>
      value != null ? DateTime.tryParse(value) : null;

  static Uri? _url(String? value) =>
      value != null && value.isNotEmpty ? Uri.tryParse(value) : null;
}
