import 'package:mallorca_transit_services/src/shared/way.dart';

/// EMT numbers directions 1 and 2.
Way wayFromJson(int direction) => direction == 2 ? Way.back : Way.way;

int wayToJson(Way way) => way == Way.back ? 2 : 1;
