import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

/// One sea-freight price from MIDTRANS's public list (the list MIRA quotes from).
class ShippingRate {
  const ShippingRate({
    required this.originPort,
    required this.originCountry,
    required this.destinationPort,
    required this.destinationCountry,
    required this.container,
    required this.priceUsd,
    required this.validUntil,
  });

  final String originPort;
  final String originCountry;
  final String destinationPort;
  final String destinationCountry;
  final String container;
  final num priceUsd;
  final DateTime? validUntil;

  /// "NSA / Nhava Sheva" -> "Nhava Sheva": the readable name when a code comes first.
  static String _port(String p) => p.contains('/') ? p.split('/').last.trim() : p.trim();
  String get from => _port(originPort);
  String get to => _port(destinationPort);
  bool get toSyria => destinationCountry.toLowerCase() == 'syria';

  static ShippingRate? fromJson(Map<String, dynamic> j) {
    final price = j['priceUsd'];
    if (price is! num || j['status'] != 'Active') return null;
    return ShippingRate(
      originPort: '${j['originPort'] ?? ''}',
      originCountry: '${j['originCountry'] ?? ''}',
      destinationPort: '${j['destinationPort'] ?? ''}',
      destinationCountry: '${j['destinationCountry'] ?? ''}',
      container: '${j['containerSize'] ?? ''}',
      priceUsd: price,
      validUntil: DateTime.tryParse('${j['validUntil'] ?? ''}'),
    );
  }
}

/// Reads the public price list, keeps the last copy for offline use, and returns the
/// prices still valid today: Syria first, then the Gulf (owner 2026-10-28).
class RatesSource {
  static const _cacheKey = 'rates_cache_v1';

  Future<List<ShippingRate>> load() async {
    final prefs = await SharedPreferences.getInstance();
    String? body;
    try {
      final res = await http.get(Uri.parse(AppConfig.ratesApi)).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        body = utf8.decode(res.bodyBytes);
        await prefs.setString(_cacheKey, body);
      }
    } catch (_) {
      // offline: fall back to the last copy
    }
    body ??= prefs.getString(_cacheKey);
    if (body == null) return const [];
    return parse(body, DateTime.now());
  }

  static List<ShippingRate> parse(String body, DateTime now) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final list = (json['data'] as Map<String, dynamic>?)?['rates'] as List? ?? const [];
      final today = DateTime(now.year, now.month, now.day);
      final rates = [
        for (final r in list)
          if (r is Map<String, dynamic>) ShippingRate.fromJson(r),
      ].whereType<ShippingRate>().where((r) => r.validUntil == null || !r.validUntil!.isBefore(today)).toList();
      rates.sort((a, b) {
        if (a.toSyria != b.toSyria) return a.toSyria ? -1 : 1;
        final d = a.destinationCountry.compareTo(b.destinationCountry);
        return d != 0 ? d : a.priceUsd.compareTo(b.priceUsd);
      });
      return rates;
    } catch (_) {
      return const [];
    }
  }
}
