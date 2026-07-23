# Mallorca Transit Services API

## Features

An unofficial Dart package for the Balearic Islands' Public Transportation services.
It provides a simple way to access Mallorca's transportation services and get information about the bus stops, lines, schedules, etc.

**This package is not affiliated with the government or the respective companies.**

## Getting started

Install the package by adding it to your `pubspec.yaml` file:

```yaml
dependencies:
  mallorca_transit_services: ^2.6.0
```

## Usage

Get the list of bus stops:

```dart
await Stations.getStations();
```

Get the list of departures from a specific bus stop:

```dart
await Departures.getDepartures(stationId: id, numberOfDepartures: 10);
```

Get a list of lines that pass through a specific bus stop:

```dart
await Station.getLines(stationCode);
```

Get the list of all lines:

```dart
await RouteLine.getAllLines();
```

Get specific line information:

```dart
await RouteLine.getLine('A42');
```

Get the route of a specific line:

```dart
await RoutePath.getPath(route.code);
```

Listen to real-time updates of a specific bus:

```dart
LocationWebSocket.locationStream(busId).then((stream) {
    stream.listen((message) {
      final action = LocationWebSocket.locationParser(jsonDecode(message));
    });
  });
```

Get the public service warnings:

```dart
final warnings = await TransitRss.getWarnings();
```

Each warning carries an `id`, a `title`, a `link`, and a `published` `DateTime`.
Its description and affected lines live on its page, so they are fetched
separately - in a single request:

```dart
await TransitWarningScraper.fetchDetails(warning);
print(warning.description);
print(warning.affectedLines); // ['231', '302', 'A32']
```

The line codes are normalised: warning pages print `L231`, `LA32` and `L411e`,
but `affectedLines` gives `231`, `A32` and `411e`, so they can be compared to
`RouteLine.code` and `Departure.lineCode` directly.

Get the public news:

```dart
final news = await TransitRss.getNews();
await NewsScraper.fetchDetails(news.first); // fills paragraphs and imageUrl
```

The scrapers take a page URL, so a cached warning can be refreshed without
keeping the feed item around:

```dart
await TransitWarningScraper.affectedLines(url);
await TransitWarningScraper.description(url);
await NewsScraper.description(url);
```

The `RssItem`-taking forms (`scrapeAffectedLines`, `scrapeWarningDescription`,
`scrapeNewsDescription`, `scrapeNewsImage`) still work but are deprecated, and
go in 3.0.0. Note `scrapeAffectedLines` keeps the `L` prefix.

The raw `dart_rss` feeds are still available if you need a field the models do
not carry:

```dart
await TransitRss.getWarningFeed();
await TransitRss.getNewsFeed();
```

Scrape the website for the timetable PDF of a specific line:

```dart
await RouteLine.getPdfTimetable('A42');
```

The full example can be found in the [example.dart](example/example.dart)

## Facing Issues?

I'm trying my best to make this API as bug-free as possible, if you find any issues, please submit a bug report in the issues section of this repository.
