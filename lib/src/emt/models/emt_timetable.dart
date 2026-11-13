import 'package:mallorca_transit_services/src/emt/models/emt_line.dart';
import 'package:mallorca_transit_services/src/emt/models/emt_way.dart';
import 'package:mallorca_transit_services/src/shared/way.dart';

/// An [EmtSubline]'s timetable for one [EmtDayType].
class EmtTimetable {
  final int id;
  final int sublineId;
  final EmtDayType days;

  final DateTime startDate;

  /// `null` if it runs until a newer timetable starts.
  final DateTime? endDate;

  /// Time between buses in the morning, if EMT states one.
  final Duration? morningInterval;

  /// Time between buses in the afternoon, if EMT states one.
  final Duration? afternoonInterval;

  final List<EmtTimetableDirection> directions;

  EmtTimetable(
      {required this.id,
      required this.sublineId,
      required this.days,
      required this.startDate,
      this.endDate,
      this.morningInterval,
      this.afternoonInterval,
      required this.directions});

  @override
  String toString() {
    return 'EmtTimetable{id: $id, sublineId: $sublineId, days: $days, startDate: $startDate, endDate: $endDate, morningInterval: $morningInterval, afternoonInterval: $afternoonInterval, directions: $directions}';
  }

  factory EmtTimetable.fromJson(Map json) {
    final comments = {
      Way.way: json['outgoingComment'],
      Way.back: json['returnComment'],
    };
    return EmtTimetable(
        id: json['id'],
        sublineId: json['sublineCode'],
        days: EmtDayType.fromJson(json['dayTypeConfiguration']),
        startDate: DateTime.parse(json['startValidityDate']),
        endDate: json['endValidityDate'] != null
            ? DateTime.parse(json['endValidityDate'])
            : null,
        morningInterval: _minutes(json['morningInterval']),
        afternoonInterval: _minutes(json['afternoonInterval']),
        directions: [
          for (final Map direction in json['timeTables'])
            EmtTimetableDirection._fromJson(direction,
                comments[wayFromJson(direction['direction']['code'])])
        ]);
  }

  Map<String, dynamic> toJson() {
    String? comment(Way direction) =>
        directions.where((d) => d.direction == direction).firstOrNull?.comment;
    return {
      'id': id,
      'sublineCode': sublineId,
      'dayTypeConfiguration': days.toJson(),
      'startValidityDate': _date(startDate),
      'endValidityDate': endDate != null ? _date(endDate!) : null,
      'morningInterval': morningInterval?.inMinutes.toString(),
      'afternoonInterval': afternoonInterval?.inMinutes.toString(),
      'outgoingComment': comment(Way.way),
      'returnComment': comment(Way.back),
      'timeTables': directions.map((d) => d.toJson()).toList(),
    };
  }

  static Duration? _minutes(String? value) {
    final minutes = value != null ? int.tryParse(value) : null;
    return minutes != null ? Duration(minutes: minutes) : null;
  }

  static String _date(DateTime date) => date.toIso8601String().substring(0, 10);
}

/// The days an [EmtTimetable] applies to.
class EmtDayType {
  /// E.g. `LAB`, `SAB` or `FES`.
  final String code;

  /// E.g. `Lunes a viernes (desde de 09/11/2026)`.
  final String name;

  /// [DateTime.monday] to [DateTime.sunday].
  final Set<int> weekdays;

  /// Whether it also applies on public holidays.
  final bool holidays;

  /// Whether it also applies on the eves of public holidays.
  final bool holidayEves;

  EmtDayType(
      {required this.code,
      required this.name,
      required this.weekdays,
      this.holidays = false,
      this.holidayEves = false});

  @override
  String toString() {
    return 'EmtDayType{code: $code, name: $name, weekdays: $weekdays, holidays: $holidays, holidayEves: $holidayEves}';
  }

  static const _weekdays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  factory EmtDayType.fromJson(Map json) {
    return EmtDayType(
        code: json['code'],
        name: json['description'],
        weekdays: {
          for (var i = 0; i < _weekdays.length; i++)
            if (json[_weekdays[i]] == true) i + 1
        },
        holidays: json['publicHoliday'] ?? false,
        holidayEves: json['publicHolidayEve'] ?? false);
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'description': name,
      for (var i = 0; i < _weekdays.length; i++)
        _weekdays[i]: weekdays.contains(i + 1),
      'publicHoliday': holidays,
      'publicHolidayEve': holidayEves,
    };
  }
}

class EmtTimetableDirection {
  /// See [EmtRoute.id].
  final int routeId;

  /// [Way.way] or [Way.back].
  final Way direction;

  /// Only in Catalan and Spanish.
  final String? comment;

  /// Usually one, with more when buses start from different stops.
  final List<EmtTimetableRuns> runs;

  EmtTimetableDirection(
      {required this.routeId,
      required this.direction,
      this.comment,
      required this.runs});

  @override
  String toString() {
    return 'EmtTimetableDirection{routeId: $routeId, direction: $direction, comment: $comment, runs: $runs}';
  }

  factory EmtTimetableDirection._fromJson(Map json, String? comment) {
    return EmtTimetableDirection(
        routeId: json['routeCode'],
        direction: wayFromJson(json['direction']['code']),
        comment: comment == null || comment.isEmpty ? null : comment,
        runs: [
          for (final Map runs in json['trips']) EmtTimetableRuns._fromJson(runs)
        ]);
  }

  Map<String, dynamic> toJson() {
    return {
      'routeCode': routeId,
      'direction': {'code': wayToJson(direction)},
      'trips': runs.map((r) => r.toJson()).toList(),
    };
  }
}

/// The buses going from one stop to another.
class EmtTimetableRuns {
  /// See [EmtStop.id].
  final int fromStopId;
  final int toStopId;

  /// When each bus leaves [fromStopId], from the start of the service day.
  /// Buses after midnight are past 24 hours.
  final List<Duration> departures;

  EmtTimetableRuns(
      {required this.fromStopId,
      required this.toStopId,
      required this.departures});

  @override
  String toString() {
    return 'EmtTimetableRuns{fromStopId: $fromStopId, toStopId: $toStopId, departures: $departures}';
  }

  factory EmtTimetableRuns._fromJson(Map json) {
    var previous = Duration.zero;
    return EmtTimetableRuns(
        fromStopId: json['fromStopCode'],
        toStopId: json['toStopCode'],
        departures: [
          for (final String time in json['departureTimes'])
            previous = _time(time, previous)
        ]);
  }

  Map<String, dynamic> toJson() {
    return {
      'fromStopCode': fromStopId,
      'toStopCode': toStopId,
      'numberOfTrips': departures.length,
      'departureTimes': [
        for (final departure in departures)
          [departure.inHours % 24, departure.inMinutes % 60]
              .map((part) => '$part'.padLeft(2, '0'))
              .join(':')
      ],
    };
  }

  /// [time] is `HH:mm`. EMT lists times in service-day order, so one earlier
  /// than [previous] is after midnight.
  static Duration _time(String time, Duration previous) {
    final [hours, minutes] = time.split(':').map(int.parse).toList();
    var duration = Duration(hours: hours, minutes: minutes);
    while (duration < previous) {
      duration += const Duration(days: 1);
    }
    return duration;
  }
}
