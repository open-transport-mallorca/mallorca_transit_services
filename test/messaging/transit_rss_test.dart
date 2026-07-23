import 'dart:io';
// Only the deprecated scrapers need this - which is the point of replacing them.
import 'package:dart_rss/dart_rss.dart' show RssItem;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:mallorca_transit_services/mallorca_transit_services.dart';

/// The markup of a warning page, as served by tib.org.
String warningPage(
    {String description =
        'Due to the celebration of FESTA ROMANA the stops are out of service.',
    String lines = '',
    String document = ''}) {
  return '''
<html><body>
  <div class="avisos-container">
    <h1 class="avisos-container-title">24th July: Temporary bus stop modification in Alcudia</h1>
    <div class="avisos-container-content">
      <div class="avisos-container-content-body" itemprop="articleBody">
        <p>$description</p>
      </div>
    </div>
    <div class="avisos-container-lines">
      <h2 class="avisos-container-lines-header">Routes affected</h2>
      <ul class="avisos-container-lines-body">$lines</ul>
    </div>
    <div class="avisos-container-document">$document</div>
  </div>
</body></html>
''';
}

/// The link to an attached document, as printed on a warning page. The
/// anchor text is localised (`Map`, `Notice`, `Plànol de parades`...) and
/// never reliable; the `.pdf` segment sits mid-path, followed by a Liferay
/// UUID and a cache-busting query string.
String documentLink(
        {String href =
            '/documents/20124/492381/Plano.pdf/9c3b6e1a-1111-2222-3333-abcdef012345?t=1690000000000',
        String text = 'Map'}) =>
    '<p><a href="$href">$text</a></p>';

/// One entry of the affected-lines list, as served by tib.org.
String lineItem(String code, {String? href}) {
  return '''
<li style="background-color: #7E7F75;">
  <a href="${href ?? '/linies-i-horaris/autobus/-/linia/$code'}">
    <span>L$code</span>
  </a>
</li>''';
}

String warningFeed(String items) {
  return '''<?xml version="1.0" encoding="UTF-8"?>
<rss xmlns:dc="http://purl.org/dc/elements/1.1/" version="2.0">
  <channel>
    <title>Avisos TIB</title>
    <link>https://www.tib.org/en/avisos/-/asset_publisher/MvaiWwqbYsHv/rss</link>
    <pubDate>Thu, 23 Jul 2026 15:48:49 GMT</pubDate>
    $items
  </channel>
</rss>''';
}

