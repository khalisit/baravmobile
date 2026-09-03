import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// سیستەمی Extra Life — ٣ ڕیکلام = ١ ژیان.
class ExtraLifeController extends ChangeNotifier {
  ExtraLifeController._();

  static final ExtraLifeController instance = ExtraLifeController._();

  static const int adsPerLife = 3;
  static const String _livesPrefix = 'extra_lives_';
  static const String _progressPrefix = 'extra_life_ads_';

  SharedPreferences? _prefs;
  String? _userKey;
  int _lives = 0;
  int _adProgress = 0;

  int get lives => _lives;
  int get adProgress => _adProgress;
  int get adsNeededForNext => adsPerLife - _adProgress;
  double get progressRatio => _adProgress / adsPerLife;
  bool get hasLives => _lives > 0;

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> bindUser(String? email) async {
    await load();
    if (email == null || email.isEmpty) {
      _userKey = null;
      _lives = 0;
      _adProgress = 0;
      notifyListeners();
      return;
    }
    _userKey = email.toLowerCase();
    _lives = _prefs?.getInt('$_livesPrefix$_userKey') ?? 0;
    _adProgress = (_prefs?.getInt('$_progressPrefix$_userKey') ?? 0)
        .clamp(0, adsPerLife - 1);
    notifyListeners();
  }

  Future<void> clear() => bindUser(null);

  /// دوای تەواوبوونی بینینی ڕیکلامێک.
  Future<bool> registerAdWatched() async {
    if (_userKey == null) return false;
    await load();
    _adProgress += 1;
    var granted = false;
    if (_adProgress >= adsPerLife) {
      _adProgress = 0;
      _lives += 1;
      granted = true;
    }
    await _persist();
    notifyListeners();
    return granted;
  }

  /// بەکارهێنانی یەک Extra Life لە کویز.
  Future<bool> consumeLife() async {
    if (_lives <= 0 || _userKey == null) return false;
    await load();
    _lives -= 1;
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> _persist() async {
    final key = _userKey;
    if (key == null || _prefs == null) return;
    await _prefs!.setInt('$_livesPrefix$key', _lives);
    await _prefs!.setInt('$_progressPrefix$key', _adProgress);
  }
}
