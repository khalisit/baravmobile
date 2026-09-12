import 'package:barav_quiz/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app.dart';
import 'core/localization/locale_controller.dart';
import 'core/services/ad_service.dart';
import 'core/services/avatar_picker_service.dart';
import 'core/services/device_integrity_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/presence_service.dart';
import 'core/session/session_controller.dart';
import 'core/theme/theme_controller.dart';
import 'features/live_quiz/live_quiz_audio.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '747424875838-6mqn0tqkqihifr4u6u14l3rse2na1bfc.apps.googleusercontent.com',
    );
  } catch (e, st) {
    // debugPrint('GoogleSignIn init error: $e');
    debugPrintStack(stackTrace: st);
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    // debugPrint('Firebase init error: $e');
  }

  // Essential things needed before rendering the first frame
  try {
    await Future.wait([
      LocaleController.instance.load(),
      ThemeController.instance.load(),
      SessionController.instance.load(),
    ]);
  } catch (e) {
    // debugPrint('Controllers load error: $e');
  }

  // Non-essential services can initialize in the background
  // to avoid blocking the app from drawing its first frame.
  Future.microtask(() async {
    try {
      await DeviceIntegrityService.instance.init();
    } catch (e) {
      // debugPrint('DeviceIntegrityService init error: $e');
    }
    try {
      await PushNotificationService.instance.initialize();
      await PushNotificationService.instance.requestPermissionIfNeeded();
    } catch (e) {
      // debugPrint('PushNotificationService init error: $e');
    }
    try {
      await PresenceService.instance.initialize();
    } catch (e) {
      // debugPrint('PresenceService init error: $e');
    }
    try {
      await MobileAds.instance.initialize();
      await AdService.instance.load();
    } catch (e) {
      // debugPrint('MobileAds / AdService init error: $e');
    }
    try {
      await LiveQuizAudio.instance.warmUp();
    } catch (e) {
      // debugPrint('LiveQuizAudio warmUp error: $e');
    }
  });

  configureImagePicker();
  SystemChrome.setSystemUIOverlayStyle(
    ThemeController.instance.isDark
        ? AppThemeOverlay.dark
        : AppThemeOverlay.light,
  );
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const BaravApp());
}