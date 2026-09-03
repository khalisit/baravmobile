import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/extra_life/extra_life_controller.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/kurdish_format.dart';
import '../../../core/widgets/barav_button.dart';
import 'rewarded_ad_flow.dart';

/// کارتی Extra Life لە سەرەکی — ٣ ڕیکلام = ١ ژیان.
class ExtraLifeCard extends StatelessWidget {
  const ExtraLifeCard({super.key});

  Future<void> _watchAd(BuildContext context) async {
    final earned = await showRewardedAdFlow(context);
    if (!earned || !context.mounted) return;

    final granted = await ExtraLifeController.instance.registerAdWatched();
    if (!context.mounted) return;

    final msg = granted
        ? AppStrings.extraLifeEarned
        : AppStrings.extraLifeAdProgress;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final extra = ExtraLifeController.instance;

    return ListenableBuilder(
      listenable: extra,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.stroke),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.purpleLight,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.extraLifeTitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.extraLifeHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '×${KurdishFormat.digits(extra.lives)}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.purpleLight,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    AppStrings.extraLifeAdsProgress,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${KurdishFormat.digits(extra.adProgress)}/${KurdishFormat.digits(ExtraLifeController.adsPerLife)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: extra.progressRatio,
                  minHeight: 6,
                  backgroundColor: colors.stroke,
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.purpleLight,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 34),
                child: BaravButton(
                  label: AppStrings.watchAdButton,
                  icon: Icons.play_circle_outline_rounded,
                  onPressed: () => unawaited(_watchAd(context)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
