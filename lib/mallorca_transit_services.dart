/// An unofficial Dart package for the Balearic Islands' Public Transportation services.
/// It provides a simple way to access Mallorca's transportation services and get information about the bus stops, lines, schedules, etc.
///
// ! WARNING ! This package is not affiliated with the government or the respective companies.

///
library mallorca_transit_services;

// TIB
export 'src/tib/tib.dart';
export 'src/tib/tib_client.dart';

// Models
export 'src/tib/models/departure.dart';
export 'src/tib/models/bay_departure.dart';
export 'src/tib/models/station.dart';
export 'src/tib/models/route_line.dart';
export 'src/tib/models/timetable.dart';
export 'src/tib/models/town.dart';
export 'src/tib/models/trip.dart';
export 'src/tib/models/language.dart';
export 'src/tib/models/transit_warning.dart';
export 'src/tib/models/transit_news.dart';

// Realtime models
export 'src/tib/models/realtime/bus_position.dart';
export 'src/tib/models/realtime/bus_stopped.dart';
export 'src/tib/models/realtime/station_info.dart';
export 'src/tib/models/realtime/connection_close.dart';

// EMT
export 'src/emt/emt.dart';
export 'src/emt/emt_client.dart';
export 'src/emt/models/emt_departure.dart';
export 'src/emt/models/emt_line.dart';
export 'src/emt/models/emt_stop.dart';
export 'src/emt/models/emt_timetable.dart';
