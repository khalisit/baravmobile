import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';

class SpectatorStatusBar extends StatelessWidget {
  const SpectatorStatusBar({super.key, required this.onLeave});

  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onLeave,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsetsDirectional.only(
            start: 8,
            end: 6,
            top: 4,
            bottom: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.visibility_outlined,
                size: 13,
                color: AppColors.danger,
              ),
              const SizedBox(width: 5),
              Text(
                AppStrings.eliminatedTitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.close_rounded,
                size: 14,
                color: AppColors.danger.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
