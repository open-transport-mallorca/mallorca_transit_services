import 'package:html/parser.dart';

/// The paragraphs and list items of [html] as plain text.
List<String> htmlParagraphs(String? html) {
  if (html == null || html.trim().isEmpty) return [];
  final fragment = parseFragment(html);
  final blocks = fragment.querySelectorAll('p, li, h1, h2, h3, h4, h5, h6');
  final texts =
      blocks.isEmpty ? [fragment.text ?? ''] : blocks.map((b) => b.text);
  return [
    for (final text in texts)
      if (_clean(text).isNotEmpty) _clean(text)
  ];
}

// `\s` also matches non-breaking spaces.
String _clean(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();
