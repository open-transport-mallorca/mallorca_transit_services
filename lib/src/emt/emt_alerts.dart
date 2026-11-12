part of 'emt.dart';

class EmtAlerts {
  final Emt _emt;

  EmtAlerts._(this._emt);

  Future<List<EmtAlert>> all({Language language = Language.es}) async {
    final url = _emt.client.url('alert/', {'locale': language.name});
    return [
      for (final Map alert in Emt._json(await _emt._get(url)))
        EmtAlert.fromJson(alert)
    ];
  }

  /// `null` if there is no alert with [id].
  Future<EmtAlert?> byId(int id, {Language language = Language.es}) async {
    final url = _emt.client.url('alert/$id', {'locale': language.name});
    final List alerts = Emt._json(await _emt._get(url));
    return alerts.isEmpty ? null : EmtAlert.fromJson(alerts.first);
  }

  /// A file from [EmtAlert.attachmentIds]. `null` if there is none.
  Future<Uint8List?> attachment(EmtAlert alert, int attachmentId) async {
    final url = _emt.client.url('alert/downloadFile', {
      'announceId': '${alert.id}',
      'attachmentId': '$attachmentId',
      'locale': Language.es.name,
    });
    return (await _emt._getOrNull(url))?.bodyBytes;
  }
}
