# CHANGELOG

## 3.0.0

A rewrite. TIB now comes from its JSON APIs instead of RSS feeds and scraped pages, behind one `Tib` entry point, and EMT Palma, Palma's city buses, is new behind `Emt`. Every public API changed; see the README for the new usage.

### TIB

- Added `Tib`, which replaces the static API classes with sub-APIs: `stations`, `lines`, `departures`, `timetables`, `trips`, `towns`, `warnings`, `news` and `realtime`
  - `StationsApi.getAllStations` → `stations.all`, `StationsApi.fromId` → `stations.byId`, `StationsApi.getLines` → `stations.lines`
  - `RouteLinesApi.getAllLines` → `lines.all`, `getLine` → `lines.byCode`, `getSublines` → `lines.sublines`, `getPath` → `lines.path`
  - `RouteLinesApi.getPdfTimetable` → `timetables.current`, which returns a `Timetable` with its `url`
  - `DeparturesApi.getDepartures` → `departures.next`
  - `TransitRss.getWarnings` → `warnings.all`, `TransitRss.getNews` → `news.all`
  - `LocationWebSocket.locationStream` → `realtime.track`
- Added `stations.byCode`, `stations.near`, `stations.inArea` and `stations.photo`
- Added `departures.at`, departures from the timetable at any time, and `departures.withBays`, a bus or train station's board with its bays (`BayDeparture`)
- Added `timetables`, with every PDF timetable of a line (`Timetable`), including seasonal ones
- Added `trips`, the runs of a day with their stop times (`Trip`, `TripStop`)
- Added `towns` (`Town`) and the stations in each
- Added `warnings.byId`
- Lookups like `byCode` and `byId` return `null` when nothing is found, and failed requests throw `TibException`
- `Departure`:
  - Renamed `estimatedArrival` to `scheduledArrival`, `departureTime` to `tripDepartureTime`, `endTime` to `tripArrivalTime`, `originStop` to `origin` and `delayed` to `onDemand`, which is what TIB's `dem` means
  - Added `lineId` and `lineColorValue`
  - Removed `departureStop` and `RealTripBusStats`
- `Station.pickupType` and `dropoffType` are now a `PickupDropoffType`
- Added `RouteLine.endDate`
- `TransitWarning` and `TransitNews` come from TIB's JSON instead of RSS, so they're complete without scraping:
  - `TransitWarning` has `title`, `summary`, `html`, `paragraphs`, `affectedLineIds` (compare to `RouteLine.id`), `modified`, and `link` and `documentUrl` as `Uri`
  - `TransitNews` has an `int` `id`, `html`, `summaryParagraphs`, `modified`, `featured`, `thumbnailUrl`, and `link` as a `Uri`
- Renamed `Passangers` to `Passengers`, `RouteStationInfo.passangers` to `passengers` (now nullable) and `BusStopped.passangers` to `passengers`
- Removed `TransitRss`, `TransitWarningScraper`, `NewsScraper` and the `dart_rss` dependency

### EMT Palma

- Added `Emt` with sub-APIs:
  - `stops`: all, by id, and the lines serving a stop (`EmtStop`)
  - `lines`: all, by id, sublines, routes (one per direction), and a route's stops and path (`EmtLine`, `EmtSubline`, `EmtRoute`)
  - `departures.next`: live arrivals at a stop, with bus numbers (`EmtDeparture`)
  - `timetables.forSubline`: one per day type (`EmtTimetable`)
  - `alerts`: all, by id, and their attachments (`EmtAlert`)
  - `news`: all articles, newest first (`EmtArticle`)
- Added `EmtClient`, which gets EMT's token by creating an anonymous user. Store the token from `onToken` and pass it back as `token`, or every start creates a new user
- Added `EmtException`, with EMT's error code and message

### Shared

- `Language` and `Way` are shared by TIB and EMT. Added `Way.circular`
- Models have an instance `toJson()` instead of a static `toJson(model)`, and `fromJson(toJson())` gives the same object back. JSON cached by 2.x may not read back, so drop those caches

## 2.8.0

