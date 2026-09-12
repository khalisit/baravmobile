import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/kurdish_format.dart';
import '../../../core/widgets/barav_button.dart';

/// دوگمەی Extra Life — ئایکۆنی پلەی ڤیدیۆ + درێژبوونەوەی ناوەناوە.
class ExtraLifeHeaderButton extends StatefulWidget {
  const ExtraLifeHeaderButton({super.key});

  @override
  State<ExtraLifeHeaderButton> createState() => _ExtraLifeHeaderButtonState();
}

class _ExtraLifeHeaderButtonState extends State<ExtraLifeHeaderButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expand = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  Timer? _cycle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCycle());
  }

  void _startCycle() {
    _cycle?.cancel();
    // یەکەم جار دوای کەمێک درێژ ببێتەوە.
    _cycle = Timer(const Duration(seconds: 2), _expandBriefly);
  }

  Future<void> _expandBriefly() async {
    if (!mounted) return;
    await _expand.forward();
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    await _expand.reverse();
    if (!mounted) return;
    // دوای چەند چرکە دووبارە.
    _cycle = Timer(const Duration(seconds: 7), _expandBriefly);
  }

  @override
  void dispose() {
    _cycle?.cancel();
    _expand.dispose();
    super.dispose();
  }

  Future<void> _openSheet() async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppStrings.extraLifeTitle,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const _ExtraLifeDialog();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
          child: child,
        );
      },
    );
  }

  double _labelWidth(BuildContext context, TextStyle? style) {
    final painter = TextPainter(
      text: TextSpan(text: AppStrings.extraLifeTitle, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return painter.width;
  }

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: AppColors.purpleLight,
      fontWeight: FontWeight.w700,
      fontSize: 10.5,
      height: 1,
    );
    final expandExtra = (_labelWidth(context, labelStyle) + 10).clamp(0.0, 96.0);

    return ListenableBuilder(
      listenable: Listenable.merge([SessionController.instance, AdService.instance]),
      builder: (context, _) {
        final lives = SessionController.instance.user?.skip ?? 0;
        
        return AnimatedBuilder(
          animation: _expand,
          builder: (context, _) {
            final t = Curves.easeInOutCubic.transform(_expand.value);
            final showLives = lives > 0;
            final livesExtra = showLives
                ? 18.0 *
                    Curves.easeOut.transform(
                      ((t - 0.65) / 0.35).clamp(0.0, 1.0),
                    )
                : 0.0;
            final width = 44.0 + (expandExtra * t) + livesExtra;

            return SizedBox(
              height: 44,
              width: width,
              child: Material(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => unawaited(_openSheet()),
                  borderRadius: BorderRadius.circular(14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Color.lerp(
                          colors.stroke,
                          AppColors.purple.withValues(alpha: 0.55),
                          t,
                        )!,
                      ),
                      boxShadow: t > 0.05
                          ? [
                              BoxShadow(
                                color: AppColors.purple.withValues(
                                  alpha: 0.14 * t,
                                ),
                                blurRadius: 14 * t,
                                spreadRadius: -4,
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        // ئایکۆن — جێگیر لە لای start (ڕاست لە RTL)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.play_circle_filled_rounded,
                              size: 22,
                              color: Color.lerp(
                                AppColors.purple.withValues(alpha: 0.75),
                                AppColors.purpleLight,
                                t,
                              ),
                            ),
                          ),
                        ),
                        // دەق — پانتایی سنووردار بە درێژی ئەنیمەیشن (بێ overflow)
                        if (t > 0.05)
                          PositionedDirectional(
                            start: 40,
                            end: showLives && t > 0.65 ? 22 : 8,
                            top: 0,
                            bottom: 0,
                            child: Opacity(
                              opacity: ((t - 0.08) / 0.92).clamp(0.0, 1.0),
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  AppStrings.extraLifeTitle,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.clip,
                                  style: labelStyle,
                                ),
                              ),
                            ),
                          ),
                        if (showLives && t > 0.65)
                          PositionedDirectional(
                            end: 6,
                            top: 0,
                            bottom: 0,
                            child: Opacity(
                              opacity: ((t - 0.65) / 0.35).clamp(0.0, 1.0),
                              child: Center(
                                child: Text(
                                  '×${KurdishFormat.digits(lives)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.purpleLight,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (showLives && t < 0.2)
                          PositionedDirectional(
                            top: 4,
                            end: 4,
                            child: Opacity(
                              opacity: (1 - t / 0.2).clamp(0.0, 1.0),
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 14,
                                  maxHeight: 14,
                                ),
                                height: 14,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.purple,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: colors.surface,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  KurdishFormat.digits(lives),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                    leadingDistribution:
                                        TextLeadingDistribution.even,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ExtraLifeDialog extends StatefulWidget {
  const _ExtraLifeDialog();

  @override
  State<_ExtraLifeDialog> createState() => _ExtraLifeDialogState();
}

class _ExtraLifeDialogState extends State<_ExtraLifeDialog> {
  String? _errorMessage;

  Future<void> _watchAd(BuildContext context) async {
    setState(() {
      _errorMessage = null;
    });

    // پیشاندانی لۆدینگ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    
    // کەمێک چاوەڕێ دەکەین بۆ جوانتر دەرکەوتن
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!context.mounted) return;
    Navigator.pop(context); // داخستنی لۆدینگ
    
    await AdService.instance.showRewardedAd(
      onEarned: () {
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.extraLifeEarned),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context); // Close the modal upon success
        }
      },
      onError: (message) {
        if (context.mounted) {
          setState(() {
            _errorMessage = message;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final maxWidth = MediaQuery.sizeOf(context).width.clamp(0.0, 420.0);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // باکگراوندی بلور + تاریک — فۆکس دەخاتە سەر دیالۆگ
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: ColoredBox(
                  color: colors.background.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () {}, // ڕێگری لە داخستنی دیالۆگ بە کرتە لەسەر ناوەڕۆک
              child: ListenableBuilder(
                listenable: Listenable.merge([SessionController.instance, AdService.instance]),
                builder: (context, _) {
                  final lives = SessionController.instance.user?.skip ?? 0;
                  final adProgress = AdService.instance.watchCount;
                  final progressRatio = AdService.instance.progressRatio;

                  return ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth - 48),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colors.stroke),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.32),
                            blurRadius: 32,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: AlignmentDirectional.topEnd,
                              child: IconButton(
                                onPressed: () => Navigator.pop(context),
                                visualDensity: VisualDensity.compact,
                                style: IconButton.styleFrom(
                                  foregroundColor: colors.textMuted,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.close_rounded, size: 20),
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.purple.withValues(
                                      alpha: 0.14,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.play_circle_filled_rounded,
                                    color: AppColors.purpleLight,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.extraLifeTitle,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        AppStrings.extraLifeHint,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: colors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '×${KurdishFormat.digits(lives)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppColors.purpleLight,
                                    fontWeight: FontWeight.w800,
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
                                  '${KurdishFormat.digits(adProgress)}/${KurdishFormat.digits(3)}',
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
                                value: progressRatio,
                                minHeight: 6,
                                backgroundColor: colors.stroke,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.purpleLight,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: BaravButton(
                                label: AppStrings.watchAdButton,
                                icon: Icons.play_circle_outline_rounded,
                                onPressed: () =>
                                    unawaited(_watchAd(context)),
                              ),
                            ),
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
                                child: Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
