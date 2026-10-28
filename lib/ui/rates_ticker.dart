import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../app_state.dart';
import '../data/rates.dart';
import 'mira_screen.dart';
import 'theme.dart';

/// A news-style strip of MIDTRANS sea-freight prices under the app bar (owner
/// 2026-10-28). It scrolls by itself, stops while touched, and a tap asks MIRA for a
/// quote on that route. Nothing is shown until there are prices (online or cached).
class RatesTicker extends StatefulWidget {
  const RatesTicker({super.key});

  @override
  State<RatesTicker> createState() => _RatesTickerState();
}

class _RatesTickerState extends State<RatesTicker> with SingleTickerProviderStateMixin {
  static const _speed = 28.0; // points per second
  final _scroll = ScrollController();
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  bool _held = false;
  List<ShippingRate> _rates = const [];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    RatesSource().load().then((r) {
      if (!mounted || r.isEmpty) return;
      setState(() => _rates = r);
      if (!MediaQuery.of(context).disableAnimations) _ticker.start();
    });
  }

  void _tick(Duration now) {
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (_held || !_scroll.hasClients || dt <= 0 || dt > 0.1) return;
    _scroll.jumpTo(_scroll.offset + _speed * dt);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scroll.dispose();
    super.dispose();
  }

  static String _usd(num v) {
    final s = v.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return '\$$b';
  }

  void _ask(ShippingRate r) {
    final s = AppScope.of(context).s;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MiraScreen(standalone: true, question: s.rateQuestion(r.container, r.from, r.to))));
  }

  @override
  Widget build(BuildContext context) {
    if (_rates.isEmpty) return const SizedBox.shrink();
    final s = AppScope.of(context).s;
    return Container(
      height: 38,
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          color: AppColors.gold,
          alignment: Alignment.center,
          child: Text(s.ratesLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ground)),
        ),
        Expanded(
          child: Listener(
            onPointerDown: (_) => _held = true,
            onPointerUp: (_) => _held = false,
            onPointerCancel: (_) => _held = false,
            child: ListView.builder(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) {
                final r = _rates[i % _rates.length];
                return InkWell(
                  onTap: () => _ask(r),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(children: [
                      Text(r.toSyria ? '🇸🇾' : '⚓', style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Text('${r.from} → ${r.to}', textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 12.5, color: AppColors.text)),
                      const SizedBox(width: 6),
                      Text(r.container, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                      const SizedBox(width: 6),
                      Text(_usd(r.priceUsd), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.goldText)),
                      const SizedBox(width: 14),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle)),
                    ]),
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}
