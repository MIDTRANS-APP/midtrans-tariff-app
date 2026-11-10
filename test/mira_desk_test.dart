import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:midtrans_gcc_tariff/data/mira_client.dart';

/// The app talks to MIRA's server the way chat.midtrans.org does (owner 2026-11-10:
/// one brain, one store, one set of visitor details): same doors, same fields.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('handoff sends the session, visitor and request key, and reads the number', () async {
    late http.Request sent;
    final client = MiraClient(client: MockClient((req) async {
      sent = req;
      return http.Response(jsonEncode({'ok': true, 'data': {'request_number': 'MIR-20261110-AB12', 'any_online': false, 'reply_by': 'hour'}}), 200);
    }));
    const lead = MiraLead(name: 'Test', phone: '+963930000000', country: 'SY');
    final h = await client.handoff(lead, lang: 'ar', requestKey: 'r-1');
    expect(sent.url.toString(), 'https://api.midtrans.org/api/v1/chat/handoff');
    expect(sent.headers['origin'], 'https://chat.midtrans.org');
    final body = jsonDecode(sent.body) as Map<String, dynamic>;
    expect(body['visitor'], {'name': 'Test', 'phone': '+963930000000'});
    expect(body['request_key'], 'r-1');
    expect(body['kind'], 'staff');
    expect((body['session_id'] as String).startsWith('gcc-tariff-app-'), isTrue);
    expect(h!.number, 'MIR-20261110-AB12');
    expect(h.replyBy, 'hour');
  });

  test('mirror waits for the visitor, then sends the turns with the app as the page', () async {
    final bodies = <Map<String, dynamic>>[];
    final mock = MockClient((req) async {
      bodies.add(jsonDecode(req.body) as Map<String, dynamic>);
      return http.Response('{"ok":true,"data":{}}', 200);
    });
    final client = MiraClient(client: mock);
    final mirror = MiraMirror(client, http: mock);
    mirror.note(visitor: false, text: 'MIRA line before the visitor wrote', meta: const {'source': 'flow'});
    await mirror.flush();
    expect(bodies, isEmpty, reason: 'nothing goes before the visitor writes');
    mirror.note(visitor: true, text: 'كم رسم القهوة؟');
    mirror.note(visitor: false, text: 'الجواب', meta: const {'source': 'brain', 'handoff_suggested': false});
    await mirror.flush();
    expect(bodies, hasLength(1));
    final b = bodies.single;
    expect(b['channel'], 'chat');
    expect((b['page_url'] as String).startsWith('https://www.mid-trans.com/gcc-tariff-app/?app='), isTrue);
    final turns = (b['turns'] as List).cast<Map<String, dynamic>>();
    expect(turns.map((t) => t['role']), ['mira', 'visitor', 'mira']);
    expect(turns.last['meta'], {'source': 'brain', 'handoff_suggested': false});
    await mirror.flush();
    expect(bodies, hasLength(1), reason: 'sent turns are not sent again');
  });

  test('a failed batch stays queued and goes again', () async {
    var fail = true;
    var calls = 0;
    final mock = MockClient((req) async {
      calls++;
      return fail ? http.Response('busy', 429) : http.Response('{"ok":true}', 200);
    });
    final mirror = MiraMirror(MiraClient(client: mock), http: mock);
    mirror.note(visitor: true, text: 'hello');
    await mirror.flush();
    fail = false;
    await mirror.flush();
    expect(calls, 2);
  });

  test('the visitor details are kept on the phone for the next request', () async {
    final client = MiraClient(client: MockClient((_) async => http.Response('{}', 200)));
    expect(await client.savedLead(), isNull);
    await client.saveLead(const MiraLead(name: 'A', phone: '+971500000000', country: 'AE', whatsapp: '+971500000000', email: 'a@b.co'));
    final l = await client.savedLead();
    expect(l!.phone, '+971500000000');
    expect(l.visitor, {'name': 'A', 'email': 'a@b.co', 'phone': '+971500000000'});
  });
}
