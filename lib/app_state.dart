import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/favorites.dart';
import 'data/search.dart';
import 'data/tariff_models.dart';
import 'data/tariff_repository.dart';
import 'l10n.dart';

class AppState extends ChangeNotifier {
  AppState({TariffRepository? repository}) : repository = repository ?? TariffRepository();

  final TariffRepository repository;
  final favorites = Favorites();

  TariffData? data;
  TariffSearch? _search;
  Map<String, TariffRow> _byCode = const {};
  String lang = 'ar';
  Object? loadError;

  S get s => S(lang);
  bool get ready => data != null;

  Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    lang = prefs.getString('lang') ?? 'ar';
    await favorites.load();
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
    await (await SharedPreferences.getInstance()).setString('lang', lang);
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
