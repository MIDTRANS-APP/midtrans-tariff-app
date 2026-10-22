import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saved codes and recent searches, kept on the device only.
class Favorites extends ChangeNotifier {
  static const _favKey = 'favorite_codes';
  static const _recentKey = 'recent_searches';

  final List<String> _codes = [];
  final List<String> _recent = [];

  List<String> get codes => List.unmodifiable(_codes);
  List<String> get recent => List.unmodifiable(_recent);
  bool contains(String code) => _codes.contains(code);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _codes
      ..clear()
      ..addAll(p.getStringList(_favKey) ?? const []);
    _recent
      ..clear()
      ..addAll(p.getStringList(_recentKey) ?? const []);
    notifyListeners();
  }

  Future<void> toggle(String code) async {
    _codes.contains(code) ? _codes.remove(code) : _codes.insert(0, code);
    notifyListeners();
    await (await SharedPreferences.getInstance()).setStringList(_favKey, _codes);
  }

  Future<void> addRecent(String query) async {
    final q = query.trim();
    if (q.length < 2) return;
    _recent
      ..remove(q)
      ..insert(0, q);
    if (_recent.length > 8) _recent.removeRange(8, _recent.length);
    notifyListeners();
    await (await SharedPreferences.getInstance()).setStringList(_recentKey, _recent);
  }
}
