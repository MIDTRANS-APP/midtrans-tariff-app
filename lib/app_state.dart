import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/account.dart';
import 'data/favorites.dart';
import 'data/push.dart';
import 'data/search.dart';
import 'data/tariff_models.dart';
import 'data/tariff_repository.dart';
import 'l10n.dart';

class AppState extends ChangeNotifier {
  AppState({TariffRepository? repository}) : repository = repository ?? TariffRepository();

  final TariffRepository repository;
  final favorites = Favorites();
  final push = Push();
  final account = Account();

  TariffData? data;
  TariffSearch? _search;
  Map<String, TariffRow> _byCode = const {};
  String lang = 'ar';
  Object? loadError;

  /// The freight prices strip: off until the person says yes, asked once on first
  /// launch, switchable in settings (owner 2026-10-28).
  bool showRates = false;
  bool ratesAsked = false;

  S get s => S(lang);
  bool get ready => data != null;

  Future<void> setShowRates(bool on) async {
    showRates = on;
    ratesAsked = true;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool('show_rates', on);
    await p.setBool('rates_asked', true);
  }

  Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    lang = prefs.getString('lang') ?? 'ar';
    showRates = prefs.getBool('show_rates') ?? false;
    ratesAsked = prefs.getBool('rates_asked') ?? false;
    await favorites.load();
    unawaited(push.start(lang));
    unawaited(account.start(lang));
    try {
      _use(await repository.loadLocal());
    } catch (e) {
      loadError = e;
      notifyListeners();
    }
    // background check for a newer published file
    final fresh = await repository.refresh();
    if (fresh != null) _use(fresh);
  }

  /// Forced check from the About screen. True when a newer file was loaded.
  Future<bool> checkForUpdate() async {
    final fresh = await repository.refresh(force: true);
    if (fresh == null) return false;
    _use(fresh);
    return true;
  }

  void _use(TariffData d) {
    data = d;
    _search = TariffSearch(d.rows);
    _byCode = {for (final r in d.rows) r.code: r};
    loadError = null;
    notifyListeners();
  }

  List<TariffRow> search(String q) => _search?.search(q) ?? const [];
  TariffRow? byCode(String code) => _byCode[code];
  List<TariffRow> inCategory(String c) => data?.rows.where((r) => r.category(lang) == c).toList() ?? const [];
  List<String> get categories => data == null ? const [] : TariffSearch.categories(data!.rows, lang);

  Future<void> toggleLang() async {
    lang = lang == 'ar' ? 'en' : 'ar';
    notifyListeners();
    unawaited(push.setLang(lang));
    unawaited(account.setLang(lang));
    await (await SharedPreferences.getInstance()).setString('lang', lang);
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
