import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// هەزە / vibration — ئەندرۆید (Vibrator) + ئایفۆن (Taptic Engine).
class LiveQuizHaptics {
  LiveQuizHaptics._();

  static const _channel = MethodChannel('barav_quiz/haptics');

  static void quizStart() {
    unawaited(_invoke('quizStart', fallback: _pulseHeavyDart));
  }

  static void nextQuestion() {
    unawaited(_invoke('nextQuestion', fallback: _pulseMediumDart));
  }

  static void prepare() {
    unawaited(_channel.invokeMethod<void>('prepare').catchError((_) {}));
  }

  static Future<void> _invoke(
    String method, {
    required Future<void> Function() fallback,
  }) async {
    try {
      await _channel.invokeMethod<void>(method);
      // لەسەر هەندێک ئەندرۆید MethodChannel بەسە؛ لەسەر iOSیش.
      // ئەگەر بێدەنگ بوو، fallback.
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Native Vibrator ئیشی کرد — تەواو.
        return;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return;
      }
      await fallback();
    } catch (_) {
      await fallback();
    }
  }

  static Future<void> _pulseHeavyDart() async {
    try {
      await HapticFeedback.vibrate();
      await Future<void>.delayed(const Duration(milliseconds: 90));
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 70));
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> _pulseMediumDart() async {
    try {
      await HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.vibrate();
    } catch (_) {}
  }
}
