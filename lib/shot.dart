import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Store screenshots on the simulator (debug builds only, never in a store build):
///   SIMCTL_CHILD_SHOT='search:اسمنت' xcrun simctl launch booted com.midtrans.gcctariff
/// SHOT = home, search:QUERY, item:CODE, mira:QUESTION, favorites or about
/// SHOT_LANG = ar | en ; SHOT_CALC = a value typed into the item page calculator.
class Shot {
  static const _defines = {
    'SHOT': String.fromEnvironment('SHOT'),
    'SHOT_LANG': String.fromEnvironment('SHOT_LANG'),
    'SHOT_CALC': String.fromEnvironment('SHOT_CALC'),
  };
  // --dart-define first (flutter run), then the launch environment (simctl launch)
  static String _env(String k) =>
      !kDebugMode ? '' : (_defines[k]!.isNotEmpty ? _defines[k]! : (Platform.environment[k] ?? ''));
  static String get mode => _env('SHOT');
  static bool get on => mode.isNotEmpty;
  static String get lang => _env('SHOT_LANG').isEmpty ? 'ar' : _env('SHOT_LANG');
  static String get calc => _env('SHOT_CALC');
  static String arg(String prefix) => mode.startsWith('$prefix:') ? mode.substring(prefix.length + 1) : '';
}