TIB moved its stops and lines service behind an API key, and the old `ws.tib.org` host no longer responds, so every `StationsApi` and `RouteLinesApi` call failed. This release fixes them without changes to calling code.

- Added `TibClient`, an HTTP client that sends TIB's API key with every request. It fetches the key from tib.org's public config on first use and caches it, refetches and retries once on a `401` in case the key rotated, and sends requests without the key if the config cannot be fetched, so endpoints that do not need it keep working. `TibClient.shared` is now the default `httpClient` of every API, RSS and scraper class
- Added `TibConfig`, the parsed config. Pass one to `TibClient(config: ...)` to skip fetching it
- Moved `StationsApi` and `RouteLinesApi` from `https://ws.tib.org/sictmws-rest` to `https://api.tib.org/sictmws`. Paths and responses are unchanged
- `DeparturesApi` now requests `https://www.tib.org` directly instead of following a redirect from `http://tib.org`
- A custom `httpClient` replaces `TibClient.shared` and so no longer gets the key; wrap it with `TibClient(inner: yourClient)`

## 2.7.0

- Added `documentUrl` to `TransitWarning`: the URL of the document (usually a PDF) attached to the warning's page, resolved against its link. Filled by `TransitWarningScraper.fetchDetails`, alongside a standalone `TransitWarningScraper.documentUrl(url)`. `null` when the page has no attachment

## 2.6.0

Everything here is additive. The four `RssItem`-taking scrapers keep their exact 2.5.0 behaviour, including the `L` prefix on line codes, and are deprecated in favour of URL-taking replacements. They will be removed in 3.0.0.

- Added `TransitWarning` and `TransitNews` models, returned by `TransitRss.getWarnings` and `TransitRss.getNews`. They carry a stable `id`, a `published` `DateTime` parsed from the feed, and the fields that have to be scraped from the item's own page. `getWarningFeed` and `getNewsFeed` still return the raw `RssFeed`
- Added URL-taking scrapers, so a consumer that caches its own model no longer needs `dart_rss`: `TransitWarningScraper.description`, `TransitWarningScraper.affectedLines`, `NewsScraper.description`, `NewsScraper.image` and `NewsScraper.imageUrl`. They return `null` or an empty list when the page layout changes, and throw only on transport failures
- `TransitWarningScraper.affectedLines` returns line codes without the `L` prefix that warning pages print (`L231` -> `231`, `LA32` -> `A32`, `L411e` -> `411e`), so they can be compared to `RouteLine.code` and `Departure.lineCode` directly. `TransitWarningScraper.normaliseLineCode` exposes the same normalisation. Duplicates are dropped and page order is kept
- Added `TransitWarningScraper.fetchDetails` and `NewsScraper.fetchDetails`, which fill in a model's scraped fields with a single request instead of one per field
- Added `TransitRss.parseFeedDate`, which reads both the RFC 822 `pubDate` (`Wed, 22 Jul 2026 22:43:00 GMT`, which `DateTime.tryParse` rejects) and the ISO 8601 `dc:date`, and returns UTC. The models use it; it is public for consumers reading `RssItem.pubDate` off the raw feed
- Added `httpClient` to `TransitRss`, `TransitWarningScraper` and `NewsScraper`, matching the API classes
- Fixed `NewsScraper.scrapeNewsImage` always throwing: it looked for `class="portada"` among the descendants of the page's first `<img>`, where it can never appear, and then built the image URL with a doubled slash. It now resolves `img.portada`'s `src` against the page URL. This is the one behaviour change to a deprecated method, and it could not have been relied on
- Deprecated `TransitWarningScraper.scrapeWarningDescription`, `TransitWarningScraper.scrapeAffectedLines`, `NewsScraper.scrapeNewsDescription` and `NewsScraper.scrapeNewsImage`. Each takes an `RssItem` only to read `rssItem.link!` off it, which throws on a feed item with no link

## 2.5.0

