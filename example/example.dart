import 'package:mallorca_transit_services/mallorca_transit_services.dart';

void main() async {
  // One instance for the whole app: it fetches the API key once
  final tib = Tib();

  // Get the list of stations
  final stations = await tib.stations.all();
  print(stations);

  // Get a specific station by its code
  final station = await tib.stations.byCode('51030');
  print(station);

  // Get the departures info of the first station
  // Limit to 5 departures
  final departures = await tib.departures.next('51030', count: 5);
  print(departures);

  // Get the list of lines that pass through the first station
  final lines = await tib.stations.lines(stations.first.code);
  print(lines);

  // Get the list of all lines
  final allRoutes = await tib.lines.all();
  print(allRoutes);

  // Get the list of the line A42 (as an example)
  final route = await tib.lines.byCode('A42');
  final sublines = await tib.lines.sublines(route!);
  print(sublines);

  // Get the service warnings
  final warnings = await TransitRss.getWarnings(Language.en);
  final warning = warnings.first;
  print('${warning.title} (${warning.published})');

  // Fetch the description and the affected lines of a warning, in one request.
  await TransitWarningScraper.fetchDetails(warning);
  print(warning.affectedLines);
  print(warning.description);

  // Only the URL is needed to scrape, so a cached warning can be refreshed
  // without keeping the feed item around.
  print(await TransitWarningScraper.affectedLines(warning.link));
  print(await TransitWarningScraper.description(warning.link));

  // Get the news
  final news = await TransitRss.getNews(Language.en);
  print(news.first.title);
  print(await NewsScraper.description(news.first.link));

  // Get the link to the PDF Timetable of line A42
  final timetablePdf = await tib.lines.pdfTimetable('A42');
  print(timetablePdf);

  // Listen to real-time bus updates
  // For example, take the first departure that has tracking info
  final realTripId = departures
      .map((departure) => departure.realTrip?.id)
      .nonNulls
      .firstOrNull;

  if (realTripId == null) {
    print("No real-time trip information available.");
    return;
  }
  print("Listening to real-time bus updates for trip ID: $realTripId");
  // Cancelling the subscription closes the socket
  tib.realtime.track(realTripId).listen(
    (event) {
      print(event);
    },
    onError: (error) {
      print("WebSocket error: $error");
    },
    onDone: () {
      print("WebSocket closed");
    },
  );
}
