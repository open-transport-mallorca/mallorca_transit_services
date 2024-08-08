# Mallorca Transit Services API

## Features

An unofficial Dart package for the Balearic Islands' Public Transportation services.
It provides a simple way to access Mallorca's transportation services and get information about the bus stops, lines, schedules, etc.

**This package is not affiliated with the government or the respective companies.**

## Getting started

Install the package by adding it to your `pubspec.yaml` file:

```yaml
dependencies:
  mallorca_transit_services: ^0.5.9
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

Get the RSS feed of the public warnings:

```dart
await TransitRss.getWarningFeed();
```

Get the RSS feed of the public news:

```dart
await TransitRss.getNewsFeed();
```

Scrape the website for the affected lines of a specific warning:

```dart
await TransitWarningScraper.scrapeAffectedLines(rssItem);
```

Scrape the website for the description of a specific warning:

```dart
await TransitWarningScraper.scrapeWarningDescription(rssItem);
```

Scrape the website for the timetable PDF of a specific line:

```dart
await RouteLine.getPdfTimetable('A42');
```

The full example can be found in the [example.dart](example/example.dart)

## Facing Issues?

I'm trying my best to make this API as bug-free as possible, if you find any issues, please submit a bug report in the issues section of this repository.
