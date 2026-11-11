import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

/// One line of the conversation, in the shape MIRA's brain takes as history.
class MiraTurn {
  const MiraTurn(this.role, this.content);
  final String role; // 'user' or 'assistant'
  final String content;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class MiraReply {
  const MiraReply(this.answer, {this.handoffSuggested = false, this.tag, this.rfqPending = false});
  final String answer;
  final bool handoffSuggested;

  /// MIRA has a quote ready that she did not send, because the visitor is not
  /// registered yet (MIRA's server, owner 2026-11-10).
  final bool rfqPending;

  /// 'personal_request' or 'priority' when MIRA's brain marks the question so.
  final String? tag;
}

/// The visitor's contact details, asked once in MIRA's own words (as on chat.midtrans.org)
/// and kept on the phone for the next request. Email is optional (owner 2026-10-25).
class MiraLead {
  const MiraLead({this.name = '', this.phone = '', this.country = '', this.whatsapp = '', this.email = '', this.company = '', this.visitorId = '', this.news = ''});
  final String name;
  final String phone; // international, +971…
  final String country; // ISO code of the phone's country
  final String whatsapp; // international, +971…
  final String email;
  final String company;
  final String visitorId;

  /// Periodic customs news the visitor asked for: 'gcc', 'sy' or 'gcc,sy' (owner 2026-11-10).
  final String news;

  /// In this app every field is required before talking to MIRA (owner 2026-11-10):
  /// name, phone, WhatsApp and email.
  bool get complete => name.isNotEmpty && phone.isNotEmpty && whatsapp.isNotEmpty && email.isNotEmpty;

  /// A signed-in account (visitorId acct-…): registered whatever its profile holds - the
  /// signed-in are never asked (owner 2026-11-10/11).
  bool get account => visitorId.startsWith('acct-');
  bool get registered => complete || account;

  /// The lines the Desk reads for this visitor.
  String get summary => [name, phone, if (whatsapp.isNotEmpty) 'WhatsApp $whatsapp', if (email.isNotEmpty) email].join('\n');

  Map<String, String> get visitor => {
        if (name.isNotEmpty) 'name': name,
        if (email.isNotEmpty) 'email': email,
        if (phone.isNotEmpty) 'phone': phone,
      };

  Map<String, String> toJson() =>
      {'name': name, 'phone': phone, 'country': country, 'whatsapp': whatsapp, 'email': email, 'company': company, 'visitorId': visitorId, 'news': news};

  static MiraLead fromJson(Map<String, dynamic> m) => MiraLead(
        name: '${m['name'] ?? ''}',
        phone: '${m['phone'] ?? ''}',
        country: '${m['country'] ?? ''}',
        whatsapp: '${m['whatsapp'] ?? ''}',
        email: '${m['email'] ?? ''}',
        company: '${m['company'] ?? ''}',
        visitorId: '${m['visitorId'] ?? ''}',
        news: '${m['news'] ?? ''}',
      );

  MiraLead withVisitorId(String id) =>
      MiraLead(name: name, phone: phone, country: country, whatsapp: whatsapp, email: email, company: company, visitorId: id, news: news);

  MiraLead withNews(String n) =>
      MiraLead(name: name, phone: phone, country: country, whatsapp: whatsapp, email: email, company: company, visitorId: visitorId, news: n);
}

/// The team's answer to a request: its number (MIR-…) when MIRA's server issued one.
class MiraHandoff {
  const MiraHandoff({this.number, this.anyOnline = false, this.replyBy, this.isTest = false});
  final String? number;
  final bool anyOnline;
  final String? replyBy;
  final bool isTest;
}

/// MIRA's brain, called directly so the chat is drawn by the app in its own design
/// (owner 2026-10-28). Same endpoint and body as chat.midtrans.org; the requests carry
/// that page's origin, which MIRA already allows (owner's choice, 2026-10-28).
class MiraClient {
  MiraClient({http.Client? client}) : _http = client ?? http.Client();
  final http.Client _http;

