import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart' show GZipDecoder;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import 'tariff_models.dart';

/// Loads the Syrian tariff: the last copy downloaded from mid-trans.com if there is
/// one, else the snapshot bundled in the app; then checks the website for a newer
/// file in the background. The file is read as published — never edited here.
class TariffRepository {
  TariffRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _cacheFile = 'syrian-hs-code-tariff.json';
  static const _etagKey = 'tariff_etag';
  static const _checkedKey = 'tariff_checked_at';

  Future<File> _cachePath() async => File('${(await getApplicationSupportDirectory()).path}/$_cacheFile');

  Future<TariffData> loadLocal() async {
    try {
      final f = await _cachePath();
      if (await f.exists()) {
        final data = await compute(_parse, (await f.readAsString(), 'cache'));
        if (data.rows.isNotEmpty) return data;
      }
    } catch (_) {
      // a damaged cache falls back to the bundled snapshot
    }
    final bytes = await rootBundle.load(AppConfig.bundledTariffAsset);
    // pure-Dart gunzip: same result on every platform (dart:io's zlib is native-only)
    final text = utf8.decode(GZipDecoder().decodeBytes(bytes.buffer.asUint8List()));
    return compute(_parse, (text, 'bundle'));
  }

  /// Downloads the website's file when it changed. Returns the new data, or null
  /// when nothing changed, the check is not due yet, or the website is unreachable.
  Future<TariffData?> refresh({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final last = DateTime.tryParse(prefs.getString(_checkedKey) ?? '');
    if (!force && last != null && DateTime.now().difference(last) < AppConfig.refreshEvery) return null;
    try {
      final etag = prefs.getString(_etagKey);
      final res = await _client
          .get(Uri.parse(AppConfig.tariffUrl), headers: {'If-None-Match': ?etag})
          .timeout(const Duration(seconds: 20));
      await prefs.setString(_checkedKey, DateTime.now().toIso8601String());
      if (res.statusCode == 304 || res.statusCode != 200) return null;
      final text = utf8.decode(res.bodyBytes);
      final data = await compute(_parse, (text, 'network'));
      if (data.rows.isEmpty) return null; // never replace a good copy with an empty one
      await (await _cachePath()).writeAsString(text, flush: true);
      final newTag = res.headers['etag'];
      if (newTag != null) await prefs.setString(_etagKey, newTag);
      return data;
    } catch (_) {
      return null;
    }
  }
}

TariffData _parse((String, String) input) =>
    TariffData.fromJson(jsonDecode(input.$1) as Map<String, dynamic>, input.$2);
