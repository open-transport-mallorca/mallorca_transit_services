# CHANGELOG

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