  static const _sessionKey = 'mira_session_id';
  static const _leadKey = 'mira_lead';
  String? _sessionId;

  static Uri _api(String path) => Uri.parse(AppConfig.miraApi.replaceFirst(RegExp(r'/ask$'), path));
  static const _headers = {'content-type': 'application/json', 'origin': AppConfig.miraOrigin};

  /// The page the Desk shows for this conversation: the app's page, and which phone.
  static String get sourcePage {
    var os = 'app';
    try {
      os = Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'app');
    } catch (_) {}
    return '${AppConfig.miraSourcePage}?app=$os';
  }

  Future<String> sessionId() => _session();

  /// A new chat is a new conversation in the Desk too.
  Future<void> newSession() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_sessionKey);
    _sessionId = null;
  }

  Future<MiraLead?> savedLead() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_leadKey);
    if (raw == null) return null;
    try {
      final lead = MiraLead.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return lead.complete ? lead : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLead(MiraLead lead) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_leadKey, jsonEncode(lead.toJson()));
  }

  /// The visitor's details in MIRA's list of visitors, as chat.midtrans.org records them.
  Future<void> upsertVisitor(MiraLead lead, {required String lang}) async {
    try {
      await _http
          .post(_api('/visitor/upsert'),
              headers: _headers,
              body: jsonEncode({
                'visitor_id': lead.visitorId,
                'name': lead.name,
                // the sheet has one phone column: the WhatsApp number, by which the team and
                // the news reach the visitor (owner 2026-11-10); the other number goes in the Desk
                'phone': lead.whatsapp.isNotEmpty ? lead.whatsapp : lead.phone,
                'country': lead.country,
                'email': lead.email,
                'company': lead.company,
                'lang': lang,
                'channel': 'chat',
                // MIRA's visitor sheet has no news column: the choice rides on the page line
                'page_url': lead.news.isEmpty ? sourcePage : '$sourcePage&news=${lead.news}',
              }))
          .timeout(const Duration(seconds: 15));
    } catch (_) {/* best effort, as on the website */}
  }

  /// A request for the team: MIRA's server gives it its number (the same number again
  /// for a retry with the same [requestKey]). Null when the server did not answer.
  Future<MiraHandoff?> handoff(MiraLead lead, {required String lang, required String requestKey, String kind = 'staff'}) async {
    try {
      final res = await _http
          .post(_api('/handoff'),
              headers: _headers,
              body: jsonEncode({'session_id': await _session(), 'visitor': lead.visitor, 'lang': lang, 'kind': kind, 'request_key': requestKey}))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final d = (jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>)['data'] as Map<String, dynamic>? ?? const {};
      return MiraHandoff(
        number: d['request_number'] as String?,
        anyOnline: d['any_online'] == true,
        replyBy: d['reply_by'] is String ? d['reply_by'] as String : null,
        isTest: d['is_test'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  static String newRequestKey() {
    final r = Random.secure();
    return 'r-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}-${List.generate(6, (_) => r.nextInt(36).toRadixString(36)).join()}';
  }

  Future<String> _session() async {
    if (_sessionId != null) return _sessionId!;
    final p = await SharedPreferences.getInstance();
    var id = p.getString(_sessionKey);
    if (id == null) {
      final r = Random.secure();
      id = 'tariff-app-${List.generate(16, (_) => r.nextInt(16).toRadixString(16)).join()}';
      await p.setString(_sessionKey, id);
    }
    return _sessionId = id;
  }

  /// [tariffCode] (12 digits, no dots) makes MIRA answer from the GCC tariff for that code.
  /// Throws on network or server failure; one retry, as the web chat does.
  /// [visitor]: the registered visitor (account or details given), or null for a guest,
  /// whose quote MIRA's server then holds back instead of sending it to the team.
  Future<MiraReply> ask(String message, {required String lang, List<MiraTurn> history = const [], String? tariffCode, MiraLead? visitor}) async {
    final recent = history.length > 4 ? history.sublist(history.length - 4) : history;
    final body = jsonEncode({
      'message': message,
      'lang': lang,
      'history': [for (final t in recent) t.toJson()],
      // The app's own scope (Syrian tariff + shipping quotes) is set by MIRA's server.
      'app': AppConfig.miraAppId,
      if (tariffCode != null) 'tariff_card': {'code': tariffCode, 'scope': 'sy', 'on_page': true},
      'session_id': await _session(),
      'registered': visitor != null,
      if (visitor != null) 'visitor': visitor.visitor,
    });
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final res = await _http
            .post(Uri.parse(AppConfig.miraApi),
                headers: {'content-type': 'application/json', 'origin': AppConfig.miraOrigin},
                body: body)
            .timeout(const Duration(seconds: 60));
        if (res.statusCode != 200) throw Exception('http_${res.statusCode}');
        final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        final answer = data?['answer'] as String?;
        if (answer == null || answer.trim().isEmpty) throw Exception(json['error'] ?? 'no_answer');
        final tag = data?['personal_request'] != null ? 'personal_request' : (data?['priority'] != null ? 'priority' : null);
        return MiraReply(answer.trim(), handoffSuggested: data?['handoff_suggested'] == true, tag: tag, rfqPending: data?['rfq_pending'] == true);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('mira_failed');
  }
}

/// Every visitor and MIRA line goes to the Desk, as chat.midtrans.org sends it
/// (/chat/mirror): MIRA appears there as a staff member and the team sees who asked
/// what. Nothing is sent until the visitor has written something; a line that fails
/// stays queued and goes with the next batch. Best effort, never blocks the chat.
class MiraMirror {
  MiraMirror(this._client, {http.Client? http}) : _http = http ?? _client._http;
  final MiraClient _client;
  final http.Client _http;
  final _queue = <Map<String, Object?>>[];
  /// Nothing reaches the Desk before the visitor is registered (owner 2026-11-10); then
  /// the whole conversation goes, the earlier lines first.
  bool get _released => lead != null && lead!.registered;
  bool _sending = false;
  Timer? _timer;
  MiraLead? lead;
  String lang = 'ar';

  void note({required bool visitor, required String text, Map<String, Object?> meta = const {}}) {
    final body = text.trim();
    if (body.isEmpty) return;
    final r = Random.secure();
    _queue.add({
      'turn_id': 't-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}-${List.generate(6, (_) => r.nextInt(36).toRadixString(36)).join()}',
      'role': visitor ? 'visitor' : 'mira',
      'text': body.length > 8000 ? body.substring(0, 8000) : body,
      'at': DateTime.now().toUtc().toIso8601String(),
      'meta': visitor ? const <String, Object?>{} : meta,
    });
    if (_queue.length > 200) _queue.removeRange(0, _queue.length - 200);
    _schedule();
  }

  /// A new chat starts a new Desk conversation; anything not yet sent goes first.
  Future<void> reset() async {
    await flush();
    _queue.clear();
  }

  void _schedule() {
    if (_timer != null || !_released) return;
    _timer = Timer(const Duration(milliseconds: 1500), () {
      _timer = null;
      flush();
    });
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_sending || _queue.isEmpty || !_released) return;
    _sending = true;
    final batch = _queue.take(50).toList();
    try {
      final res = await _http
          .post(MiraClient._api('/mirror'),
              headers: MiraClient._headers,
              body: jsonEncode({
                'session_id': await _client._session(),
                'channel': 'chat',
                'page_url': MiraClient.sourcePage,
                'lang': lang,
                'visitor': (lead == null || lead!.visitor.isEmpty) ? null : lead!.visitor,
                'turns': batch,
              }))
          .timeout(const Duration(seconds: 20));
      // as the website: a refused batch (4xx other than 429) is not sent again
      if (res.statusCode == 200 || (res.statusCode >= 400 && res.statusCode < 500 && res.statusCode != 429)) {
        _queue.removeRange(0, batch.length.clamp(0, _queue.length));
      }
    } catch (_) {
      // stays queued
    } finally {
      _sending = false;
      if (_queue.isNotEmpty) _schedule();
    }
  }
}
