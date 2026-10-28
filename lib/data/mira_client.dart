import 'dart:convert';
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
  const MiraReply(this.answer, {this.handoffSuggested = false});
  final String answer;
  final bool handoffSuggested;
}

/// MIRA's brain, called directly so the chat is drawn by the app in its own design
/// (owner 2026-10-28). Same endpoint and body as chat.midtrans.org; the requests carry
/// that page's origin, which MIRA already allows (owner's choice, 2026-10-28).
class MiraClient {
  MiraClient({http.Client? client}) : _http = client ?? http.Client();
  final http.Client _http;

  static const _sessionKey = 'mira_session_id';
  String? _sessionId;

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

  /// The app is for the Syrian tariff only (owner 2026-10-28): every conversation opens
  /// with this exchange, so MIRA answers about Syria and does not ask for the destination.
  /// It goes in the history, not in the message, so MIRA's code search reads only the question.
  static List<MiraTurn> _context(String lang) => lang == 'en'
      ? const [
          MiraTurn('user', 'I am using the MIDTRANS Syrian Customs Tariff app. My questions are about importing into Syria and the Syrian customs tariff only.'),
          MiraTurn('assistant', 'Understood, I will answer about the Syrian customs tariff and importing into Syria.'),
        ]
      : const [
          MiraTurn('user', 'أستخدم تطبيق التعرفة الجمركية السورية من ميدترانس. أسئلتي عن الاستيراد إلى سوريا والتعرفة الجمركية السورية فقط.'),
          MiraTurn('assistant', 'تمام، سأجيبك عن التعرفة الجمركية السورية والاستيراد إلى سوريا.'),
        ];

  /// [tariffCode] (8 digits, no dots) makes MIRA answer from the Syrian tariff for that code.
  /// Throws on network or server failure; one retry, as the web chat does.
  Future<MiraReply> ask(String message, {required String lang, List<MiraTurn> history = const [], String? tariffCode}) async {
    final recent = history.length > 4 ? history.sublist(history.length - 4) : history;
    final body = jsonEncode({
      'message': message,
      'lang': lang,
      'history': [for (final t in [..._context(lang), ...recent]) t.toJson()],
      if (tariffCode != null) 'tariff_card': {'code': tariffCode, 'scope': 'syria', 'on_page': true},
      'session_id': await _session(),
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
        return MiraReply(answer.trim(), handoffSuggested: data?['handoff_suggested'] == true);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('mira_failed');
  }
}
