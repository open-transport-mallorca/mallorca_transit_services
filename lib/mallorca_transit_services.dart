/// An unofficial Dart package for the Balearic Islands' Public Transportation services.
/// It provides a simple way to access Mallorca's transportation services and get information about the bus stops, lines, schedules, etc.
///
// ! WARNING ! This package is not affiliated with the government or the respective companies.

///
library mallorca_transit_services;

// APIs
export 'src/api/departures_api.dart';
export 'src/api/stations_api.dart';
export 'src/api/route_lines_api.dart';

// Messaging
export 'src/messaging/transit_rss.dart';

// Models
export 'src/models/departure.dart';
export 'src/models/station.dart';
export 'src/models/route_line.dart';
export 'src/models/transit_warning.dart';
export 'src/models/transit_news.dart';

// Realtime models
export 'src/models/realtime/bus_position.dart';
export 'src/models/realtime/bus_stopped.dart';
export 'src/models/realtime/station_info.dart';
export 'src/models/realtime/connection_close.dart';

// Sockets
export 'src/sockets/location_socket.dart';
