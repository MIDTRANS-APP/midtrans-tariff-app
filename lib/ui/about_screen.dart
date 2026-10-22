import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../config.dart';
import 'theme.dart';
import 'widgets.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _checking = false;

  Future<void> _check(AppState app) async {
    setState(() => _checking = true);
    final updated = await app.checkForUpdate();
    if (!mounted) return;
    setState(() => _checking = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(updated ? app.s.updated : app.s.upToDate)));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.s;
    final d = app.data;
    Widget link(String label, String url) => ListTile(
          title: Text(label),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        );
    return Scaffold(
      appBar: AppBar(title: Text(s.tabAbout)),
      body: ListView(children: [
        const UnofficialNotice(),
        if (d != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              [
                d.source.name,
                '${s.reviewed}: ${d.reviewedOn}',
                d.origin == 'bundle' ? s.fromBundle : s.fromCache,
                if (d.source.warning.isNotEmpty) d.source.warning,
              ].join('\n'),
              style: const TextStyle(fontSize: 12.5, height: 1.8, color: AppColors.muted),
            ),
          ),
        const SizedBox(height: 8),
        ListTile(
          title: Text(s.checkUpdate),
          trailing: _checking ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh),
          onTap: _checking ? null : () => _check(app),
        ),
        link(s.webPage, app.lang == 'ar' ? AppConfig.tariffPageAr : AppConfig.tariffPageEn),
        link(s.authority, AppConfig.authorityUrl),
        link(s.privacy, AppConfig.privacyUrl),
        ListTile(title: Text(s.language), trailing: const Icon(Icons.translate), onTap: app.toggleLang),
      ]),
    );
  }
}
