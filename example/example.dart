import 'package:mallorca_transit_services/src/api/departures.dart';
import 'package:mallorca_transit_services/src/api/route_line.dart';
import 'package:mallorca_transit_services/src/api/stations.dart';
import 'package:mallorca_transit_services/src/messaging/transit_rss.dart';

void main() async {
  // Get the list of stations
  final List<Station> stations = await Station.getAllStations();
  print(stations);

  // Get the departures info of the first station
  // Limit to 5 departures
  List<Departure> departures =
      await Departures.getDepartures(stationCode: 51030, numberOfDepartures: 5);
  print(departures);

  // Get the list of lines that pass through the first station
  List<RouteLine> lines = await Station.getLines(stations.first.code);
  print(lines);

  // Get the list of all lines
  final allRoutes = await RouteLine.getAllLines();
  print(allRoutes);

  // Get the list of the line A42 (as an example)
  final route = await RouteLine.getLine('A42');
  final sublines = await Subline.getSublines(route);
  print(sublines);

  // Get the warning feed
  final warnings = await TransitRss.getWarningFeed(Language.en);
  print(warnings.items.first.title);
  print(await TransitWarningScraper.scrapeAffectedLines(warnings.items.first));
  print(await TransitWarningScraper.scrapeWarningDescription(
      warnings.items.first));

  // Get the news feed
  final news = await TransitRss.getNewsFeed(Language.en);
  print(news.items.first.title);
  print(await NewsScraper.scrapeNewsDescription(news.items.first));

  // Get the link to the PDF Timetable of line A42
  final timetablePdf = await RouteLine.getPdfTimetable('A42');
  print(timetablePdf);
}
