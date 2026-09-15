import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:barav_quiz/core/session/session_controller.dart';
import 'package:barav_quiz/data/api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// External (system tray) push notifications — Android + iOS.
///
/// FCM token wiring can be added later via [registerDeviceToken].
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const String channelId = 'barav_quiz_push_v4';
  static const String channelName = 'BARAV QUIZ';
  static const String _promptedKey = 'push_permission_prompted';
  static const String _enabledKey = 'user_notifications_enabled';

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _fcmInitialized = false;
  String? _deviceToken;
  bool _enabledSetting = true;
  String? _initialPayload;
  
  bool suppressSupportNotifications = false;

  final _onMessageReceivedController = StreamController<void>.broadcast();
  Stream<void> get onMessageReceived => _onMessageReceivedController.stream;

  final _onNotificationTappedController = StreamController<String?>.broadcast();
  Stream<String?> get onNotificationTapped =>
      _onNotificationTappedController.stream;

  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  String? get deviceToken => _deviceToken;
  bool get isEnabled => _enabledSetting;

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _enabledSetting = prefs.getBool(_enabledKey) ?? true;
    _deviceToken = prefs.getString('cached_device_fcm_token');

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final launchDetails = await _local.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      final payload = launchDetails.notificationResponse?.payload;
      final lastPayload = prefs.getString('last_local_payload');
      if (payload != null && payload == lastPayload) {
        // Ignore, already handled before hot restart
      } else {
        _initialPayload = payload;
        if (payload != null) {
          await prefs.setString('last_local_payload', payload);
        }
      }
    }

    if (Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              channelId,
              channelName,
              description: 'Quiz alerts and updates from BARAV QUIZ',
              importance: Importance.high,
              sound: RawResourceAndroidNotificationSound(
                'notification_message',
              ),
            ),
          );
    }

    await _initFirebaseMessaging();

    _initialized = true;
  }

  Future<void> ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    } else if (!_fcmInitialized) {
      await _initFirebaseMessaging();
    } else {
      await syncDeviceTokenWithBackend();
      if (_enabledSetting && SessionController.instance.isLoggedIn) {
        try {
          await FirebaseMessaging.instance.subscribeToTopic('all');
        } catch (_) {}
      }
    }
  }

  Future<void> onSignOut() async {
    if (!isSupported) return;
    try {
      final fcm = FirebaseMessaging.instance;
      await fcm.unsubscribeFromTopic('all');
      await fcm.setAutoInitEnabled(false);
      await fcm.deleteToken();
      _deviceToken = null;
      _fcmInitialized = false;
    } catch (e) {
      // debugPrint('Error on push notification signout: $e');
    }
  }

  Future<void> _initFirebaseMessaging() async {
    if (!isSupported || _fcmInitialized) return;
    _fcmInitialized = true;

    try {
      final fcm = FirebaseMessaging.instance;
      await fcm.setAutoInitEnabled(_enabledSetting);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (!_enabledSetting) return;
        _onMessageReceivedController.add(null);

        // Suppress support notifications if user is on the support chat screen
        if (suppressSupportNotifications && message.data['type'] == 'support_message') {
          return;
        }

        final notification = message.notification;
        if (notification != null) {
          showExternal(
            title: notification.title ?? '',
            body: notification.body ?? '',
            payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (!_enabledSetting) return;
        _onNotificationTappedController.add(
          message.data.isNotEmpty ? jsonEncode(message.data) : null,
        );
      });

      final initialMessage = await fcm.getInitialMessage();
      if (initialMessage != null && _enabledSetting) {
        final prefs = await SharedPreferences.getInstance();
        final messageId = initialMessage.messageId ?? '';
        final lastMessageId = prefs.getString('last_fcm_message_id');
        
        if (messageId.isNotEmpty && messageId == lastMessageId) {
          // Ignore, already handled before hot restart
        } else {
          _initialPayload = initialMessage.data.isNotEmpty
              ? jsonEncode(initialMessage.data)
              : null;
          if (messageId.isNotEmpty) {
            await prefs.setString('last_fcm_message_id', messageId);
          }
        }
      }

      fcm.onTokenRefresh.listen((token) {
        if (_enabledSetting) {
          registerDeviceToken(token);
        }
      });

      if (_enabledSetting) {
        if (Platform.isIOS) {
          try {
            await fcm.requestPermission(
              alert: true,
              badge: true,
              sound: true,
              provisional: false,
            );
            await fcm.setForegroundNotificationPresentationOptions(
              alert: true,
              badge: true,
              sound: true,
            );
            String? apnsToken = await fcm.getAPNSToken();
            int retries = 0;
            while (apnsToken == null && retries < 10) {
              await Future.delayed(const Duration(milliseconds: 500));
              apnsToken = await fcm.getAPNSToken();
              retries++;
            }
          } catch (_) {}
        }

        try {
          final token = await fcm.getToken();
          if (token != null) {
            await registerDeviceToken(token);
          }
        } catch (e) {
          Future.delayed(const Duration(seconds: 3), () async {
            try {
              final token = await fcm.getToken();
              if (token != null) {
                await registerDeviceToken(token);
              }
            } catch (_) {}
          });
        }

        try {
          if (SessionController.instance.isLoggedIn) {
            await fcm.subscribeToTopic('all');
          } else {
            await fcm.unsubscribeFromTopic('all');
          }
        } catch (_) {}
      }
    } catch (e) {
      // debugPrint('Error initializing Firebase Messaging: $e');
    }
  }

  Future<void> setEnabledSetting(bool enabled) async {
    _enabledSetting = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, enabled);

      final fcm = FirebaseMessaging.instance;
      if (enabled) {
        await fcm.setAutoInitEnabled(true);
        try {
          if (SessionController.instance.isLoggedIn) {
            await fcm.subscribeToTopic('all');
          } else {
            await fcm.unsubscribeFromTopic('all');
          }
        } catch (_) {}
        final token = await fcm.getToken();
        if (token != null) {
          await registerDeviceToken(token);
        }
      } else {
        try {
          await fcm.unsubscribeFromTopic('all');
        } catch (_) {}
        await fcm.setAutoInitEnabled(false);
        await fcm.deleteToken();
      }
    } catch (e) {
      // debugPrint('Error setting notification preference: $e');
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    _onNotificationTappedController.add(response.payload);
  }

  String? consumeInitialPayload() {
    final payload = _initialPayload;
    _initialPayload = null;
    return payload;
  }

  Future<bool> hasPermission() async {
    if (!isSupported) return false;

    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted || status.isLimited;
    }

    if (Platform.isIOS) {
      try {
        final settings = await FirebaseMessaging.instance.getNotificationSettings();
        return settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
      } catch (_) {
        return false;
      }
    }

    return false;
  }

  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    if (!_initialized) await initialize();

    if (Platform.isIOS) {
      try {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        final ios = _local
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
      } catch (_) {
        return false;
      }
    }

    final status = await Permission.notification.request();
    return status.isGranted || status.isLimited;
  }

  Future<bool> openSystemSettings() => openAppSettings();

  /// Shows the native Allow / Don't Allow dialog once per install (Android + iOS).
  Future<bool> requestPermissionIfNeeded() async {
    if (!isSupported) return false;
    if (!_initialized) await initialize();
    if (!_enabledSetting) return false;
    if (await hasPermission()) return true;
    if (await wasPrompted()) return false;

    final granted = await requestPermission();
    await markPrompted();
    return granted;
  }

  Future<bool> wasPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_promptedKey) ?? false;
  }

  Future<void> markPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_promptedKey, true);
  }

  /// Shows a notification in the system tray (also used when FCM arrives in foreground).
  Future<void> showExternal({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!isSupported) return;
    if (!_initialized) await initialize();
    if (!_enabledSetting) return;
    if (!await hasPermission()) return;

    if (payload != null) {
      try {
        jsonDecode(payload);
      } catch (_) {}
    }

    String displayTitle = title;
    if (displayTitle.isEmpty) {
      displayTitle = 'BARAV QUIZ';
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Quiz alerts and updates from BARAV QUIZ',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('app_logo'),
      styleInformation: BigTextStyleInformation(body),
      sound: const RawResourceAndroidNotificationSound('notification_message'),
      color: const Color(0xFF6D28D9),
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_message.mp3',
    );

    await _local.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: displayTitle,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  /// Called when Firebase Messaging (or another provider) supplies a token.
  Future<void> registerDeviceToken(String token) async {
    _deviceToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_device_fcm_token', token);
    await syncDeviceTokenWithBackend();
  }

  Future<void> syncDeviceTokenWithBackend() async {
    if (!isSupported || _deviceToken == null || !_enabledSetting) return;

    final userId = SessionController.instance.user?.id;
    if (userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      String? devId = prefs.getString('device_unique_id');
      if (devId == null) {
        devId = 'dev_${DateTime.now().millisecondsSinceEpoch}_550';
        await prefs.setString('device_unique_id', devId);
      }

      String? model;
      String? osVersion;
      String? appVersion;

      try {
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion = packageInfo.version;

        final deviceInfo = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          model = '${androidInfo.manufacturer} ${androidInfo.model}';
          osVersion = 'Android ${androidInfo.version.release}';
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          model = iosInfo.utsname.machine;
          osVersion = 'iOS ${iosInfo.systemVersion}';
        }
      } catch (e) {
        // debugPrint('Error getting device info: $e');
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/notifications/register-device'),
        headers: {
          'Content-Type': 'application/json',
          if (SessionController.instance.token != null)
            'Authorization': 'Bearer ${SessionController.instance.token}',
        },
        body: jsonEncode({
          'userId': userId,
          'deviceId': devId,
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'pushToken': _deviceToken,
          'model': model,
          'osVersion': osVersion,
          'appVersion': appVersion,
        }),
      );
      if (response.statusCode != 200) {
        // debugPrint(
        //  'Failed to sync device token: ${response.statusCode} ${response.body}',
        // );
      } else {
        // debugPrint('Successfully synced device token with backend');
      }
    } catch (e) {
      // debugPrint('Error syncing device token with backend: $e');
    }
  }
}