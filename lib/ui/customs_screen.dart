import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import 'theme.dart';
import 'widgets.dart';

/// Official customs websites of the six GCC states (owner 2026-11-07: «تبويب فيه روابط
/// الجمارك لكل بلد»). Links only, opened in the browser; checked 2026-11-07.
class _Office {
  const _Office(this.ar, this.en, this.url);
  final String ar;
  final String en;
  final String url;
}

class _Country {
  const _Country(this.flag, this.ar, this.en, this.offices);
  final String flag;
  final String ar;
  final String en;
  final List<_Office> offices;
}

const _countries = [
  _Country('🇸🇦', 'السعودية', 'Saudi Arabia', [
    _Office('هيئة الزكاة والضريبة والجمارك', 'Zakat, Tax and Customs Authority (ZATCA)', 'https://zatca.gov.sa/'),
  ]),
  _Country('🇦🇪', 'الإمارات', 'United Arab Emirates', [
    _Office('الهيئة الاتحادية للهوية والجنسية والجمارك وأمن المنافذ', 'Federal Authority for Identity, Citizenship, Customs and Port Security', 'https://icp.gov.ae/'),
    _Office('جمارك دبي', 'Dubai Customs', 'https://www.dubaicustoms.gov.ae/'),
    _Office('جمارك أبوظبي', 'Abu Dhabi Customs', 'https://www.adcustoms.gov.ae/'),
    _Office('جمارك الشارقة', 'Sharjah Customs', 'https://www.sharjahcustoms.gov.ae/'),
  ]),
  _Country('🇰🇼', 'الكويت', 'Kuwait', [
    _Office('الإدارة العامة للجمارك', 'General Administration of Customs', 'https://www.customs.gov.kw/'),
  ]),
  _Country('🇶🇦', 'قطر', 'Qatar', [
    _Office('الهيئة العامة للجمارك', 'General Authority of Customs', 'https://www.customs.gov.qa/'),
  ]),
  _Country('🇧🇭', 'البحرين', 'Bahrain', [
    _Office('شؤون الجمارك', 'Bahrain Customs Affairs', 'https://www.bahraincustoms.gov.bh/'),
  ]),
  _Country('🇴🇲', 'عُمان', 'Oman', [
    _Office('الإدارة العامة للجمارك', 'Directorate General of Customs', 'https://www.customs.gov.om/'),
  ]),
];

const _gcc = _Office('الأمانة العامة لمجلس التعاون الخليجي', 'GCC Secretariat General', 'https://www.gcc-sg.org/');

class CustomsScreen extends StatelessWidget {
  const CustomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.s;
    final en = app.lang == 'en';
    Widget office(_Office o) => ListTile(
          title: Text(en ? o.en : o.ar, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
          subtitle: Text(Uri.parse(o.url).host, textDirection: TextDirection.ltr,
              textAlign: en ? TextAlign.left : TextAlign.right,
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.gold),
          onTap: () => launchUrl(Uri.parse(o.url), mode: LaunchMode.externalApplication),
        );
    return Scaffold(
      appBar: AppBar(title: Text(s.tabCustoms)),
      body: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(s.customsIntro, style: const TextStyle(fontSize: 13.5, height: 1.7, color: AppColors.muted)),
        ),
        for (final c in _countries) ...[
          GoldHeading('${c.flag}  ${en ? c.en : c.ar}'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(child: Column(children: [for (final o in c.offices) office(o)])),
          ),
        ],
        GoldHeading(s.gccStates),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Card(child: office(_gcc))),
      ]),
    );
  }
}
