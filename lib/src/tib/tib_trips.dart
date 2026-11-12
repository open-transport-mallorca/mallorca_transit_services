part of 'tib.dart';

/// Scheduled bus runs. [date] defaults to today.
class TibTrips {
  final Tib _tib;

  TibTrips._(this._tib);

  /// Every trip on [date], without stops.
  Future<List<Trip>> all({DateTime? date}) async {
    final day = _day(date);
    final url = await _tib.client.sictmws('trips/${_tib.entity}', _query(day));
    return _parse(await _tib._get(url), day);
  }

  /// The trips of the line with [lineCode] on [date], without stops.
  ///
  /// Covers all its sublines, including hidden ones, which run most trips.
  Future<List<Trip>> forLine(String lineCode, {DateTime? date}) async {
    final trips = await all(date: date);
    return trips.where((trip) => trip.lineCode == lineCode).toList();
  }

  /// The trips of the subline with [sublineCode] on [date], with stops.
  Future<List<Trip>> forSubline(String sublineCode, {DateTime? date}) async {
    final day = _day(date);
    final url = await _tib.client
        .sictmws('trips/${_tib.entity}/$sublineCode', _query(day));
    return _parse(await _tib._get(url), day);
  }

  /// The trip with [id] on [date], with stops. `null` if there is none.
  Future<Trip?> byId(int id, {DateTime? date}) async {
    final day = _day(date);
    final url = await _tib.client.sictmws('trips/id/$id', _query(day));
    final response = await _tib._getOrNull(url);
    return response == null
        ? null
        : Trip.fromJson(Tib._json(response), date: day);
  }

  static DateTime _day(DateTime? date) {
    final day = date ?? DateTime.now();
    return DateTime(day.year, day.month, day.day);
  }

  static Map<String, String> _query(DateTime day) => {
        'dat': '${day.year}-${'${day.month}'.padLeft(2, '0')}-'
            '${'${day.day}'.padLeft(2, '0')}'
      };

  static List<Trip> _parse(Response response, DateTime day) => [
        for (final Map trip in Tib._json(response))
          Trip.fromJson(trip, date: day)
      ]..sort((a, b) => a.departureTime.compareTo(b.departureTime));
}
