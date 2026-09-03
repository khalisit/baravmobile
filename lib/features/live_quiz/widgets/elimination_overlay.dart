import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/barav_button.dart';

class EliminationOverlay extends StatelessWidget {
  const EliminationOverlay({
    super.key,
    required this.animation,
    required this.onContinue,
    required this.onLeave,
  });

  final Animation<double> animation;
  final VoidCallback onContinue;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    final scale = Tween<double>(
      begin: 0.88,
      end: 1,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack));

    return FadeTransition(
      opacity: fade,
      child: Material(
        color: Colors.black.withValues(alpha: 0.42),
        child: Center(
          child: ScaleTransition(
            scale: scale,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.danger.withValues(alpha: 0.12),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.heart_broken_rounded,
                          size: 22,
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppStrings.eliminatedTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.spectatorWatching,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      BaravButton(
                        label: AppStrings.continueWatching,
                        onPressed: onContinue,
                        height: 44,
                      ),
                      const SizedBox(height: 2),
                      TextButton(
                        onPressed: onLeave,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppStrings.backToHome,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
