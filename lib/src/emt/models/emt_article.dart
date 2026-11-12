import 'package:mallorca_transit_services/src/emt/emt_client.dart';
import 'package:mallorca_transit_services/src/tib/models/html_text.dart';

class EmtArticle {
  final int id;
  final String title;
  final String summary;

  /// The article as HTML.
  final String html;

  final DateTime published;
  final int? imageId;

  EmtArticle(
      {required this.id,
      required this.title,
      this.summary = '',
      required this.html,
      required this.published,
      this.imageId});

  /// [html] as plain-text paragraphs.
  List<String> get paragraphs => htmlParagraphs(html);

  /// The cover image. Unlike the rest of the API, it needs no token.
  Uri? get imageUrl => imageId != null
      ? EmtClient.baseUrl.resolve('image/download/$imageId')
      : null;

  @override
  String toString() {
    return 'EmtArticle{id: $id, title: $title, published: $published, imageId: $imageId}';
  }

  factory EmtArticle.fromJson(Map json) {
    return EmtArticle(
        id: json['id'],
        title: (json['title'] as String).trim(),
        summary: (json['summary'] as String? ?? '').trim(),
        html: json['description'] ?? '',
        published: DateTime.parse(json['publishedAt']),
        imageId: json['image']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'description': html,
      'publishedAt': published.toIso8601String(),
      'image': imageId,
    };
  }
}
