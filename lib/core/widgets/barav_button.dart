import 'package:flutter/material.dart';

import '../animation/fade_slide_in.dart';
import '../theme/app_colors.dart';

const Color _onPurple = Color(0xFFF5F5F7);

/// دوگمەی سەرەکی — مۆری قووڵی تەخت، ڕادیۆسی ١٥.
class BaravButton extends StatelessWidget {
  const BaravButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.height = 56,
    this.borderRadius,
    this.color,
    this.gradient,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final double height;

  /// ئەگەر null بێت، ١٥.
  final double? borderRadius;

  /// ڕەنگی تەخت — بنەڕەت AppColors.cta.
  final Color? color;

  /// ئەگەر دانرابێت، لە جیاتی ڕەنگی تەخت.
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final radius = borderRadius ?? 15;
    final useGradient = gradient != null;
    final fill = useGradient ? null : (color ?? AppColors.cta);
    final shadowColor = fill ?? AppColors.purple;

    return PressableScale(
      onTap: enabled ? onPressed : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.55,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: fill,
            gradient: gradient,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: enabled ? 0.28 : 0),
                blurRadius: 18,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: _onPurple,
                      ),
                    )
                  : Padding(
                      key: ValueKey(label),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 20, color: _onPurple),
                            const SizedBox(width: 10),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// دوگمەی لاوەکی — تەنها چوارچێوە، بێ پڕکردنەوە.
class BaravOutlineButton extends StatelessWidget {
  const BaravOutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? AppColors.of(context).ink;
    return PressableScale(
      onTap: onPressed,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: resolved.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: resolved.withValues(alpha: 0.28)),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19, color: resolved),
                const SizedBox(width: 9),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: resolved,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
