import 'package:flutter/material.dart';

import '../animation/fade_slide_in.dart';
import '../localization/app_strings.dart';
import '../localization/locale_controller.dart';
import '../theme/app_colors.dart';

/// دوگمەی گۆڕینی شێوەزار — سۆرانی / بادینی.
class DialectToggleButton extends StatelessWidget {
  const DialectToggleButton({super.key, this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final controller = LocaleController.instance;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isSorani = controller.isSorani;
        final short = isSorani ? 'ک.س' : 'Bd';
        final switchTo = isSorani
            ? AppStrings.dialectBadini
            : AppStrings.dialectSorani;

        if (compact) {
          return PressableScale(
            onTap: controller.toggleDialect,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.stroke),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.14),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.translate_rounded,
                    size: 18,
                    color: AppColors.purpleLight,
                  ),
                  const SizedBox(width: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      short,
                      key: ValueKey(short),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colors.ink,
                            fontSize: 12,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return PressableScale(
          onTap: controller.toggleDialect,
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
                  child: const Icon(
                    Icons.translate_rounded,
                    size: 19,
                    color: AppColors.purpleLight,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.dialect,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                            ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          isSorani
                              ? AppStrings.dialectSorani
                              : AppStrings.dialectBadini,
                          key: ValueKey(isSorani),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontSize: 14,
                                height: 1.4,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  switchTo,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.purpleLight,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
