import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// کۆنترۆڵەری دارک / لایت مۆد بۆ تەواوی ئەپەکە.
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();
  static const String _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  /// بارکردنی ڕووکاری پاشەکەوتکراو لە SharedPreferences.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved == 'light') {
        _mode = ThemeMode.light;
      } else if (saved == 'dark') {
        _mode = ThemeMode.dark;
      } else if (saved == 'system') {
        _mode = ThemeMode.system;
      }
      _syncSystemUi();
    } catch (_) {
      _mode = ThemeMode.dark;
    }
    notifyListeners();
  }

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _syncSystemUi();
    notifyListeners();

    // پاشەکەوتکردن بە شێوازی ناهاوکات لە باکگراونددا
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_key, mode.name).catchError((_) => false);
    }).catchError((_) => null);
  }

  void toggle() =>
      setMode(isDark ? ThemeMode.light : ThemeMode.dark);

  void _syncSystemUi() {
    SystemChrome.setSystemUIOverlayStyle(
      isDark ? AppThemeOverlay.dark : AppThemeOverlay.light,
    );
  }
}

/// ستایلی ناوچەی ستاتەس‌بار بۆ هەردوو دۆخ.
abstract final class AppThemeOverlay {
  static const SystemUiOverlayStyle dark = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF10172A),
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static const SystemUiOverlayStyle light = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFFF3F1FA),
    systemNavigationBarIconBrightness: Brightness.dark,
  );
}
