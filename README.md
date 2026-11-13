# Mallorca Transit Services API

## Features

An unofficial Dart package for the Balearic Islands' Public Transportation services.
It provides a simple way to access Mallorca's transportation services and get information about the bus stops, lines, schedules, etc.

**This package is not affiliated with the government or the respective companies.**

## Getting started

Install the package by adding it to your `pubspec.yaml` file:

```yaml
dependencies:
  mallorca_transit_services: ^2.8.0
```

## Usage

There are two entry points:

- `Tib` for TIB, the interurban buses, trains and metro.
- `Emt` for EMT Palma, the city buses.

## TIB

Create one `Tib` and reuse it, as it fetches TIB's API key once and caches it:

```dart
final tib = Tib();
```

### Stations

Points are `LatLng` from [latlong2](https://pub.dev/packages/latlong2):

```dart
await tib.stations.all();
await tib.stations.byCode('40036');
await tib.stations.byId(984);
await tib.stations.near(LatLng(39.5763, 2.6541), radius: 300);
await tib.stations.inArea(southWest, northEast);
await tib.stations.lines('40036'); // the lines serving it
await tib.stations.photo(984); // image bytes, or null
```

### Departures

```dart
// Live, with `realTrip` for buses that can be tracked.
await tib.departures.next('40036', count: 10);

// From the timetable, at any time.
await tib.departures.at('40036', DateTime(2026, 12, 24, 18));

// A bus or train station's board, with the bays.
await tib.departures.withBays('40036');
```

### Lines

```dart
final lines = await tib.lines.all(activeOnly: true);
final line = (await tib.lines.byCode('401'))!;
final sublines = await tib.lines.sublines(line);
final path = await tib.lines.path(sublines.first);
```

### Timetables

Timetables are PDFs. A line can have several, e.g. a seasonal one, so
`current` picks the one in effect:

```dart
await tib.timetables.forLine(line.id); // newest first
final timetable = await tib.timetables.current(line.id);
print(timetable?.url);
```

### Trips

A trip is one run of a bus, with its stop times:

```dart
await tib.trips.all(); // today's trips
await tib.trips.forLine('401', date: DateTime(2026, 12, 24));
await tib.trips.forSubline('L401-1');
final trip = await tib.trips.byId(departure.tripId);
print(trip?.stops);
```

### Towns

```dart
final towns = await tib.towns.all();
await tib.towns.stations(towns.first.id);
```

### Warnings and news

Both come in Catalan, Spanish, English or German:

```dart
final warnings = await tib.warnings.all(language: Language.en);
print(warnings.first.affectedLineIds); // compare to RouteLine.id
print(warnings.first.documentUrl); // the attached PDF, if any

final news = await tib.news.all(language: Language.en); // newest first
print(news.first.paragraphs);
```

### Real-time tracking

Follow a bus from a live departure's `realTrip`:

```dart
final subscription = tib.realtime.track(departure.realTrip!.id).listen((event) {
  switch (event) {
    case BusPosition position:
      print(position);
    case BusStopped stopped:
      print(stopped);
    case RouteStationInfo info:
      print(info);
    case ConnectionClose():
      print('Trip ended');
  }
});

// Closes the socket.
await subscription.cancel();
```

## EMT Palma

EMT needs a token, which the package gets by creating an anonymous user. Store
it and pass it back, so a new user isn't created on every start:

```dart
final emt = Emt(
    client: EmtClient(
        token: storedToken, // null on the first run
        onToken: (token) => saveToken(token)));
```

### Stops

A stop's id is also the code shown at the stop:

```dart
await emt.stops.all();
await emt.stops.byId(1);
await emt.stops.lines(1); // the lines serving it
```

### Departures

The buses coming to a stop, soonest first, with their bus numbers:

```dart
final departures = await emt.departures.next(1);
print(departures.first.arrival);
```

### Lines

A line has sublines, its variants, and each subline has a route per direction:

```dart
final lines = await emt.lines.all();
final line = (await emt.lines.byId(4))!;
final sublines = await emt.lines.sublines(line);
final routes = await emt.lines.routes(sublines.first);
await emt.lines.stops(routes.first); // in driving order
await emt.lines.path(routes.first);
```

### Timetables

One per day type, e.g. weekdays or Sundays and holidays. Departures are counted
from the start of the service day, so buses after midnight are past 24 hours:

```dart
final timetables = await emt.timetables.forSubline(sublines.first);
print(timetables.first.days.name);
print(timetables.first.directions.first.runs.first.departures);
```

### Alerts and news

Alert titles come in Catalan, Spanish, English or German, but descriptions only
in Catalan and Spanish. English and German news is sparse and often in Spanish:

```dart
final alerts = await emt.alerts.all(language: Language.ca);
print(alerts.first.lineIds); // compare to EmtLine.id
final pdf = await emt.alerts
    .attachment(alerts.first, alerts.first.attachmentIds.first);

final news = await emt.news.all(language: Language.ca); // newest first
print(news.first.imageUrl);
```

## Errors

Requests that fail throw a `TibException` or an `EmtException` with the status
code and URL. Lookups like `byCode` and `byId` return `null` instead when
nothing is found.

## HTTP client

To route requests through your own client, wrap it:

```dart
final tib = Tib(client: TibClient(inner: myClient));
final emt = Emt(client: EmtClient(inner: myClient, token: storedToken));
```

## Caching

Models have `toJson`, and `fromJson(toJson())` gives the same object back, so
they can be cached.

The full example can be found in the [example.dart](example/example.dart)

## Facing Issues?

I'm trying my best to make this API as bug-free as possible, if you find any issues, please submit a bug report in the issues section of this repository.
