/// An unofficial Dart package for the Balearic Islands' Public Transportation services.
/// It provides a simple way to access Mallorca's transportation services and get information about the bus stops, lines, schedules, etc.
///
// ! WARNING ! This package is not affiliated with the government or the respective companies.

///
library mallorca_transit_services;

// APIs
export 'src/api/departures.dart';
export 'src/api/stations.dart';
export 'src/api/route_line.dart';

// Realtime
export 'src/realtime/bus_position.dart';
export 'src/realtime/bus_stopped.dart';
export 'src/realtime/station_info.dart';
export 'src/realtime/connection_close.dart';

// Sockets
export 'src/sockets/location_socket.dart';

// Messaging
export 'src/messaging/transit_rss.dart';
