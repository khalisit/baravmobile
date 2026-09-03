import 'package:flutter/material.dart';

import '../localization/locale_controller.dart';
import '../theme/app_colors.dart';
import 'barav_logo.dart';

/// دایالۆگی یەکەم کردنەوە — هەڵبژاردنی سۆرانی یان بادینی.
Future<void> showDialectPickerDialog(BuildContext context) async {
  if (!context.mounted) return;

  final chosen = await showGeneralDialog<AppLocale>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierLabel: 'dialect',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const _DialectPickerDialog();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurveTween(curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: animation.drive(curved),
        child: ScaleTransition(
          scale: animation.drive(
            Tween<double>(begin: 0.96, end: 1).chain(curved),
          ),
          child: child,
        ),
      );
    },
  );

  if (chosen != null) {
    await LocaleController.instance.chooseDialect(chosen);
  }
}

class _DialectPickerDialog extends StatelessWidget {
  const _DialectPickerDialog();

  void _pick(BuildContext context, AppLocale locale) {
    Navigator.of(context, rootNavigator: true).pop(locale);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colors.stroke,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BaravLogo(size: 44),
                      const SizedBox(height: 16),
                      Text(
                        'هەڵبژاردنی شێوەزار',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'تکایە یەکێک هەڵبژێرە',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _DialectChoice(
                        label: 'سۆرانی',
                        subtitle: 'کوردی ناوەڕاست',
                        onTap: () => _pick(context, AppLocale.ckb),
                      ),
                      const SizedBox(height: 12),
                      _DialectChoice(
                        label: 'کرمانجی',
                        subtitle: 'Kurdî Kurmancî',
                        onTap: () => _pick(context, AppLocale.badini),
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

class _DialectChoice extends StatelessWidget {
  const _DialectChoice({
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colors.surfaceHigh,
            border: Border.all(
              color: colors.stroke,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.language_rounded,
                  size: 20,
                  color: AppColors.purpleLight,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colors.textFaint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
