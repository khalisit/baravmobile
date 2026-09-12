import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization/app_strings.dart';
import 'core/localization/kurdish_material_localizations.dart';
import 'core/localization/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/session/session_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/main_shell.dart';

class BaravApp extends StatelessWidget {
  const BaravApp({super.key, this.themeController, this.localeController});

  final ThemeController? themeController;
  final LocaleController? localeController;

  @override
  Widget build(BuildContext context) {
    final themes = themeController ?? ThemeController.instance;
    final locales = localeController ?? LocaleController.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([themes, locales]),
      builder: (context, _) {
        final appLocale = Locale(locales.locale.code);

        return MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themes.mode,
          // ckb = سۆرانی، badini = بادینی — نەک عەرەبی.
          locale: appLocale,
          supportedLocales: const [Locale('ckb'), Locale('badini')],
          localizationsDelegates: const [
            KurdishMaterialLocalizations.delegate,
            KurdishWidgetsLocalizations.delegate,
            KurdishCupertinoLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final data = MediaQuery.of(context);
            return LocaleScope(
              controller: locales,
              child: Directionality(
                textDirection: locales.textDirection,
                child: MediaQuery(
                  data: data.copyWith(
                    textScaler: data.textScaler.clamp(maxScaleFactor: 1.2),
                    disableAnimations:
                        false, // Ensure animations always play even if disabled in system settings
                  ),
                  child: AnimatedTheme(
                    data: Theme.of(context),
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
          home: SessionController.instance.isLoggedIn ? const MainShell() : const LoginScreen(),
        );
      },
    );
  }
}
