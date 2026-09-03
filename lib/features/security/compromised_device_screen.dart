import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_strings.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/barav_button.dart';
import '../../core/widgets/barav_logo.dart';
import '../../core/widgets/glow_backdrop.dart';

/// شاشەی قفڵ — ئامێری ڕووت / جەیلبرێک / ناڕاستەقینە.
class CompromisedDeviceScreen extends StatelessWidget {
  const CompromisedDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: GlowBackdrop(
          intensity: 0.55,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const BaravLogo(size: 88),
                  const SizedBox(height: 28),
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.danger.withValues(alpha: 0.14),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      size: 34,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    AppStrings.compromisedDeviceTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.compromisedDeviceBody,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(flex: 3),
                  BaravButton(
                    label: AppStrings.compromisedDeviceExit,
                    icon: Icons.exit_to_app_rounded,
                    color: AppColors.danger,
                    onPressed: () => SystemNavigator.pop(),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
