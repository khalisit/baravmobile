import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/routing/transitions.dart';
import '../../core/services/device_integrity_service.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/barav_logo.dart';
import '../../core/widgets/glow_backdrop.dart';
import '../auth/login_screen.dart';
import '../security/compromised_device_screen.dart';
import '../shell/main_shell.dart';

/// سکرینی کردنەوە — لۆگۆکە بە نەرمی گەورە دەبێت و دەردەکەوێت.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  late final Animation<double> _logoScale = Tween<double>(begin: 0.72, end: 1)
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.65, curve: Curves.easeOutBack),
        ),
      );

  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.5, curve: Curves.easeOut),
  );

  late final Animation<double> _textFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.45, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    unawaited(_launch());
  }

  Future<void> _launch() async {
    // Wait for splash to appear, then show the native system permission dialog.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final compromised = await DeviceIntegrityService.instance.refresh();
    if (!mounted) return;
    if (compromised) {
      Navigator.of(context).pushReplacement(
        fadeRoute(const CompromisedDeviceScreen()),
      );
      return;
    }

    await PushNotificationService.instance.requestPermissionIfNeeded();

    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      if (SessionController.instance.isLoggedIn) {
        Navigator.of(context).pushReplacement(fadeRoute(const MainShell()));
      } else {
        Navigator.of(context).pushReplacement(fadeRoute(const LoginScreen()));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);
    final colors = AppColors.of(context);

    return Scaffold(
      body: GlowBackdrop(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: const BaravLogo(size: 128),
                ),
              ),
              const SizedBox(height: 26),
              FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    const BaravWordmark(fontSize: 28),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.appTagline,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