void main() {
  group('normaliseLineCode', () {
    test('strips the L prefix printed on warning pages', () {
      expect(TransitWarningScraper.normaliseLineCode('L231'), '231');
      expect(TransitWarningScraper.normaliseLineCode('L302'), '302');
      expect(TransitWarningScraper.normaliseLineCode('L322'), '322');
      expect(TransitWarningScraper.normaliseLineCode('L334'), '334');
    });

    test('strips it from the airport lines too', () {
      expect(TransitWarningScraper.normaliseLineCode('LA32'), 'A32');
      expect(TransitWarningScraper.normaliseLineCode('LA42'), 'A42');
    });

    test('keeps a lowercase suffix', () {
      expect(TransitWarningScraper.normaliseLineCode('L411e'), '411e');
      expect(TransitWarningScraper.normaliseLineCode('L343d'), '343d');
    });

    test('leaves an already normalised code alone', () {
      for (final code in ['231', 'A32', '411e', 'M1', 'T1']) {
        expect(TransitWarningScraper.normaliseLineCode(code), code);
      }
    });

    test('trims surrounding whitespace', () {
      expect(TransitWarningScraper.normaliseLineCode('\n  L231 '), '231');
    });

    test('leaves a bare L alone rather than emptying it', () {
      expect(TransitWarningScraper.normaliseLineCode('L'), 'L');
    });
  });

  group('affectedLines', () {
    test('returns codes comparable to RouteLine.code', () async {
      TransitWarningScraper.httpClient = MockClient((request) async {
        return http.Response(
            warningPage(
                lines: [
              lineItem('231'),
              lineItem('302'),
              lineItem('A32'),
              lineItem('411e'),
            ].join()),
            200);
      });

      final lines = await TransitWarningScraper.affectedLines(
          'https://www.tib.org/en/w/avis-festa-romana-alcudia');

      expect(lines, ['231', '302', 'A32', '411e']);
    });

    test('falls back to the anchor text when the href carries no code',
        () async {
      TransitWarningScraper.httpClient = MockClient((request) async {
        return http.Response(
            warningPage(
                lines: [
              lineItem('A32', href: '/en/w/some-other-page'),
              lineItem('411e', href: '/en/w/some-other-page'),
            ].join()),
            200);
      });

      final lines = await TransitWarningScraper.affectedLines(
          'https://www.tib.org/en/w/avis');

      expect(lines, ['A32', '411e']);
    });

    test('drops duplicates and keeps page order', () async {
      TransitWarningScraper.httpClient = MockClient((request) async {
        return http.Response(
            warningPage(
                lines:
                    [lineItem('322'), lineItem('231'), lineItem('322')].join()),
            200);
      });

      final lines =
          await TransitWarningScraper.affectedLines('https://www.tib.org');

      expect(lines, ['322', '231']);
    });

    test('returns an empty list when no lines are listed', () async {
      TransitWarningScraper.httpClient =
          MockClient((request) async => http.Response(warningPage(), 200));

      expect(
          await TransitWarningScraper.affectedLines('https://x.test'), isEmpty);
    });

    test('returns an empty list when the lines block is gone', () async {
      TransitWarningScraper.httpClient = MockClient(
          (request) async => http.Response('<html><body></body></html>', 200));

      expect(
          await TransitWarningScraper.affectedLines('https://x.test'), isEmpty);
    });

    test('throws on a transport failure', () async {
      TransitWarningScraper.httpClient =
          MockClient((request) async => http.Response('Not found', 404));

      expect(TransitWarningScraper.affectedLines('https://x.test'),
          throwsA(isA<HttpException>()));
    });
  });

  group('description', () {
    test('returns the description block text', () async {
      TransitWarningScraper.httpClient = MockClient((request) async =>
          http.Response(warningPage(description: 'Hello'), 200));

      expect(
          await TransitWarningScraper.description('https://x.test'), 'Hello');
    });

    test('returns null when the description block is gone', () async {
      TransitWarningScraper.httpClient = MockClient(
          (request) async => http.Response('<html><body></body></html>', 200));

      expect(await TransitWarningScraper.description('https://x.test'), isNull);
    });

    test('throws on a transport failure', () async {
      TransitWarningScraper.httpClient =
          MockClient((request) async => http.Response('Boom', 500));

      expect(TransitWarningScraper.description('https://x.test'),
          throwsA(isA<HttpException>()));
    });
  });

  group('documentUrl', () {
    test('resolves the relative link against the page URL', () async {
      TransitWarningScraper.httpClient = MockClient((request) async =>
          http.Response(warningPage(document: documentLink()), 200));

      final url = await TransitWarningScraper.documentUrl(
          'https://www.tib.org/en/w/avis-festa-romana-alcudia');

      expect(
          url,
          'https://www.tib.org/documents/20124/492381/Plano.pdf/'
          '9c3b6e1a-1111-2222-3333-abcdef012345?t=1690000000000');
    });

    test('matches a .pdf path segment regardless of the localised link text',
        () async {
      for (final text in [
        'Map',
        'Notice',
        'Plànol de parades',
        'Plànol de parada'
      ]) {
        TransitWarningScraper.httpClient = MockClient((request) async =>
            http.Response(warningPage(document: documentLink(text: text)), 200,
                headers: {'content-type': 'text/html; charset=utf-8'}));

        expect(await TransitWarningScraper.documentUrl('https://www.tib.org'),
            isNotNull);
      }
    });

    test('ignores a link whose path merely ends in pdf-like text', () async {
      TransitWarningScraper.httpClient = MockClient((request) async =>
          http.Response(
              warningPage(document: documentLink(href: '/en/w/avis-not-a-pdf')),
              200));

      expect(await TransitWarningScraper.documentUrl('https://www.tib.org'),
          isNull);
    });

    test('returns null when the page has no attachment', () async {
      TransitWarningScraper.httpClient =
          MockClient((request) async => http.Response(warningPage(), 200));

      expect(await TransitWarningScraper.documentUrl('https://x.test'), isNull);
    });

    test('throws on a transport failure', () async {
      TransitWarningScraper.httpClient =
          MockClient((request) async => http.Response('Boom', 500));

      expect(TransitWarningScraper.documentUrl('https://x.test'),
          throwsA(isA<HttpException>()));
    });
  });

  group('parseFeedDate', () {
    test('parses the RFC 822 pubDate the feed writes', () {
      expect(TransitRss.parseFeedDate('Wed, 22 Jul 2026 22:43:00 GMT'),
          DateTime.utc(2026, 7, 22, 22, 43));
    });

    test('parses a numeric offset', () {
      expect(TransitRss.parseFeedDate('Wed, 22 Jul 2026 22:43:00 +0200'),
          DateTime.utc(2026, 7, 22, 20, 43));
      expect(TransitRss.parseFeedDate('Wed, 22 Jul 2026 22:43:00 -0330'),
          DateTime.utc(2026, 7, 23, 2, 13));
    });

    test('parses the ISO 8601 dc:date', () {
      expect(TransitRss.parseFeedDate('2026-07-22T22:43:00Z'),
          DateTime.utc(2026, 7, 22, 22, 43));
    });

    test('tolerates a missing weekday and seconds', () {
      expect(TransitRss.parseFeedDate('22 Jul 2026 22:43 GMT'),
          DateTime.utc(2026, 7, 22, 22, 43));
    });

    test('reads a two-digit year as RFC 2822 does', () {
      expect(TransitRss.parseFeedDate('Wed, 22 Jul 26 22:43:00 GMT'),
          DateTime.utc(2026, 7, 22, 22, 43));
      expect(TransitRss.parseFeedDate('Sat, 22 Jul 95 22:43:00 GMT'),
          DateTime.utc(1995, 7, 22, 22, 43));
    });

    test('returns null for an empty or unparseable value', () {
      expect(TransitRss.parseFeedDate(null), isNull);
      expect(TransitRss.parseFeedDate(''), isNull);
      expect(TransitRss.parseFeedDate('last tuesday'), isNull);
      expect(TransitRss.parseFeedDate('Wed, 22 Xxx 2026 22:43:00 GMT'), isNull);
    });
  });

  group('getWarnings', () {
    test('builds warnings with a parsed date and a stable id', () async {
      TransitRss.httpClient = MockClient((request) async {
        return http.Response(warningFeed('''
    <item>
      <title>Avis festa romana Alcudia</title>
      <link>https://www.tib.org/en/w/avis-festa-romana-alcudia?redirect=%2Fen</link>
      <description />
      <pubDate>Wed, 22 Jul 2026 22:43:00 GMT</pubDate>
      <guid isPermaLink="false">https://www.tib.org/en/w/avis-festa-romana-alcudia?redirect=%2Fen</guid>
      <dc:date>2026-07-22T22:43:00Z</dc:date>
    </item>'''), 200);
      });

      final warnings = await TransitRss.getWarnings(Language.en);

      expect(warnings, hasLength(1));
      final warning = warnings.single;
      expect(warning.title, 'Avis festa romana Alcudia');
      expect(warning.link,
          'https://www.tib.org/en/w/avis-festa-romana-alcudia?redirect=%2Fen');
      expect(warning.id, warning.link);
      expect(warning.published, DateTime.utc(2026, 7, 22, 22, 43));
      expect(warning.affectedLines, isNull);
      expect(warning.description, isNull);
    });

    test('falls back to pubDate when dc:date is absent', () async {
      TransitRss.httpClient = MockClient((request) async {
        return http.Response(warningFeed('''
    <item>
      <title>Avis</title>
      <link>https://www.tib.org/en/w/avis</link>
      <pubDate>Fri, 17 Jul 2026 06:00:00 GMT</pubDate>
    </item>'''), 200);
      });

      final warnings = await TransitRss.getWarnings(Language.en);

      expect(warnings.single.published, DateTime.utc(2026, 7, 17, 6));
    });

    test('skips items without a link instead of throwing', () async {
      TransitRss.httpClient = MockClient((request) async {
        return http.Response(warningFeed('''
    <item>
      <title>Linkless</title>
      <pubDate>Fri, 17 Jul 2026 06:00:00 GMT</pubDate>
    </item>
    <item>
      <title>Avis</title>
      <link>https://www.tib.org/en/w/avis</link>
    </item>'''), 200);
      });

      final warnings = await TransitRss.getWarnings(Language.en);

      expect(warnings.map((warning) => warning.title), ['Avis']);
    });

    test('requests the feed in the given language', () async {
      late Uri requested;
      TransitRss.httpClient = MockClient((request) async {
        requested = request.url;
        return http.Response(warningFeed(''), 200);
      });

      await TransitRss.getWarnings(Language.de);

      expect(requested.path, startsWith('/de/avisos/'));
    });
  });

  group('TransitWarning', () {
    test(
        'fetchDetails fills description, affected lines and documentUrl in '
        'one request', () async {
      var requests = 0;
      TransitWarningScraper.httpClient = MockClient((request) async {
        requests++;
        return http.Response(
            warningPage(
                description: 'The stops are out of service.',
                lines: [lineItem('231'), lineItem('A32')].join(),
                document: documentLink()),
            200);
      });

      final warning = TransitWarning(
          id: 'https://www.tib.org/en/w/avis',
          link: 'https://www.tib.org/en/w/avis');

      await TransitWarningScraper.fetchDetails(warning);

      expect(requests, 1);
      expect(warning.description, 'The stops are out of service.');
      expect(warning.affectedLines, ['231', 'A32']);
      expect(
          warning.documentUrl,
          'https://www.tib.org/documents/20124/492381/Plano.pdf/'
          '9c3b6e1a-1111-2222-3333-abcdef012345?t=1690000000000');
    });

    test('fetchDetails leaves documentUrl null when the page has none',
        () async {
      TransitWarningScraper.httpClient =
          MockClient((request) async => http.Response(warningPage(), 200));

      final warning = TransitWarning(
          id: 'https://www.tib.org/en/w/avis',
          link: 'https://www.tib.org/en/w/avis');

      await TransitWarningScraper.fetchDetails(warning);

      expect(warning.documentUrl, isNull);
    });

    test('survives a round trip through toJson', () {
      final original = TransitWarning(
          id: 'https://www.tib.org/en/w/avis',
          link: 'https://www.tib.org/en/w/avis',
          title: 'Avis',
          published: DateTime.utc(2026, 7, 22, 22, 43),
          description: 'The stops are out of service.',
          affectedLines: ['231', 'A32'],
          documentUrl: 'https://www.tib.org/documents/20124/492381/Plano.pdf');

      final roundTripped =
          TransitWarning.fromJson(TransitWarning.toJson(original));

      expect(roundTripped.id, original.id);
      expect(roundTripped.link, original.link);
      expect(roundTripped.title, original.title);
      expect(roundTripped.published, original.published);
      expect(roundTripped.description, original.description);
      expect(roundTripped.affectedLines, original.affectedLines);
      expect(roundTripped.documentUrl, original.documentUrl);
    });
  });

  group('NewsScraper', () {
    const newsPage = '''
<html><body>
  <div class="news-container-content">
    <div class="news-container-content-header-image">
      <img class="portada" src="/documents/20124/444202/Noticia.jpg?t=1782995303159" alt="">
    </div>
    <div class="news-container-content-body" itemprop="articleBody">
      <p>First paragraph.</p>
      <p>Second paragraph.</p>
    </div>
  </div>
</body></html>''';

    test('description returns the body paragraphs', () async {
      NewsScraper.httpClient =
          MockClient((request) async => http.Response(newsPage, 200));

      expect(await NewsScraper.description('https://www.tib.org/es/w/n'),
          ['First paragraph.', 'Second paragraph.']);
    });

    test('description returns null when the body block is gone', () async {
      NewsScraper.httpClient = MockClient(
          (request) async => http.Response('<html><body></body></html>', 200));

      expect(await NewsScraper.description('https://x.test'), isNull);
    });

    test('imageUrl resolves the cover image against the page URL', () async {
      NewsScraper.httpClient =
          MockClient((request) async => http.Response(newsPage, 200));

      final imageUrl = await NewsScraper.imageUrl('https://www.tib.org/es/w/n');

      expect(imageUrl.toString(),
          'https://www.tib.org/documents/20124/444202/Noticia.jpg?t=1782995303159');
    });

    test('image downloads the cover image', () async {
      NewsScraper.httpClient = MockClient((request) async {
        if (request.url.path.startsWith('/documents/')) {
          return http.Response.bytes([1, 2, 3], 200);
        }
        return http.Response(newsPage, 200);
      });

      expect(await NewsScraper.image('https://www.tib.org/es/w/n'), [1, 2, 3]);
    });

    test('image returns null when the page has no cover image', () async {
      NewsScraper.httpClient = MockClient(
          (request) async => http.Response('<html><body></body></html>', 200));

      expect(await NewsScraper.image('https://x.test'), isNull);
    });
  });

  group('getNews', () {
    test('builds news items with a parsed date and the feed summary', () async {
      TransitRss.httpClient = MockClient((request) async {
        return http.Response('''<?xml version="1.0" encoding="UTF-8"?>
<rss xmlns:dc="http://purl.org/dc/elements/1.1/" version="2.0">
  <channel>
    <title>Noticies TIB</title>
    <item>
      <title>Conclou el proces</title>
      <link>https://www.tib.org/es/w/conclou-el-proces</link>
      <description>El proces ha finalitzat.</description>
      <pubDate>Wed, 22 Jul 2026 08:00:00 GMT</pubDate>
      <dc:date>2026-07-22T08:00:00Z</dc:date>
    </item>
  </channel>
</rss>''', 200);
      });

      final news = await TransitRss.getNews();

      expect(news, hasLength(1));
      expect(news.single.title, 'Conclou el proces');
      expect(news.single.summary, 'El proces ha finalitzat.');
      expect(news.single.published, DateTime.utc(2026, 7, 22, 8));
      expect(news.single.paragraphs, isNull);
    });
  });

  // The deprecated RssItem forms must keep behaving exactly as they did in
  // 2.5.0, so that upgrading to 2.6.0 changes nothing for a caller still on
  // them. They go in 3.0.0.
  group('deprecated RssItem scrapers', () {
    const item = RssItem(link: 'https://www.tib.org/en/w/avis');

    test('scrapeAffectedLines keeps the L prefix', () async {
      TransitWarningScraper.httpClient = MockClient((request) async {
        return http.Response(
            warningPage(
                lines: [lineItem('231'), lineItem('A32'), lineItem('411e')]
                    .join()),
            200);
      });

      // ignore: deprecated_member_use_from_same_package
      expect(await TransitWarningScraper.scrapeAffectedLines(item),
          ['L231', 'LA32', 'L411e']);
    });

    test('scrapeWarningDescription still throws when the layout changes',
        () async {
      TransitWarningScraper.httpClient = MockClient(
          (request) async => http.Response('<html><body></body></html>', 200));

      expect(
          // ignore: deprecated_member_use_from_same_package
          TransitWarningScraper.scrapeWarningDescription(item),
          throwsA(isA<Exception>()));
    });

    test('scrapeNewsImage throws rather than returning null', () async {
      NewsScraper.httpClient = MockClient(
          (request) async => http.Response('<html><body></body></html>', 200));

      // ignore: deprecated_member_use_from_same_package
      expect(NewsScraper.scrapeNewsImage(item), throwsA(isA<Exception>()));
    });

    test('scrapeNewsImage now downloads an image it used to always throw on',
        () async {
      NewsScraper.httpClient = MockClient((request) async {
        if (request.url.path.startsWith('/documents/')) {
          return http.Response.bytes([1, 2, 3], 200);
        }
        return http.Response('''
<html><body><div class="news-container-content-header-image">
  <img class="portada" src="/documents/20124/Noticia.jpg" alt="">
</div></body></html>''', 200);
      });

      // ignore: deprecated_member_use_from_same_package
      expect(await NewsScraper.scrapeNewsImage(item), [1, 2, 3]);
    });
  });
}
