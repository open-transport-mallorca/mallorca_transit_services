import 'package:latlong2/latlong.dart';
import 'package:mallorca_transit_services/src/shared/way.dart';
import 'package:mallorca_transit_services/src/tib/models/station.dart';
import 'package:xml/xml.dart';

enum LineType {
  train, // 1
  metro, // 2
  bus, // 3
  urban, // 4
  shuttle, // 5, Lançadora
  unknown
}

/// A line, e.g. `A42`.
class RouteLine {
  /// Whether the line runs this season.
  bool active;

  String code;

  /// Internal id.
  int id;

  String name;

  /// ARGB colour.
  int color;

  LineType type;

  /// Only set by [TibLines.byCode].
  List<Subline>? sublines;

  /// Whether the line only runs in summer.
  bool? summerOnly;

  /// The line's seasons.
  List<RouteSession>? sessions;

  /// Towns the line serves.
  List<RouteTown>? towns;

  /// Holidays, on which the holiday timetable applies. Only set by
  /// [TibLines.byCode].
  List<RouteHoliday>? holidays;

  List<int>? zoneIds;

  /// Whether the line only runs on request.
  bool? onDemand;

  /// The line's sector, e.g. `100`, `Metro` or `Tren`. `null` for the airport
  /// lines.
  String? sector;

  /// Start of the line's validity. Only set by [TibLines.byCode].
  DateTime? startDate;

  /// End of the line's validity.
  DateTime? endDate;

  /// Internal id of the line's entity.
  int? entityId;

  RouteLine(
      {required this.active,
      required this.code,
      required this.id,
      required this.name,
      required this.color,
      this.sublines,
      required this.type,
      this.summerOnly,
      this.sessions,
      this.towns,
      this.holidays,
      this.zoneIds,
      this.onDemand,
      this.sector,
      this.startDate,
      this.endDate,
      this.entityId});

  @override
  String toString() {
    return 'Line{active: $active, code: $code, color: $color, id: $id, name: $name, type: $type, sublines: $sublines, summerOnly: $summerOnly, sessions: $sessions, towns: $towns, holidays: $holidays, zoneIds: $zoneIds, onDemand: $onDemand, sector: $sector, startDate: $startDate, endDate: $endDate, entityId: $entityId}';
  }

  factory RouteLine.fromJson(Map json) {
    final routeLine = RouteLine(
      active: json['act'],
      code: json['cod'],
      id: json['id'],
      name: json['nam'],
      color: int.parse(json['color'].replaceAll("#", "0xFF")),
      type: switch (json['typ']) {
        1 => LineType.train,
        2 => LineType.metro,
        3 => LineType.bus,
        4 => LineType.urban,
        5 => LineType.shuttle,
        _ => LineType.unknown,
      },
      summerOnly: json['summ'],
      sector: json['sec'],
      startDate: json['ini'] != null ? DateTime.tryParse(json['ini']) : null,
      endDate: json['end'] != null ? DateTime.tryParse(json['end']) : null,
      entityId: json['entityId'],
    );

    routeLine.sublines = (json['sublines'] as List?)
        ?.map((s) => Subline.fromJson(s, routeLine))
        .toList();
    routeLine.sessions = (json['sessions'] as List?)
        ?.map((s) => RouteSession.fromJson(s))
        .toList();
    routeLine.towns =
        (json['towns'] as List?)?.map((t) => RouteTown.fromJson(t)).toList();
    routeLine.holidays = (json['festius'] as List?)
        ?.map((h) => RouteHoliday.fromJson(h))
        .toList();
    routeLine.zoneIds =
        (json['zoneTransport'] as List?)?.map((z) => z['id'] as int).toList();
    routeLine.onDemand = json['dem'];

    return routeLine;
  }

  Map<String, dynamic> toJson() {
    return {
      'act': active,
      'cod': code,
      'id': id,
      'nam': name,
      'color': color.toString(),
      'typ': switch (type) {
        LineType.train => 1,
        LineType.metro => 2,
        LineType.bus => 3,
        LineType.urban => 4,
        LineType.shuttle => 5,
        LineType.unknown => -1,
      },
      'sublines': sublines?.map((s) => s.toJson()).toList(),
      'summ': summerOnly,
      'sessions': sessions?.map((s) => s.toJson()).toList(),
      'towns': towns?.map((t) => t.toJson()).toList(),
      'festius': holidays?.map((h) => h.toJson()).toList(),
      'zoneTransport': zoneIds?.map((id) => {'id': id}).toList(),
      'dem': onDemand,
      'sec': sector,
      'ini': startDate?.toIso8601String(),
      'end': endDate?.toIso8601String(),
      'entityId': entityId
    };
  }
}

/// One route of a [RouteLine], e.g. its outbound or return direction.
class Subline {
  RouteLine parentLine;

  /// Whether TIB shows the subline.
  bool active;

  String code;

  /// Internal id.
  int id;

  String name;

  /// ARGB colour, the same as [parentLine]'s.
  int color;

  LineType type;
  Way way;

  /// Stops in driving order.
  List<Station> stations;

  /// Towns the subline serves.
  List<RouteTown>? towns;

  /// Whether this is the line's main subline.
  bool? main;

  /// Length in metres.
  double? distance;

  String? description;

  /// Id of [parentLine], see [RouteLine.id].
  int? lineId;

