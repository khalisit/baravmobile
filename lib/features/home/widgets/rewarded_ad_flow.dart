import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/barav_button.dart';

/// سیمولەیشنی ڕیکلامی Google Rewarded — دواتر بە AdMob دەگۆڕدرێت.
Future<bool> showRewardedAdFlow(BuildContext context) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierLabel: 'rewarded-ad',
    barrierColor: Colors.black.withValues(alpha: 0.82),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const _RewardedAdSimulation();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
  return result ?? false;
}

class _RewardedAdSimulation extends StatefulWidget {
  const _RewardedAdSimulation();

  @override
  State<_RewardedAdSimulation> createState() => _RewardedAdSimulationState();
}

class _RewardedAdSimulationState extends State<_RewardedAdSimulation>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(seconds: 5);

  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: _duration,
  );

  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _progress.forward().whenComplete(() {
      if (mounted) setState(() => _finished = true);
    });
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.stroke),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.smart_display_rounded,
                        size: 42,
                        color: AppColors.purpleLight,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        AppStrings.watchAdTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _finished
                            ? AppStrings.watchAdDone
                            : AppStrings.watchAdHint,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _progress,
                        builder: (context, _) {
                          return Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: _progress.value,
                                  minHeight: 6,
                                  backgroundColor: colors.stroke,
                                  valueColor: const AlwaysStoppedAnimation(
                                    AppColors.purpleLight,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _finished
                                    ? '100%'
                                    : '${(_progress.value * 100).round()}%',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      if (_finished)
                        BaravButton(
                          label: AppStrings.watchAdClaim,
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true)
                                .pop(true);
                          },
                        )
                      else
                        TextButton(
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true)
                                .pop(false);
                          },
                          child: Text(
                            AppStrings.cancel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colors.textMuted,
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
