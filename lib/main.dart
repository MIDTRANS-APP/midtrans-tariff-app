import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'shot.dart';
import 'ui/item_screen.dart';
import 'ui/about_screen.dart';
import 'ui/customs_screen.dart';
import 'ui/favorites_screen.dart';
import 'ui/mira_screen.dart';
import 'ui/news_prompt.dart';
import 'ui/search_screen.dart';
import 'ui/theme.dart';

final _messenger = GlobalKey<ScaffoldMessengerState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  state.push.onForeground = (title, body) => _messenger.currentState?.showSnackBar(
        SnackBar(content: Text(title.isEmpty ? body : '$title\n$body'), duration: const Duration(seconds: 6)),
      );
  state.start();
  runApp(TariffApp(state: state));
}

class TariffApp extends StatelessWidget {
  const TariffApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: Builder(builder: (context) {
        final app = AppScope.of(context);
        return MaterialApp(
          title: app.s.appName,
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: _messenger,
          theme: buildTheme(),
          locale: Locale(app.lang),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomeShell(),
        );
      }),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  bool _miraOpened = false; // MIRA loads only once its tab is first opened

  @override
  void initState() {
    super.initState();
    if (!Shot.on) return;
    _tab = switch (Shot.mode) { 'favorites' => 1, 'customs' => 2, 'about' => 4, _ => 0 };
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final app = AppScope.of(context);
      final code = Shot.arg('item');
      final q = Shot.arg('mira');
      for (var i = 0; i < 100 && !app.ready; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (!mounted) return;
      if (Shot.demo) return _playDemo();
      if (code.isNotEmpty) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ItemScreen(code: code)));
      } else if (Shot.mode == 'news') {
        NewsPrompt.show(context, null);
      } else if (Shot.mode == 'team') {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MiraScreen(standalone: true, askTeam: true)));
      } else if (q.isNotEmpty) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => MiraScreen(standalone: true, question: q)));
      }
    });
  }

  /// SHOT=demo: about 25 seconds of the app in use, recorded for the App Store preview.
  Future<void> _playDemo() async {
    Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));
    Future<void> typeInto(ValueNotifier<String?> n, String text, int ms) async {
      for (var i = 1; i <= text.length; i++) {
        n.value = text.substring(0, i);
        await wait(ms);
      }
    }

    await wait(8000); // time to start the screen recording
    await wait(1500);
    await typeInto(Shot.query, 'مكيف هواء', 260);
    await wait(2200);
    if (!mounted) return;
    final nav = Navigator.of(context);
    nav.push(MaterialPageRoute(builder: (_) => const ItemScreen(code: '841510109999')));
    await wait(2200);
    await typeInto(Shot.calcFeed, '12000', 300);
    await wait(3000);
    nav.pop();
    await wait(900);
    if (!mounted) return;
    setState(() => _tab = 2);
    await wait(3000);
    if (!mounted) return;
    nav.push(MaterialPageRoute(
        builder: (_) => const MiraScreen(standalone: true, question: 'كم الرسم الجمركي على المكيفات في السعودية؟')));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).s;
    return Scaffold(
      body: IndexedStack(index: _tab, children: [
        const SearchScreen(),
        const FavoritesScreen(),
        const CustomsScreen(),
        _miraOpened ? const MiraScreen() : const SizedBox.shrink(),
        const AboutScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() {
          _tab = i;
          if (i == 3) _miraOpened = true;
        }),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.search), label: s.tabSearch),
          NavigationDestination(icon: const Icon(Icons.star_border), selectedIcon: const Icon(Icons.star), label: s.tabFavorites),
          NavigationDestination(icon: const Icon(Icons.account_balance_outlined), selectedIcon: const Icon(Icons.account_balance), label: s.tabCustoms),
          NavigationDestination(icon: const Icon(Icons.chat_bubble_outline), label: s.tabMira),
          NavigationDestination(icon: const Icon(Icons.info_outline), label: s.tabAbout),
        ],
      ),
    );
  }
}
