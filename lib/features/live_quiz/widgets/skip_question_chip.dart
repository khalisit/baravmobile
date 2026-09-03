import 'package:flutter/material.dart';

import '../../../core/extra_life/extra_life_controller.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/kurdish_format.dart';

class SkipQuestionChip extends StatelessWidget {
  const SkipQuestionChip({super.key, required this.onTap, this.selected = false});

  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);
    final theme = Theme.of(context);
    final lives = ExtraLifeController.instance.lives;
    final accent = selected ? AppColors.purpleLight : AppColors.purple;
    final fillA = selected ? 0.42 : 0.22;
    final fillB = selected ? 0.28 : 0.10;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 10, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
              colors: [
                accent.withValues(alpha: fillA),
                AppColors.purple.withValues(alpha: fillB),
              ],
            ),
            border: Border.all(
              color: selected
                  ? AppColors.purpleLight
                  : AppColors.purpleLight.withValues(alpha: 0.42),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(
                  alpha: selected ? 0.28 : 0.12,
                ),
                blurRadius: selected ? 14 : 10,
                offset: const Offset(0, 4),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.purple.withValues(
                    alpha: selected ? 0.48 : 0.28,
                  ),
                ),
                child: Icon(
                  selected ? Icons.check_rounded : Icons.fast_forward_rounded,
                  size: 13,
                  color: AppColors.purpleLight,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                AppStrings.skipQuestion,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.purpleLight,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: AppColors.purple.withValues(
                    alpha: selected ? 0.42 : 0.28,
                  ),
                ),
                child: Text(
                  '×${KurdishFormat.digits(lives)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.purpleLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
