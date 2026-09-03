import 'package:flutter/material.dart';

import '../animation/fade_slide_in.dart';
import '../localization/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';

/// دوگمەی گۆڕینی دارک / لایت مۆد.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, this.compact = true});

  /// ئەگەر `false` بێت، دەقیش لەگەڵ ئایکۆن پیشان دەدات (بۆ پرۆفایل).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final controller = ThemeController.instance;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isDark = controller.isDark;
        final icon = isDark
            ? Icons.light_mode_rounded
            : Icons.dark_mode_rounded;
        final label = isDark ? AppStrings.lightMode : AppStrings.darkMode;

        if (compact) {
          return PressableScale(
            onTap: controller.toggle,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.stroke),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(
                      alpha: isDark ? 0.18 : 0.12,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, animation) => RotationTransition(
                  turns: Tween(begin: 0.75, end: 1.0).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  icon,
                  key: ValueKey(isDark),
                  size: 20,
                  color: AppColors.purpleLight,
                ),
              ),
            ),
          );
        }

        return PressableScale(
          onTap: controller.toggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.stroke),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: Icon(
                      icon,
                      key: ValueKey(isDark),
                      size: 19,
                      color: AppColors.purpleLight,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.appearance,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                            ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          label,
                          key: ValueKey(label),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontSize: 14,
                                height: 1.4,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 20,
                  color: colors.textMuted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
