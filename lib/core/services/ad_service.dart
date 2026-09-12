import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../session/session_controller.dart';
import '../../data/api_service.dart';

/// AdService — بەڕێوەبردنی ڕیکلامی Rewarded بۆ وەرگرتنی هەڵی زیادەیی
class AdService extends ChangeNotifier {
  AdService._();
  static final AdService instance = AdService._();

  static String get _adUnitId {
    // بۆ تێستکردن (پێش بڵاوکردنەوەی ئەپ) پێویستە Test IDs ی گۆگڵ بەکاربێنیت
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // Test iOS
      // return 'ca-app-pub-3139189762957713/7101840755'; // Production iOS
    }
    return 'ca-app-pub-3940256099942544/5224354917'; // Test Android
    // return 'ca-app-pub-3139189762957713/6834247446'; // Production Android
  }

  static const int _adsRequiredForSkip = 3;
  static const String _prefKey = 'ad_watch_count';

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  int _watchCount = 0;

  /// شمارەی ڕیکلامی سەیرکراو
  int get watchCount => _watchCount;

  /// چەند ڕیکلامی تر پێویستە بۆ هەڵی نوێ
  int get adsNeeded => _adsRequiredForSkip - _watchCount;

  /// ڕێژەی تەواوبوون بۆ پڕوگرێس بار
  double get progressRatio => _watchCount / _adsRequiredForSkip;

  /// ئایا بەکارهێنەر دەتوانێت ڕیکلام سەیر بکات
  bool get canWatchAd => true;

  /// بارکردنی شمارەی ذەخیرەکراو لە SharedPreferences
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _watchCount = prefs.getInt(_prefKey) ?? 0;
    debugPrint('[AdService] Loaded watch count: $_watchCount');
    notifyListeners();
    _preloadAd();
  }

  /// پێش بارکردنی ڕیکلام
  void _preloadAd() {
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;
    notifyListeners();
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          debugPrint('[AdService] Ad loaded successfully');
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoading = false;
          debugPrint('[AdService] Ad failed to load: $error');
          notifyListeners();
        },
      ),
    );
  }

  /// نیشاندانی ڕیکلام و دوای تەواوبوونی
  /// [onEarned] — بانگکرێت کاتێک هەڵی نوێ وەردەگیرێت
  /// [onError] — بانگکرێت کاتێک کێشەیەک هەبێت
  Future<void> showRewardedAd({
    required VoidCallback onEarned,
    required void Function(String message) onError,
  }) async {
    if (_rewardedAd == null) {
      // هەوڵ بدە دووبارە بارببکەیت
      _preloadAd();
      onError(
        'ڕیکلامەکە ئامادە نیە، تکایە چەند خولەکێک بوەستە و دووبارە هەوڵ بدە',
      );
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _preloadAd(); // پێشبارکردنی ڕیکلامی داهاتوو
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _preloadAd();
        onError('ڕیکلامەکە نیشان نەدرا: $error');
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) async {
        await _onAdWatched(onEarned);
      },
    );
  }

  /// کاتێک ڕیکلامێک تەواو سەیر کرا
  Future<void> _onAdWatched(VoidCallback onEarned) async {
    _watchCount++;
    final prefs = await SharedPreferences.getInstance();

    if (_watchCount >= _adsRequiredForSkip) {
      // هەڵی نوێ وەردەگیرێت
      _watchCount = 0;
      await prefs.setInt(_prefKey, 0);
      debugPrint('[AdService] Earned a skip! Calling API...');
      notifyListeners();
      await _addSkipViaApi();
      onEarned();
    } else {
      await prefs.setInt(_prefKey, _watchCount);
      debugPrint('[AdService] Watch count: $_watchCount/$_adsRequiredForSkip');
      notifyListeners();
    }
  }

  /// بانگکردنی API بۆ زیادکردنی skip
  Future<void> _addSkipViaApi() async {
    try {
      final session = SessionController.instance;
      final user = session.user;
      final token = session.token;
      if (user == null || token == null) return;

      final newSkip = await ApiService.addSkip(user.id, token);
      session.updateSkipLocal(newSkip);
      debugPrint('[AdService] Skip added. New total: $newSkip');
    } catch (e) {
      debugPrint('[AdService] Failed to add skip via API: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
