import 'dart:async';

import 'package:flutter/material.dart';

import '../ads/ad_slot.dart';
import '../app_state.dart';
import '../data/tariff_models.dart';
import '../l10n.dart';
import 'category_screen.dart';
import 'motion.dart';
import 'rates_ticker.dart';
import 'theme.dart';
import 'widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () => setState(() => _query = v));
  }

  void _setQuery(String q) {
    _controller.text = q;
    setState(() => _query = q);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.s;
    final results = _query.trim().isEmpty ? const <TariffRow>[] : app.search(_query);
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset('assets/branding/app-icon-96.png', width: 34, height: 34, filterQuality: FilterQuality.medium),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.appName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              Text(s.byMidtrans, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: app.toggleLang, child: Text(s.language, style: const TextStyle(color: AppColors.text))),
        ],
      ),
      // The field sits outside the list, under a fixed key: when the hero disappears on the
      // first letter the list's children shift, and a field inside it was rebuilt as a new
      // one, losing focus and closing the keyboard after every letter.
      body: !app.ready
          ? Center(child: app.loadError != null ? Text('${app.loadError}') : Text(s.loading))
          : Column(children: [
              const RatesTicker(),
              if (_query.trim().isEmpty) _hero(s),
              Padding(
                key: const ValueKey('search-field'),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: TextField(
                  controller: _controller,
                  onChanged: _onChanged,
                  onSubmitted: (v) => app.favorites.addRecent(v),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: s.searchLabel,
                    hintText: s.searchHint,
                    prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(tooltip: MaterialLocalizations.of(context).deleteButtonTooltip, icon: const Icon(Icons.close), onPressed: () => _setQuery('')),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [if (_query.trim().isEmpty) ..._home(app) else ..._results(app, results)],
                ),
              ),
            ]),
    );
  }

  Widget _hero(S s) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 80, height: 1, color: const Color(0xFF8F8361)),
            // Emblem of the General Authority for Borders and Customs, used with its written permission.
            const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Image(image: AssetImage('assets/branding/ports-emblem.png'), height: 32)),
            Container(width: 80, height: 1, color: const Color(0xFF8F8361)),
          ]),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2F4F4), Color(0xFFA7B0B0)]).createShader(r),
            child: Text(s.searchTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(height: 8),
          Text(s.searchIntro, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.7, color: AppColors.muted)),
        ]),
      );

  List<Widget> _home(AppState app) {
    final s = app.s;
    final recent = app.favorites.recent;
    return [
      PushAskCard(push: app.push),
      if (recent.isNotEmpty) ...[
        GoldHeading(s.recent),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final q in recent) Pressable(child: ActionChip(label: Text(q), onPressed: () => _setQuery(q))),
          ]),
        ),
      ],
      GoldHeading(s.browse),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.3,
          children: [
            for (final c in app.categories)
              Pressable(
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryScreen(category: c))),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Align(alignment: AlignmentDirectional.centerStart, child: Text(c, style: const TextStyle(fontSize: 13, height: 1.5))),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      const UnofficialNotice(),
    ];
  }

  List<Widget> _results(AppState app, List<TariffRow> results) {
    final s = app.s;
    final digits = _query.replaceAll(RegExp(r'[\s.]'), '');
    final isCode = RegExp(r'^\d{4,}$').hasMatch(digits);
    return [
      if (results.isEmpty && isCode)
        _codeNotFound(app, digits)
      else
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: Text(results.isEmpty ? s.noResults : s.results(results.length), style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        ),
      for (var i = 0; i < results.length; i++)
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 10), child: RowTile(results[i])),
      if (results.isNotEmpty) const AdSlot(AdPlacement.resultsBanner),
      const SizedBox(height: 16),
    ];
  }

  /// A code with no line in the Syrian table: ask to drop the last two digits or more,
  /// offer the shorter codes that do exist, and remind that only the first six digits
  /// (HS) are international (owner 2026-10-28).
  Widget _codeNotFound(AppState app, String digits) {
    final s = app.s;
    final shorter = <String>[];
    for (var n = digits.length - 2; n >= 4; n -= 2) {
      final c = digits.substring(0, n);
      if (app.search(c).isNotEmpty) shorter.add(c);
      if (shorter.length == 2) break;
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gold)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.info_outline, color: AppColors.gold, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(s.codeNotFound(digits), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 8),
        Text(s.trimDigits, style: const TextStyle(fontSize: 13, height: 1.6)),
        if (shorter.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in shorter)
              Pressable(child: ActionChip(avatar: const Icon(Icons.search, size: 18, color: AppColors.gold), label: Text(s.tryCode(c)), onPressed: () => _setQuery(c))),
          ]),
        ],
        const SizedBox(height: 10),
        Text(s.hsWorldwide, style: const TextStyle(fontSize: 12, height: 1.6, color: AppColors.muted)),
      ]),
    );
  }
}
