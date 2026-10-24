import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../app_state.dart';
import '../config.dart';
import 'motion.dart';
import 'theme.dart';

/// MIRA as it already runs on chat.midtrans.org, opened inside the app.
/// No change to MIRA: that origin is already on MIRA's allow-list.
class MiraScreen extends StatefulWidget {
  const MiraScreen({super.key, this.standalone = false});

  /// Pushed from a code page (own app bar) rather than shown as a tab.
  final bool standalone;

  @override
  State<MiraScreen> createState() => _MiraScreenState();
}

class _MiraScreenState extends State<MiraScreen> with AutomaticKeepAliveClientMixin {
  late final WebViewController _controller;
  bool _failed = false;
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.ground)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => mounted ? setState(() => _loading = false) : null,
        onWebResourceError: (e) {
          if (e.isForMainFrame ?? true) setState(() => _failed = true);
        },
        // links that leave MIRA (website pages, WhatsApp, email) open outside the app
        onNavigationRequest: (req) {
          final uri = Uri.parse(req.url);
          if (uri.host == Uri.parse(AppConfig.miraUrl).host) return NavigationDecision.navigate;
          launchUrl(uri, mode: LaunchMode.externalApplication);
          return NavigationDecision.prevent;
        },
      ))
      ..loadRequest(Uri.parse(AppConfig.miraUrl));
  }

  void _retry() {
    setState(() {
      _failed = false;
      _loading = true;
    });
    _controller.loadRequest(Uri.parse(AppConfig.miraUrl));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = AppScope.of(context).s;
    final body = _failed
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.wifi_off, color: AppColors.gold, size: 40),
                const SizedBox(height: 12),
                Text(s.miraOffline, textAlign: TextAlign.center, style: const TextStyle(height: 1.7)),
                const SizedBox(height: 16),
                Pressable(child: OutlinedButton(onPressed: _retry, child: Text(s.retry))),
              ]),
            ),
          )
        : Stack(children: [
            WebViewWidget(controller: _controller),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
          ]);
    return Scaffold(appBar: AppBar(title: Text(s.tabMira)), body: SafeArea(top: false, child: body));
  }
}