- Added `lineColor`, `originStop` and `endTime` to `Departure`
- Deprecated `Departure.departureStop`: it parsed `et`, an arrival time, not a stop name - use `endTime`
- Added `sector`, `startDate` and `entityId` to `RouteLine`
- Added `description` and `lineId` to `Subline`
- Added `tripId` and `recordedAt` to `BusPosition`
- Added `tripId` and `position` to `RouteStationInfo`
- Added `stopCode` to `StationOnRoute`
- Added `stopId`, `stopCode`, `tripId` and `recordedAt` to `BusStopped`
- Fixed `Departure.fromJson` losing `realTrip` when re-reading its own `toJson` output: `RealTrip.toJson` returns an encoded JSON string, which `fromJson` now accepts alongside a map
- Fixed numeric type coercion in `RealTrip.fromJson` (`lat`/`lng`) and `BusPosition.fromJson` (`lat`/`lng`/`vel`), which the 2.2.0 entry claimed but did not apply
- Documented which endpoints populate the endpoint-dependent fields of `Station` and `RouteLine`

## 2.4.1

- Added `town` optional field to `Station` model (not returned on all endpoints)

## 2.4.0

- Added `pickupType`, `dropoffType`, `isDischargeOnly` and `isPickupOnly` optional fields to `Station` model (not returned on all endpoints)

## 2.3.0

- Changed `stationCode` from `int` to `String` in `getDepartures` to match `Station` model and API response format

## 2.2.0

- Added `seatedCapacity` and `standingCapacity` optional fields to `Passangers`
- Fixed nullable field handling in `BusStopped.fromJson`: `actualTime` now safely returns `null` when absent instead of throwing
- Fixed numeric type coercion in `BusStopped.fromJson` and `BusPosition.fromJson`: `lat`, `lng`, and `speed` are now cast via `(num).toDouble()` to handle integer values from the API

## 2.1.0

- Added new fields to `RouteLine`: `summerOnly`, `onDemand`, `sessions` (`RouteSession`), `towns` (`RouteTown`), `holidays` (`RouteHoliday`), `zoneIds`
- Added new fields to `Subline`: `main`, `distance`, `towns` (`RouteTown`)
- Added new model classes: `RouteSession`, `RouteTown`, `RouteHoliday`, `PickupDropoffType`
- Added `activeOnly` parameter to `RouteLinesApi.getAllLines` to filter out inactive lines
- Changed `Station.code` from `int` to `String` to match the API response format
- Changed `StationsApi.getLines` parameter from `int` to `String`

## 2.0.0

BREAKING CHANGE

- Separated models from API logic. Pure data classes (`Departure`, `Station`, `RouteLine`, `Subline`, `RoutePath`) are now in `src/models/`. All network calls have moved to dedicated service classes:
  - `DeparturesApi.getDepartures` (was `Departures.getDepartures`)
  - `StationsApi.getAllStations`, `StationsApi.fromId`, `StationsApi.getLines` (were static methods on `Station`)
  - `RouteLinesApi.getAllLines`, `RouteLinesApi.getLine`, `RouteLinesApi.getPdfTimetable`, `RouteLinesApi.getSublines`, `RouteLinesApi.getPath` (were static methods on `RouteLine`, `Subline`, and `RoutePath`)
- Moved realtime models (`BusPosition`, `BusStopped`, `ConnectionClose`, `RouteStationInfo`) into `src/models/realtime/`

## 1.4.0

- Changed `getPdfTimetable` to use API instead of web scraping

## 1.3.0

- Made `estimatedDistance` and `estimatedArrival` optional in `StationOnRoute` to handle cases where this information is not available.
- Added location stream to example

## 1.2.1

- Made `locationStream` syncronous and renamed it to `locationChannel` for clarity.
- `locationStream` is still available as a method that returns the stream.

## 1.2.0

BREAKING CHANGE

- Changed `locationStream` to return a `WebSocketChannel` instead of a `Stream`. This allows for more flexibility in handling the WebSocket connection.

## 1.1.1

- Made `RealTripBusStats` optional in `Departure` because of endpoint changes

## 1.1.0

- Added `RealTripBusStats` to `Departure`

## 1.0.2

- Added a method to get a station by its ID

## 1.0.1

- Fixed README & License

## 1.0.0

- Initial version.
