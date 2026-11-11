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
  const MiraReply(this.answer, {this.handoffSuggested = false, this.rfqPending = false});
  final String answer;
  final bool handoffSuggested;

  /// A quote request is ready but the visitor is not signed in: nothing reaches the team
  /// until they sign in (owner 2026-11-10).
  final bool rfqPending;
}

/// The signed-in person MIRA greets by name and never asks to register (owner 2026-11-11).
class MiraVisitor {
  const MiraVisitor({this.name = '', this.email = '', this.phone = ''});
  final String name;
  final String email;
  final String phone;

  Map<String, String> toJson() => {'name': name, 'email': email, 'phone': phone};
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

  /// [tariffCode] (8 digits, no dots) makes MIRA answer from the Syrian tariff for that code.
  /// Throws on network or server failure; one retry, as the web chat does.
  Future<MiraReply> ask(String message, {required String lang, List<MiraTurn> history = const [], String? tariffCode, MiraVisitor? visitor}) async {
    final recent = history.length > 4 ? history.sublist(history.length - 4) : history;
    final body = jsonEncode({
      'message': message,
      'lang': lang,
      'history': [for (final t in recent) t.toJson()],
      // The app's own scope (Syrian tariff + shipping quotes) is set by MIRA's server.
      'app': AppConfig.miraAppId,
      'registered': visitor != null,
      if (visitor != null) 'visitor': visitor.toJson(),
      if (tariffCode != null) 'tariff_card': {'code': tariffCode, 'scope': 'sy', 'on_page': true},
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
        return MiraReply(answer.trim(), handoffSuggested: data?['handoff_suggested'] == true, rfqPending: data?['rfq_pending'] == true);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('mira_failed');
  }
}
