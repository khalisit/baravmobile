import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// شێوەزار / زمانە پشتگیریکراوەکان.
/// بۆ زیادکردنی زمانی نوێ: کلیلی JSON زیاد بکە و لێرەش تۆماری بکە.
enum AppLocale {
  ckb(code: 'ckb', isRtl: true),
  badini(code: 'badini', isRtl: false);

  const AppLocale({required this.code, required this.isRtl});

  final String code;
  final bool isRtl;

  static AppLocale fromCode(String code) {
    for (final locale in AppLocale.values) {
      if (locale.code == code) return locale;
    }
    return AppLocale.ckb;
  }
}

/// پرۆڤایدەری زمان — JSON جارێک دەبارێت و لە میمۆریدا دەمێنێتەوە.
class LocaleController extends ChangeNotifier {
  LocaleController._();

  static final LocaleController instance = LocaleController._();

  static const String _assetPath = 'assets/languages/translations.json';
  static const String _fallbackCode = 'ckb';
  static const String _prefsLocaleKey = 'locale_code';
  static const String _prefsChosenKey = 'dialect_chosen';

  final Map<String, Map<String, String>> _catalog = {};
  AppLocale _locale = AppLocale.ckb;
  bool _loaded = false;
  bool _hasChosenDialect = false;

  bool get isLoaded => _loaded;
  bool get hasChosenDialect => _hasChosenDialect;
  AppLocale get locale => _locale;
  bool get isSorani => _locale == AppLocale.ckb;
  bool get isBadini => _locale == AppLocale.badini;
  TextDirection get textDirection =>
      _locale.isRtl ? TextDirection.rtl : TextDirection.ltr;

  /// پێش `runApp` بانگ بکرێت — یەک جار، خێرا.
  Future<void> load() async {
    // cache: false — کلیلی نوێی JSON دوای گۆڕانکاری دەستبەجێ دەخوێنرێتەوە.
    final raw = await rootBundle.loadString(_assetPath, cache: false);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    _catalog.clear();
    for (final entry in decoded.entries) {
      final map = entry.value;
      if (map is! Map) continue;
      _catalog[entry.key] = {
        for (final item in map.entries)
          item.key.toString(): item.value.toString(),
      };
    }

    if (!_loaded) {
      try {
        final prefs = await SharedPreferences.getInstance();
        _hasChosenDialect = prefs.getBool(_prefsChosenKey) ?? false;
        final saved = prefs.getString(_prefsLocaleKey);
        if (saved != null) _locale = AppLocale.fromCode(saved);
      } catch (_) {
        _hasChosenDialect = false;
      }
    }

    _loaded = true;
  }

  void setLocale(AppLocale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    _persist();
  }

  /// هەڵبژاردنی یەکەمی شێوەزار لە دایالۆگەکە.
  Future<void> chooseDialect(AppLocale locale) async {
    _locale = locale;
    _hasChosenDialect = true;
    await _persist();
    notifyListeners();
  }

  void toggleDialect() =>
      setLocale(isSorani ? AppLocale.badini : AppLocale.ckb);

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsLocaleKey, _locale.code);
      await prefs.setBool(_prefsChosenKey, _hasChosenDialect);
    } catch (_) {
      // پاشەکەوتکردن شکستی هێنا — UI هەر کار دەکات.
    }
  }

  /// بۆ تێستەکان — دایالۆگی یەکەم کردنەوە پیشان نادات.
  @visibleForTesting
  void debugMarkDialectChosen([AppLocale locale = AppLocale.ckb]) {
    _locale = locale;
    _hasChosenDialect = true;
  }

  /// وەرگێڕان بە کلیلی JSON. ئەگەر نەدۆزرایەوە، دەگەڕێتەوە بۆ ckb.
  String t(String key) {
    return _catalog[_locale.code]?[key] ?? _catalog[_fallbackCode]?[key] ?? key;
  }
}

/// InheritedNotifier — سکرینەکان `LocaleScope.of(context)` بانگ دەکەن
/// تا لە گۆڕینی شێوەزاردا دووبارە build ببنەوە (نەک تەنها ئاراستە).
class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope not found in tree');
    return scope!.notifier!;
  }
}
