import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// پاراستنی پرسیار/وەڵام لە سکرینشۆت و تۆمارکردنی شاشە (Android + iOS).
///
/// بە MethodChannel خۆماڵی — بێ پلاگینی screen_protector (کە بیڵدی APK تێکدەدا).
class QuizScreenSecurity {
  QuizScreenSecurity._();

  static const _channel = MethodChannel('barav_quiz/screen_security');
  static const _events = EventChannel('barav_quiz/screen_security_events');

  static bool _active = false;
  static StreamSubscription<dynamic>? _recordingSub;
  static void Function(bool recording)? onRecordingChanged;

  static bool get isActive => _active;

  /// چالاککردن لە کاتی کویزی زیندوو.
  static Future<void> enable() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('enable');
      _active = true;
      _listenRecording();
    } catch (e, st) {
      debugPrint('QuizScreenSecurity.enable failed: $e\n$st');
    }
  }

  /// ناکارا کردن دوای جێهێشتنی کویز.
  static Future<void> disable() async {
    if (kIsWeb || !_active) return;
    try {
      await _recordingSub?.cancel();
      _recordingSub = null;
      await _channel.invokeMethod<void>('disable');
      _active = false;
    } catch (e, st) {
      debugPrint('QuizScreenSecurity.disable failed: $e\n$st');
      _active = false;
    }
  }

  static Future<bool> isRecording() async {
    if (kIsWeb || !Platform.isIOS) return false;
    try {
      final value = await _channel.invokeMethod<bool>('isRecording');
      return value ?? false;
    } catch (_) {
      return false;
    }
  }

  static void _listenRecording() {
    if (!Platform.isIOS) return;
    _recordingSub?.cancel();
    _recordingSub = _events.receiveBroadcastStream().listen((event) {
      if (event is bool) {
        onRecordingChanged?.call(event);
      }
    });
  }
}
