# CHANGELOG

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