  Subline(
      {required this.parentLine,
      required this.active,
      required this.code,
      required this.id,
      required this.name,
      required this.color,
      required this.type,
      required this.stations,
      required this.way,
      this.towns,
      this.main,
      this.distance,
      this.description,
      this.lineId});

  factory Subline.fromJson(Map json, RouteLine mainRouteLine) {
    return Subline(
        parentLine: mainRouteLine,
        active: json['vis'],
        code: json['cod'],
        id: json['id'],
        name: json['nam'],
        color: mainRouteLine.color,
        type: mainRouteLine.type,
        stations: (json['stops'] as List<dynamic>)
            .map<Station>((station) => Station.fromJson(station))
            .toList(),
        towns: json['towns'] != null
            ? (json['towns'] as List<dynamic>)
                .map((town) => RouteTown.fromJson(town))
                .toList()
            : null,
        way: switch (json['dir']) {
          'Anada' => Way.way,
          'Circular' => Way.circular,
          _ => Way.back,
        },
        main: json['main'],
        distance: (json['distance'] as num?)?.toDouble(),
        description: json['desc'],
        lineId: json['lineid']);
  }

  Map<String, dynamic> toJson() {
    return {
      'vis': active,
      'cod': code,
      'id': id,
      'nam': name,
      'stops': stations.map((station) => station.toJson()).toList(),
      'dir': switch (way) {
        Way.way => 'Anada',
        Way.back => 'Tornada',
        Way.circular => 'Circular',
      },
      'main': main,
      'towns': towns?.map((town) => town.toJson()).toList(),
      'distance': distance,
      'desc': description,
      'lineid': lineId
    };
  }

  @override
  String toString() {
    return 'Subline{active: $active, code: $code, color: $color, id: $id, name: $name, type: $type, way: $way, stations: $stations, parentLine: $parentLine, towns: $towns, main: $main, distance: $distance, description: $description, lineId: $lineId}';
  }
}

/// A season of a [RouteLine], e.g. summer.
class RouteSession {
  /// Code of the bus type used.
  String? busTypeId;

  /// Whether this is the current season.
  bool current;

  /// Only the day and month count; the year is fake.
  DateTime startDate;

  /// Only the day and month count; the year is fake.
  DateTime endDate;

  String name;

  RouteSession(
      {this.busTypeId,
      required this.current,
      required this.startDate,
      required this.endDate,
      required this.name});

  @override
  String toString() {
    return 'RouteSession{busTypeId: $busTypeId, current: $current, startDate: $startDate, endDate: $endDate, name: $name}';
  }

  factory RouteSession.fromJson(Map json) {
    return RouteSession(
        busTypeId: json['busTypeId'],
        current: json['cur'],
        startDate: DateTime.parse(json['ini']),
        endDate: DateTime.parse(json['end']),
        name: json['nam']);
  }

  Map<String, dynamic> toJson() {
    return {
      'busTypeId': busTypeId,
      'cur': current,
      'ini': startDate.toIso8601String(),
      'end': endDate.toIso8601String(),
      'nam': name
    };
  }
}

/// A town on a [RouteLine] or [Subline].
class RouteTown {
  int id;

  /// Distance along the route.
  double distance;

  String name;

  RouteTown({required this.id, required this.distance, required this.name});

  @override
  String toString() {
    return 'RouteTown{id: $id, distance: $distance, name: $name}';
  }

  factory RouteTown.fromJson(Map json) {
    return RouteTown(
        id: json['id'],
        distance: (json['dis'] as num).toDouble(),
        name: json['nam']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'dis': distance, 'nam': name};
  }
}

/// A holiday, on which a [RouteLine] runs its holiday timetable.
class RouteHoliday {
  DateTime date;
  String name;

  RouteHoliday({required this.date, required this.name});

  @override
  String toString() {
    return 'RouteHoliday{date: $date, name: $name}';
  }

  factory RouteHoliday.fromJson(Map json) {
    return RouteHoliday(date: DateTime.parse(json['dat']), name: json['nam']);
  }

  Map<String, dynamic> toJson() {
    return {'dat': date.toIso8601String(), 'nam': name};
  }
}

/// The road a [Subline] drives on.
class RoutePath {
  Subline subline;

  /// Segments of the road, each a list of points.
  List<List<LatLng>> paths;

  RoutePath({required this.subline, required this.paths});

  @override
  String toString() {
    return 'RoutePath{line: ${subline.parentLine}, subline: $subline, paths: $paths}';
  }

  static RoutePath fromKmz(String kmz, Subline subline) {
    final document = XmlDocument.parse(kmz);
    List<List<LatLng>> allCoordinates = [];
    var lineStrings = document.findAllElements('LineString');

    for (XmlElement lineString in lineStrings) {
      var coordinates = lineString.findElements('coordinates');
      if (coordinates.isNotEmpty) {
        List<LatLng> coordinatesList = [];
        var coordinatesString = coordinates.first.innerText;
        var coordinatesSplit = coordinatesString.split(" ");
        for (var coordinate in coordinatesSplit) {
          var latLong = coordinate.split(",");
          coordinatesList
              .add(LatLng(double.parse(latLong[1]), double.parse(latLong[0])));
        }
        allCoordinates.add(coordinatesList);
      }
    }
    return RoutePath(paths: allCoordinates, subline: subline);
  }
}
