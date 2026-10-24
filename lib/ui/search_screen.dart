import 'dart:async';

import 'package:flutter/material.dart';

import '../ads/ad_slot.dart';
import '../app_state.dart';
import '../data/tariff_models.dart';
import '../l10n.dart';
import 'category_screen.dart';
import 'motion.dart';
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
      body: !app.ready
          ? Center(child: app.loadError != null ? Text('${app.loadError}') : Text(s.loading))
          : ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                if (_query.trim().isEmpty) _hero(s),
                Padding(
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
                if (_query.trim().isEmpty) ..._home(app) else ..._results(app, results),
              ],
            ),
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
    return [
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
}
