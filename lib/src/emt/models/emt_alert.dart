class EmtAlert {
  final int id;

  /// E.g. `Línea desviada carrera`.
  final String title;

  /// Plain text. Only in Catalan and Spanish; other languages mostly get
  /// Spanish.
  final String description;

  /// See [EmtLine.id].
  final List<int> lineIds;

  /// See [EmtStop.id].
  final List<int> stopIds;

  /// When it applies. [end] is `null` until further notice.
  final List<({DateTime start, DateTime? end})> periods;

  final DateTime? published;

  /// Files, usually PDFs, to download with [EmtAlerts.attachment].
  final List<int> attachmentIds;

  EmtAlert(
      {required this.id,
      required this.title,
      required this.description,
      this.lineIds = const [],
      this.stopIds = const [],
      this.periods = const [],
      this.published,
      this.attachmentIds = const []});

  @override
  String toString() {
    return 'EmtAlert{id: $id, title: $title, description: $description, lineIds: $lineIds, stopIds: $stopIds, periods: $periods, published: $published, attachmentIds: $attachmentIds}';
  }

  factory EmtAlert.fromJson(Map json) {
    return EmtAlert(
        id: json['idAlerta'],
        title:
            (json['titulo'] as String).replaceAll(RegExp(r'\s+'), ' ').trim(),
        description: (json['descripcion'] as String? ?? '').trim(),
        lineIds: [for (final Map line in json['lineas'] ?? []) line['idLinea']],
        stopIds: [
          for (final Map stop in json['paradas'] ?? []) stop['idParada']
        ],
        periods: [
          for (final Map period in json['fechas'] ?? [])
            (start: _date(period['horaInicio'])!, end: _date(period['horaFin']))
        ],
        published: _date(json['createdAt']),
        attachmentIds: [...?json['files']]);
  }

  Map<String, dynamic> toJson() {
    return {
      'idAlerta': id,
      'titulo': title,
      'descripcion': description,
      'lineas': [
        for (final id in lineIds) {'idLinea': id}
      ],
      'paradas': [
        for (final id in stopIds) {'idParada': id}
      ],
      'fechas': [
        for (final period in periods)
          {'horaInicio': _format(period.start), 'horaFin': _format(period.end)}
      ],
      'createdAt': _format(published),
      'files': attachmentIds,
    };
  }

  /// [value] is `dd/MM/yyyy HH:mm`.
  static DateTime? _date(String? value) {
    if (value == null) return null;
    final [date, time] = value.split(' ');
    final [day, month, year] = date.split('/').map(int.parse).toList();
    final [hour, minute] = time.split(':').map(int.parse).toList();
    return DateTime(year, month, day, hour, minute);
  }

  static String? _format(DateTime? date) {
    if (date == null) return null;
    String two(int n) => '$n'.padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }
}
