import 'package:test/test.dart';
import 'package:mallorca_transit_services/mallorca_transit_services.dart';

/// A notice as sent by SICTMWS.
final noticeJson = {
  'abs': '',
  'afl': [3129, 3126],
  'id': 'dxp-ctmr4-3800363',
  'mdt': '2026-07-03',
  'pdt': '2026-06-10',
  'tit': 'Traslado de paradas en Sant Llorenç',
  'txt': '<p>Debido a obras,&nbsp;las paradas <em>Sant Llorenç 1</em> quedan '
      'suprimidas:</p>\n\n<ul>\n\t<li>Hacia Manacor (411, 412)</li>\n</ul>',
  'url': 'https://www.tib.org//-/avis-obres-st-llorenc',
};

/// An article as sent by SICTMWS.
final newsJson = {
  'abs': '<p><em>Se refuerza la oferta</em></p>',
  'dat': '2026-03-26',
  'id': 3492691,
  'img': 'https://www.tib.org/documents/cover.jpg',
  'imga': 'https://www.tib.org/documents/thumb.jpg',
  'imp': false,
  'mdt': '2026-03-27',
  'tit': 'Nuevos horarios de verano',
  'txt': '<p style="margin:0"><span>El Govern mejora el servicio.</span></p>'
      '<p>&nbsp;</p><p>Más líneas.</p>',
  'url': 'https://www.tib.org/-/nuevos-horarios',
};

void main() {
  group('TransitWarning', () {
    test('fromJson maps every field', () {
      final warning = TransitWarning.fromJson(noticeJson);

      expect(warning.id, 'dxp-ctmr4-3800363');
      expect(warning.title, 'Traslado de paradas en Sant Llorenç');
      expect(warning.summary, '');
      expect(warning.affectedLineIds, [3129, 3126]);
      expect(warning.published, DateTime(2026, 6, 10));
      expect(warning.modified, DateTime(2026, 7, 3));
      expect(warning.documentUrl, isNull);
    });

    test('fromJson fixes the double slash in the link', () {
      expect(TransitWarning.fromJson(noticeJson).link.toString(),
          'https://www.tib.org/-/avis-obres-st-llorenc');
    });

    test('paragraphs turns the HTML into plain text', () {
      expect(TransitWarning.fromJson(noticeJson).paragraphs, [
        'Debido a obras, las paradas Sant Llorenç 1 quedan suprimidas:',
        'Hacia Manacor (411, 412)',
      ]);
    });

    test('fromJson(toJson(x)) keeps every field', () {
      final warning = TransitWarning.fromJson(noticeJson).copyWith(
          documentUrl: Uri.parse('https://www.tib.org/documents/d/ctm/avis'));

      final roundTripped = TransitWarning.fromJson(warning.toJson());

      expect(roundTripped.toString(), warning.toString());
      expect(roundTripped.html, warning.html);
    });
  });

  group('TransitNews', () {
    test('fromJson maps every field', () {
      final news = TransitNews.fromJson(newsJson);

      expect(news.id, 3492691);
      expect(news.title, 'Nuevos horarios de verano');
      expect(news.summaryParagraphs, ['Se refuerza la oferta']);
      expect(news.paragraphs, ['El Govern mejora el servicio.', 'Más líneas.']);
      expect(news.published, DateTime(2026, 3, 26));
      expect(news.modified, DateTime(2026, 3, 27));
      expect(news.featured, isFalse);
      expect(
          news.imageUrl.toString(), 'https://www.tib.org/documents/cover.jpg');
      expect(news.thumbnailUrl.toString(),
          'https://www.tib.org/documents/thumb.jpg');
      expect(news.link.toString(), 'https://www.tib.org/-/nuevos-horarios');
    });

    test('fromJson falls back to the modification date', () {
      final news = TransitNews.fromJson({...newsJson}..remove('dat'));

      expect(news.published, DateTime(2026, 3, 27));
    });

    test('fromJson reads null for a missing thumbnail', () {
      final news = TransitNews.fromJson({...newsJson}..remove('imga'));

      expect(news.thumbnailUrl, isNull);
    });

    test('fromJson(toJson(x)) keeps every field', () {
      final news = TransitNews.fromJson(newsJson);

      expect(TransitNews.fromJson(news.toJson()).toString(), news.toString());
    });
  });
}
