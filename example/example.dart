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

  // Get the sublines of line 401 (as an example)
  final route = await tib.lines.byCode('401');
  final sublines = await tib.lines.sublines(route!);
  print(sublines);

  // Get the service warnings, with the ids of the lines they affect
  final warnings = await tib.warnings.all(language: Language.en);
  final warning = warnings.first;
  print('${warning.title} (${warning.published})');
  print(warning.affectedLineIds);
  print(warning.paragraphs);
  print(warning.documentUrl);

  // Get the news, newest first
  final news = await tib.news.all(language: Language.en);
  print(news.first.title);
  print(news.first.paragraphs);

  // Get the PDF timetable line 401 runs on today
  final timetable = await tib.timetables.current(3066);
  print(timetable?.url);

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
