import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// دەستنیشانکردنی ئامێری ڕووت / جەیلبرێک / سیمولەیتەر (بێ safe_device).
class DeviceIntegrityService {
  DeviceIntegrityService._();

  static final DeviceIntegrityService instance = DeviceIntegrityService._();

  static const _channel = MethodChannel('barav_quiz/device_integrity');

  bool? _compromised;
  bool _initialized = false;

  /// null = هێشتا نەپشکنراوە.
  bool? get compromised => _compromised;

  bool get isCompromised => _compromised == true;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

  /// لە debug ـدا ڕێگە دەدات بۆ پەرەپێدان؛ لە release ـدا ڕووت/جەیلبرێک قەدەغە دەکات.
  Future<bool> refresh() async {
    await init();

    if (kDebugMode) {
      _compromised = false;
      return false;
    }

    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('check');
      final compromised = raw?['compromised'] == true;
      _compromised = compromised;
    } catch (e, st) {
      debugPrint('DeviceIntegrityService.refresh failed: $e\n$st');
      // ئەگەر پشکنین شکستی هێنا — قفڵ ناکرێت بۆ ئەوەی یوزەری ئاسایی نەگیرێت.
      _compromised = false;
    }
    return isCompromised;
  }

  Future<bool> ensureSafe() async {
    if (_compromised == true) return false;
    await refresh();
    return !isCompromised;
  }
}
