import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/api_service.dart';
import '../../data/models.dart';
import '../extra_life/extra_life_controller.dart';
import '../services/push_notification_service.dart';
import '../utils/player_progress.dart';

DateTime? _parseDateTime(dynamic val) {
  if (val == null) return null;
  String clean = val.toString().trim().replaceAll(' ', 'T');
  if (clean.isEmpty) return null;
  if (!clean.endsWith('Z') && !clean.contains('+')) {
    clean += 'Z';
  }
  return DateTime.tryParse(clean)?.toLocal();
}

/// دۆخی لۆگینی ئێستا — یوزەر یان ئەدمین.
class SessionController extends ChangeNotifier {
  SessionController._();

  static final SessionController instance = SessionController._();
  static const String _xpKeyPrefix = 'profile_xp_';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'cached_user_profile';

  Timer? _refreshTimer;

  void _startSessionRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 22), (_) {
      refreshSession();
    });
  }

  void _stopSessionRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  UserProfile? _user;
  SharedPreferences? _prefs;
  int _points = 0;
  int? _pendingLevelUpFrom;
  int? _pendingLevelUpTo;
  String? _token;

  UserProfile? get user => _user;
  bool get isLoggedIn => _user != null;
  String? get token => _token;

  int get points => _points;
  LevelProgress get progress => PlayerProgress.forPoints(_points);
  int get level => progress.level;
  int? get pendingLevelUpTo => _pendingLevelUpTo;
  bool get hasPendingLevelUp => _pendingLevelUpTo != null;

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    await ExtraLifeController.instance.load();

    _token = _prefs?.getString(_tokenKey);
    final cachedUserJson = _prefs?.getString(_userKey);
    if (cachedUserJson != null && cachedUserJson.isNotEmpty) {
      try {
        _user = UserProfile.fromMap(jsonDecode(cachedUserJson));
        _initializeUserSession();
      } catch (e) {
        // debugPrint('Failed to load cached user: $e');
      }
    }

    if (_token != null && _token!.isNotEmpty) {
      try {
        final userData = await ApiService.getMe(_token!);
        _user = UserProfile(
          id: userData['id'] ?? '',
          fullName:
              userData['fullName'] ??
              userData['name'] ??
              userData['username'] ??
              '',
          username: userData['username'] ?? '',
          phone: userData['phone'] ?? '',
          email: userData['email'] ?? '',
          status: userData['status'] ?? 'active',
          provider: userData['provider'] ?? 'phone',
          phoneCode: userData['phoneCode'],
          avatarPath: userData['avatarUrl'],
          lastUsernameChangedAt: _parseDateTime(userData['last_username_changed_at'] ?? userData['lastUsernameChangedAt']),
          lastNameChangedAt: _parseDateTime(userData['last_name_changed_at'] ?? userData['lastNameChangedAt']),
          skip: userData['skip'] ?? 0,
          totalPoints: userData['totalPoints'] ?? 0,
          winnings: userData['quizzesWon'] ?? 0,
          quizzesPlayed: userData['quizzesPlayed'] ?? 0,
          totalRewards: userData['totalRewards'] ?? 0,
          verifyPhone: userData['verifyPhone'] == true || userData['verifyPhone'] == 1 || userData['verify_phone'] == true || userData['verify_phone'] == 1,
        );
        _initializeUserSession();
        _startSessionRefreshTimer();
      } on UnauthorizedException {
        await signOut();
      } catch (e) {
        // debugPrint('Failed to refresh user profile on load: $e');
        if (_user != null) {
          _startSessionRefreshTimer();
        }
      }
    }
  }

  Future<bool> refreshSession() async {
    if (_token == null || _token!.isEmpty) return false;
    try {
      final userData = await ApiService.getMe(_token!);
      final pointsFromDb = userData['totalPoints'] as int? ?? 0;
      _user = _user?.copyWith(
        id: userData['id'] ?? '',
        fullName:
            userData['fullName'] ??
            userData['name'] ??
            userData['username'] ??
            '',
        username: userData['username'] ?? '',
        phone: userData['phone'] ?? '',
        email: userData['email'] ?? '',
        status: userData['status'] ?? 'active',
        provider: userData['provider'] ?? _user?.provider ?? 'phone',
        phoneCode: userData['phoneCode'] ?? _user?.phoneCode,
        avatarPath: userData['avatarUrl'],
        lastUsernameChangedAt: _parseDateTime(userData['last_username_changed_at'] ?? userData['lastUsernameChangedAt']),
        lastNameChangedAt: _parseDateTime(userData['last_name_changed_at'] ?? userData['lastNameChangedAt']),
        skip: userData['skip'] ?? 0,
        totalPoints: pointsFromDb,
        winnings: userData['quizzesWon'] ?? 0,
        quizzesPlayed: userData['quizzesPlayed'] ?? 0,
        totalRewards: userData['totalRewards'] ?? 0,
        verifyPhone: userData['verifyPhone'] == true || userData['verifyPhone'] == 1 || userData['verify_phone'] == true || userData['verify_phone'] == 1,
      );
      _points = pointsFromDb;
      if (_user != null) {
        await _prefs?.setInt(_storageKeyFor(_user!), _points);
        await _prefs?.setString(_userKey, jsonEncode(_user!.toMap()));
      }
      notifyListeners();
      return true;
    } on UnauthorizedException {
      await signOut();
      return false;
    } catch (e) {
      // debugPrint('Failed to refresh session: $e');
      return false;
    }
  }

  Future<bool> signInWithProvider(String token) async {
    final response = await ApiService.providerLogin(token);
    
    // Check if new user
    if (response['isNewUser'] == true) {
      // Return true to indicate we need to show complete profile screen
      return true; 
    }

    final userMap = response['user'];
    _token = response['tokens']['accessToken'];
    final userStatus = userMap['status'] ?? 'active';

    _user = UserProfile(
      id: userMap['id'] ?? '',
      fullName:
          userMap['fullName'] ?? userMap['name'] ?? userMap['username'] ?? '',
      username: userMap['username'] ?? '',
      phone: userMap['phone'] ?? '',
      email: userMap['email'] ?? '',
      status: userStatus,
      provider: userMap['provider'] ?? 'google',
      avatarPath: userMap['avatarUrl'],
      lastUsernameChangedAt: _parseDateTime(userMap['last_username_changed_at'] ?? userMap['lastUsernameChangedAt']),
      lastNameChangedAt: _parseDateTime(userMap['last_name_changed_at'] ?? userMap['lastNameChangedAt']),
      skip: userMap['skip'] ?? 0,
      totalPoints: userMap['totalPoints'] ?? 0,
      winnings: userMap['quizzesWon'] ?? 0,
      quizzesPlayed: userMap['quizzesPlayed'] ?? 0,
      totalRewards: userMap['totalRewards'] ?? 0,
      verifyPhone: userMap['verifyPhone'] == true || userMap['verifyPhone'] == 1 || userMap['verify_phone'] == true || userMap['verify_phone'] == 1,
    );

    if (userStatus == 'deleted') {
      return true;
    }

    if (_token != null) {
      await _prefs?.setString(_tokenKey, _token!);
    }
    if (_user != null) {
      await _prefs?.setString(_userKey, jsonEncode(_user!.toMap()));
    }

    _initializeUserSession();
    _startSessionRefreshTimer();
    return false; // successfully signed in
  }

  /// Login with phone/username + password (Neon, no Firebase).
  /// Returns false on success, throws on error.
  Future<void> signInWithPhone({
    required String identifier,
    required String password,
  }) async {
    final response = await ApiService.phoneLogin(
      identifier: identifier,
      password: password,
    );

    final userMap = response['user'];
    _token = response['tokens']['accessToken'];

    _user = UserProfile(
      id: userMap['id'] ?? '',
      fullName: userMap['name'] ?? userMap['fullName'] ?? userMap['username'] ?? '',
      username: userMap['username'] ?? '',
      phone: userMap['phone'] ?? '',
      email: userMap['email'] ?? '',
      status: userMap['status'] ?? 'active',
      provider: userMap['provider'] ?? 'phone',
      phoneCode: userMap['phoneCode'],
      avatarPath: userMap['avatarUrl'],
      lastUsernameChangedAt: _parseDateTime(userMap['lastUsernameChangedAt']),
      lastNameChangedAt: _parseDateTime(userMap['lastNameChangedAt']),
      skip: userMap['skip'] ?? 0,
      totalPoints: userMap['totalPoints'] ?? 0,
      winnings: userMap['quizzesWon'] ?? 0,
      quizzesPlayed: userMap['quizzesPlayed'] ?? 0,
      totalRewards: userMap['totalRewards'] ?? 0,
      verifyPhone: userMap['verifyPhone'] == true || userMap['verifyPhone'] == 1 || userMap['verify_phone'] == true || userMap['verify_phone'] == 1,
    );

    if (_token != null) await _prefs?.setString(_tokenKey, _token!);
    if (_user != null) await _prefs?.setString(_userKey, jsonEncode(_user!.toMap()));

    _initializeUserSession();
    _startSessionRefreshTimer();
  }

  Future<Map<String, dynamic>> registerPhoneUser({
    required String phone,
    required String password,
    required String code,
    String? phoneCode,
  }) async {
    final response = await ApiService.registerPhone(
      phone: phone,
      password: password,
      code: code,
      phoneCode: phoneCode,
    );
    _token = response['tokens']['accessToken'];
    await _prefs?.setString(_tokenKey, _token!);

    final userMap = response['user'];
    _user = UserProfile(
      id: userMap['id'] ?? '',
      fullName: userMap['name'] ?? userMap['fullName'] ?? userMap['username'] ?? '',
      username: userMap['username'] ?? '',
      phone: userMap['phone'] ?? '',
      email: userMap['email'] ?? '',
      status: userMap['status'] ?? 'active',
      provider: userMap['provider'] ?? 'phone',
      phoneCode: userMap['phoneCode'] ?? phoneCode,
      avatarPath: userMap['avatarUrl'],
      lastUsernameChangedAt: _parseDateTime(userMap['lastUsernameChangedAt']),
      lastNameChangedAt: _parseDateTime(userMap['lastNameChangedAt']),
      skip: userMap['skip'] ?? 0,
      totalPoints: userMap['totalPoints'] ?? 0,
      winnings: userMap['quizzesWon'] ?? 0,
      quizzesPlayed: userMap['quizzesPlayed'] ?? 0,
      totalRewards: userMap['totalRewards'] ?? 0,
      verifyPhone: userMap['verifyPhone'] == true || userMap['verifyPhone'] == 1 || userMap['verify_phone'] == true || userMap['verify_phone'] == 1,
    );
    await _prefs?.setString(_userKey, jsonEncode(_user!.toMap()));

    _initializeUserSession();
    _startSessionRefreshTimer();
    return response; // contains token, userId, phone
  }

  Future<void> updateProfile({
    String? fullName,
    String? username,
    String? email,
    String? phone,
    String? phoneCode,
    String? password,
    String? avatarPath,
    bool isInitialSetup = false,
  }) async {
    if (_user == null || _token == null) return;

    final data = <String, dynamic>{};
    if (fullName != null) data['fullName'] = fullName;
    if (username != null) data['username'] = username;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (phoneCode != null) data['phoneCode'] = phoneCode;
    if (password != null) data['password'] = password;
    if (isInitialSetup) data['isInitialSetup'] = true;

    Map<String, dynamic>? userData;
    if (data.isNotEmpty) {
      userData = await ApiService.updateUser(_user!.id, data, _token!);
    }

    String? finalAvatarUrl = _user!.avatarPath;
    if (avatarPath != null) {
      if (!avatarPath.startsWith('http')) {
        finalAvatarUrl = await ApiService.uploadAvatar(
          _user!.id,
          avatarPath,
          _token!,
        );
      } else {
        finalAvatarUrl = avatarPath;
      }
    }

    if (userData != null) {
      _user = _user?.copyWith(
        fullName: userData['fullName'] ?? userData['name'] ?? _user!.fullName,
        username: userData['username'] ?? _user!.username,
        email: userData['email'] ?? _user!.email,
        phone: userData['phone'] ?? _user!.phone,
        phoneCode: userData['phoneCode'] ?? _user!.phoneCode,
        lastUsernameChangedAt: _parseDateTime(userData['last_username_changed_at'] ?? userData['lastUsernameChangedAt']),
        lastNameChangedAt: _parseDateTime(userData['last_name_changed_at'] ?? userData['lastNameChangedAt']),
        avatarPath: finalAvatarUrl,
        verifyPhone: userData['verifyPhone'] == true || userData['verifyPhone'] == 1 || userData['verify_phone'] == true || userData['verify_phone'] == 1 || _user!.verifyPhone,
      );
    } else {
      _user = _user?.copyWith(
        avatarPath: finalAvatarUrl,
      );
    }

    _saveUser();
    notifyListeners();
  }

  Future<void> registerWithProvider({
    required String token,
    required String fullName,
    required String username,
    String? phone,
    String? phoneCode,
    String? avatarPath,
    String? provider,
  }) async {
    final response = await ApiService.registerProvider(
      token: token,
      fullName: fullName,
      username: username,
      phone: phone,
      phoneCode: phoneCode,
      avatarPath: avatarPath,
      provider: provider,
    );

    final userMap = response['user'];
    _token = response['tokens']['accessToken'];
    final userStatus = userMap['status'] ?? 'active';
    final userId = userMap['id'] ?? '';

    String? finalAvatarUrl = userMap['avatarUrl'];

    // Upload avatar if provided (Only for local files, backend handles HTTP URLs)
    if (avatarPath != null && _token != null) {
      if (!avatarPath.startsWith('http')) {
        // Local file — upload as multipart
        try {
          finalAvatarUrl = await ApiService.uploadAvatar(
            userId,
            avatarPath,
            _token!,
          );
        } catch (e) {
          // debugPrint('Failed to upload avatar during registration: $e');
        }
      }
    }

    _user = UserProfile(
      id: userId,
      fullName: userMap['fullName'] ?? userMap['name'] ?? userMap['username'] ?? '',
      username: userMap['username'] ?? '',
      phone: userMap['phone'] ?? '',
      email: userMap['email'] ?? '',
      status: userStatus,
      provider: userMap['provider'] ?? provider ?? 'google',
      phoneCode: userMap['phoneCode'],
      avatarPath: finalAvatarUrl,
      lastUsernameChangedAt: _parseDateTime(userMap['last_username_changed_at']),
      lastNameChangedAt: _parseDateTime(userMap['last_name_changed_at']),
      skip: userMap['skip'] ?? 0,
      totalPoints: userMap['totalPoints'] ?? 0,
      winnings: userMap['quizzesWon'] ?? 0,
      quizzesPlayed: userMap['quizzesPlayed'] ?? 0,
      totalRewards: userMap['totalRewards'] ?? 0,
      verifyPhone: userMap['verifyPhone'] == true || userMap['verifyPhone'] == 1 || userMap['verify_phone'] == true || userMap['verify_phone'] == 1,
    );

    if (_token != null) {
      await _prefs?.setString(_tokenKey, _token!);
    }
    if (_user != null) {
      await _prefs?.setString(_userKey, jsonEncode(_user!.toMap()));
    }

    _initializeUserSession();
    _startSessionRefreshTimer();
  }

  void _initializeUserSession() {
    _points = _user?.totalPoints ?? 0;
    if (_user != null) {
      _prefs?.setInt(_storageKeyFor(_user!), _points);
      _prefs?.setString(_userKey, jsonEncode(_user!.toMap()));
    }
    _pendingLevelUpFrom = null;
    _pendingLevelUpTo = null;
    notifyListeners();
    ExtraLifeController.instance.bindUser(_user?.email);
    PushNotificationService.instance.ensureInitialized();
  }

  void _saveUser() {
    if (_user != null) {
      _prefs?.setString(_userKey, jsonEncode(_user!.toMap()));
    }
  }

  Future<void> signOut() async {
    _stopSessionRefreshTimer();
    _user = null;
    _points = 0;
    _pendingLevelUpFrom = null;
    _pendingLevelUpTo = null;
    _token = null;
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_userKey);
    ExtraLifeController.instance.clear();
    await PushNotificationService.instance.onSignOut();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final current = _user;
    if (current == null || _token == null) return;
    await ApiService.updateUser(current.id, {'status': 'deleted'}, _token!);
    await signOut();
  }

  Future<void> activateAccount() async {
    if (_user == null || _token == null) return;
    await ApiService.updateUser(_user!.id, {'status': 'active'}, _token!);
    await _prefs?.setString(_tokenKey, _token!);
    _user = _user!.copyWith(status: 'active');
    _initializeUserSession();
    _startSessionRefreshTimer();
  }

  void cancelActivation() {
    _token = null;
    _user = null;
    notifyListeners();
  }

  /// دانانی وێنەی پرۆفایل — ڕێڕەوی ناوخۆیی پاشەکەوت دەکرێت.
  Future<void> setAvatarPath(String? path) async {
    final current = _user;
    if (current == null || _token == null) return;

    if (path == null || path.isEmpty) {
      // Clear avatar (if supported by backend later, could call an endpoint)
      _user = current.copyWith(clearAvatar: true);
    } else {
      try {
        // Upload avatar directly
        final remoteUrl = await ApiService.uploadAvatar(
          current.id,
          path,
          _token!,
        );
        _user = current.copyWith(avatarPath: remoteUrl);
      } catch (e) {
        // Fallback to local path if upload fails for optimistic UI
        _user = current.copyWith(avatarPath: path);
      }
    }
    _saveUser();
    notifyListeners();
  }

  void updateSkipLocal(int newSkip) {
    if (_user == null) return;
    _user = _user!.copyWith(skip: newSkip);
    _saveUser();
    notifyListeners();
  }

  Future<void> addPoints(int value) async {
    if (value <= 0 || _user == null) return;
    await load();
    final beforeLevel = PlayerProgress.forPoints(_points).level;
    _points += value;
    _user = _user!.copyWith(totalPoints: _points);
    final afterLevel = PlayerProgress.forPoints(_points).level;
    if (afterLevel > beforeLevel) {
      _pendingLevelUpFrom ??= beforeLevel;
      _pendingLevelUpTo = afterLevel;
    }
    await _prefs?.setInt(_storageKeyFor(_user!), _points);
    _saveUser();
    notifyListeners();
  }

  /// دوای نیشاندانی ئاماژەی بەرزبوونەوە — بۆ یەکجار.
  ({int from, int to})? consumePendingLevelUp() {
    final to = _pendingLevelUpTo;
    if (to == null) return null;
    final from = _pendingLevelUpFrom ?? (to - 1).clamp(0, to);
    _pendingLevelUpFrom = null;
    _pendingLevelUpTo = null;
    notifyListeners();
    return (from: from, to: to);
  }

  String _storageKeyFor(UserProfile profile) {
    return '$_xpKeyPrefix${profile.email.toLowerCase()}';
  }
}