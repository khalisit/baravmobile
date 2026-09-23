import 'package:flutter/material.dart';

import '../../../core/session/session_controller.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/utils/kurdish_format.dart';

class SkipChanceChip extends StatelessWidget {
  const SkipChanceChip({
    super.key,
    required this.onTap,
    this.disabled = false,
    this.overrideSkipCount,
  });

  final VoidCallback onTap;
  final bool disabled;
  final int? overrideSkipCount;

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);
    final theme = Theme.of(context);
    final skipCount = overrideSkipCount ?? SessionController.instance.user?.skip ?? 0;
    final isActuallyDisabled = disabled || skipCount <= 0;

    final accent = isActuallyDisabled ? Colors.grey : Colors.amber;
    final fillA = isActuallyDisabled ? 0.22 : 0.42;
    final fillB = isActuallyDisabled ? 0.10 : 0.28;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActuallyDisabled ? null : onTap,
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
                (isActuallyDisabled ? Colors.grey : Colors.orange).withValues(alpha: fillB),
              ],
            ),
            border: Border.all(
              color: accent.withValues(alpha: isActuallyDisabled ? 0.42 : 1.0),
              width: isActuallyDisabled ? 1 : 1.6,
            ),
            boxShadow: [
              if (!isActuallyDisabled)
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.28),
                  blurRadius: 14,
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
                  color: (isActuallyDisabled ? Colors.grey : Colors.amber).withValues(
                    alpha: 0.28,
                  ),
                ),
                child: Icon(
                  Icons.skip_next_rounded,
                  size: 13,
                  color: accent,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Skip',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: accent,
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
                  color: (isActuallyDisabled ? Colors.grey : Colors.amber).withValues(
                    alpha: 0.28,
                  ),
                ),
                child: Text(
                  '×${KurdishFormat.digits(skipCount)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accent,
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
