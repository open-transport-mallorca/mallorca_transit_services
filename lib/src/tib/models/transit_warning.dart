import 'package:mallorca_transit_services/src/tib/models/html_text.dart';

/// A service warning, e.g. a stop moved because of roadworks.
class TransitWarning {
  /// E.g. `dxp-ctmr4-5273343`.
  final String id;

  final String title;

  /// Short summary as HTML. Usually empty.
  final String summary;

  /// The warning's text as HTML.
  final String html;

  /// Ids of the affected lines, see [RouteLine.id].
  final List<int> affectedLineIds;

  final DateTime? published;
  final DateTime? modified;

  /// The warning's page on tib.org.
  final Uri link;

  /// The PDF attached to the warning, usually the full notice with maps.
  final Uri? documentUrl;

  TransitWarning(
      {required this.id,
      required this.title,
      this.summary = '',
      required this.html,
      this.affectedLineIds = const [],
      this.published,
      this.modified,
      required this.link,
      this.documentUrl});

  /// [html] as plain-text paragraphs.
  List<String> get paragraphs => htmlParagraphs(html);

  @override
  String toString() {
    return 'TransitWarning{id: $id, title: $title, affectedLineIds: $affectedLineIds, published: $published, modified: $modified, link: $link, documentUrl: $documentUrl}';
  }

  factory TransitWarning.fromJson(Map json) {
    return TransitWarning(
        id: json['id'],
        title: json['tit'],
        summary: json['abs'] ?? '',
        html: json['txt'] ?? '',
        affectedLineIds: (json['afl'] as List?)?.cast<int>() ?? const [],
        published: json['pdt'] != null ? DateTime.tryParse(json['pdt']) : null,
        modified: json['mdt'] != null ? DateTime.tryParse(json['mdt']) : null,
        // Sent with a double slash, e.g. `https://www.tib.org//-/avis`.
        link: _normalise(Uri.parse(json['url'])),
        documentUrl: json['documentUrl'] != null
            ? Uri.tryParse(json['documentUrl'])
            : null);
  }

  /// [documentUrl] isn't part of TIB's JSON; it's kept under `documentUrl`.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tit': title,
      'abs': summary,
      'txt': html,
      'afl': affectedLineIds,
      'pdt': published?.toIso8601String(),
      'mdt': modified?.toIso8601String(),
      'url': link.toString(),
      'documentUrl': documentUrl?.toString(),
    };
  }

  TransitWarning copyWith({Uri? documentUrl}) {
    return TransitWarning(
        id: id,
        title: title,
        summary: summary,
        html: html,
        affectedLineIds: affectedLineIds,
        published: published,
        modified: modified,
        link: link,
        documentUrl: documentUrl ?? this.documentUrl);
  }

  static Uri _normalise(Uri url) =>
      url.replace(path: url.path.replaceAll(RegExp('/+'), '/'));
}
