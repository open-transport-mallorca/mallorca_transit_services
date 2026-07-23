import 'dart:convert';
import 'package:mallorca_transit_services/mallorca_transit_services.dart';

void main() async {
  // Get the list of stations
  final stations = await StationsApi.getAllStations();
  print(stations);

  // Get a specific station by its ID
  final station = await StationsApi.fromId(51030);
  print(station);

  // Get the departures info of the first station
  // Limit to 5 departures
  final departures = await DeparturesApi.getDepartures(
      stationCode: "51030", numberOfDepartures: 5);
  print(departures);

  // Get the list of lines that pass through the first station
  final lines = await StationsApi.getLines(stations.first.code);
  print(lines);

  // Get the list of all lines
  final allRoutes = await RouteLinesApi.getAllLines();
  print(allRoutes);

  // Get the list of the line A42 (as an example)
  final route = await RouteLinesApi.getLine('A42');
  final sublines = await RouteLinesApi.getSublines(route);
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
  final timetablePdf = await RouteLinesApi.getPdfTimetable('A42');
  print(timetablePdf);

  // Listen to real-time bus updates
  final realTripId = departures
      .firstWhere((departure) => departure.realTrip != null)
      .realTrip
      ?.id; // For example, take the first departure that has tracking info

  if (realTripId == null) {
    print("No real-time trip information available.");
    return;
  }
  final locationStream = LocationWebSocket.locationStream(realTripId);
  print("Listening to real-time bus updates for trip ID: $realTripId");
  locationStream.listen(
    (message) {
      final decoded = jsonDecode(message);
      final parsedMessage = LocationWebSocket.locationParser(decoded);
      print(parsedMessage);
    },
    onError: (error) {
      print("WebSocket error: $error");
    },
    onDone: () {
      print("WebSocket closed");
    },
  );
}
