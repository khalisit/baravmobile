import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../theme/app_colors.dart';
import '../utils/kurdish_format.dart';
import '../utils/player_progress.dart';

/// نیشاندەری لیڤڵ — سادە، ڕەسمی، بێ زیادە.
class PlayerLevelBadge extends StatelessWidget {
  const PlayerLevelBadge({
    super.key,
    required this.progress,
    this.barWidth = 72,
  });

  final LevelProgress progress;
  final double barWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: AppColors.purpleLight,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.15,
      height: 1,
      fontSize: 11.5,
    );

    Widget label({bool flexible = false}) {
      final text = Text(
        '${AppStrings.levelLabel} ${KurdishFormat.digits(progress.level)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: labelStyle,
      );
      return flexible ? Flexible(child: text) : text;
    }

    Widget bar(double width) {
      return SizedBox(
        width: width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress.progressToNext,
            minHeight: 2.5,
            backgroundColor: colors.stroke,
            valueColor: const AlwaysStoppedAnimation(AppColors.purpleLight),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;

        // لە Column/Rowی بێ سنوور — Flexible کڕاش دەکات.
        if (!maxW.isFinite) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              label(),
              const SizedBox(width: 8),
              bar(barWidth),
            ],
          );
        }

        final usable = (maxW - 8).clamp(0.0, maxW);
        final resolvedBar = barWidth.clamp(24.0, usable * 0.5).toDouble();

        return Row(
          children: [
            label(flexible: true),
            const SizedBox(width: 8),
            bar(resolvedBar),
          ],
        );
      },
    );
  }
}
