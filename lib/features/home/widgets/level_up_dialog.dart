import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/kurdish_format.dart';
import '../../../core/widgets/barav_button.dart';

/// ئاماژەی بەرزبوونەوەی لیڤڵ — ئەنیمەیشنی گۆڕینی ژمارە.
Future<void> showLevelUpDialog(
  BuildContext context, {
  required int fromLevel,
  required int toLevel,
}) {
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierLabel: 'level-up',
    barrierColor: Colors.black.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _LevelUpCeremony(
        fromLevel: fromLevel,
        toLevel: toLevel,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class _LevelUpCeremony extends StatefulWidget {
  const _LevelUpCeremony({
    required this.fromLevel,
    required this.toLevel,
  });

  final int fromLevel;
  final int toLevel;

  @override
  State<_LevelUpCeremony> createState() => _LevelUpCeremonyState();
}

class _LevelUpCeremonyState extends State<_LevelUpCeremony>
    with TickerProviderStateMixin {
  late final AnimationController _master = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// ٠ → کۆن، ١ → گۆڕان، ٢+ → نوێ + دەق.
  late final Animation<double> _oldFade = Tween<double>(begin: 1, end: 0)
      .animate(
    CurvedAnimation(
      parent: _master,
      curve: const Interval(0.28, 0.42, curve: Curves.easeIn),
    ),
  );

  late final Animation<double> _oldScale = Tween<double>(begin: 1, end: 0.72)
      .animate(
    CurvedAnimation(
      parent: _master,
      curve: const Interval(0.28, 0.42, curve: Curves.easeIn),
    ),
  );

  late final Animation<double> _newFade = Tween<double>(begin: 0, end: 1)
      .animate(
    CurvedAnimation(
      parent: _master,
      curve: const Interval(0.38, 0.55, curve: Curves.easeOut),
    ),
  );

  late final Animation<double> _newScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(begin: 0.55, end: 1.12)
          .chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 55,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.12, end: 1)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 45,
    ),
  ]).animate(
    CurvedAnimation(
      parent: _master,
      curve: const Interval(0.38, 0.72),
    ),
  );

  late final Animation<double> _ring = Tween<double>(begin: 0.4, end: 1)
      .animate(
    CurvedAnimation(
      parent: _master,
      curve: const Interval(0.4, 0.75, curve: Curves.easeOutCubic),
    ),
  );

  late final Animation<double> _copyFade = CurvedAnimation(
    parent: _master,
    curve: const Interval(0.62, 0.82, curve: Curves.easeOut),
  );

  late final Animation<Offset> _copySlide = Tween<Offset>(
    begin: const Offset(0, 0.18),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _master,
      curve: const Interval(0.62, 0.86, curve: Curves.easeOutCubic),
    ),
  );

  late final Animation<double> _buttonFade = CurvedAnimation(
    parent: _master,
    curve: const Interval(0.78, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _master.forward();
    _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _master.dispose();
    _pulse.dispose();
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([_master, _pulse]),
                    builder: (context, _) {
                      final glow = 0.22 + (_pulse.value * 0.16);
                      return SizedBox(
                        width: 180,
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: _ring.value,
                              child: Container(
                                width: 168,
                                height: 168,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.purpleLight
                                        .withValues(alpha: 0.28 * _newFade.value),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.purple
                                          .withValues(alpha: glow * _newFade.value),
                                      blurRadius: 42,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.purpleGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.purple
                                        .withValues(alpha: 0.35),
                                    blurRadius: 28,
                                    offset: const Offset(0, 12),
                                    spreadRadius: -8,
                                  ),
                                ],
                              ),
                            ),
                            // لیڤڵی کۆن
                            Opacity(
                              opacity: _oldFade.value,
                              child: Transform.scale(
                                scale: _oldScale.value,
                                child: Text(
                                  KurdishFormat.digits(widget.fromLevel),
                                  style: theme.textTheme.displayMedium
                                      ?.copyWith(
                                    color: Colors.white
                                        .withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                            // لیڤڵی نوێ
                            Opacity(
                              opacity: _newFade.value,
                              child: Transform.scale(
                                scale: _newScale.value,
                                child: Text(
                                  KurdishFormat.digits(widget.toLevel),
                                  style: theme.textTheme.displayMedium
                                      ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _copyFade,
                    child: SlideTransition(
                      position: _copySlide,
                      child: Column(
                        children: [
                          Text(
                            AppStrings.levelUpTitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.purpleLight,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${AppStrings.levelLabel} ${KurdishFormat.digits(widget.fromLevel)}  →  ${AppStrings.levelLabel} ${KurdishFormat.digits(widget.toLevel)}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.levelUpBody,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.textMuted,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  FadeTransition(
                    opacity: _buttonFade,
                    child: SizedBox(
                      width: double.infinity,
                      child: BaravButton(
                        label: AppStrings.levelUpContinue,
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
