import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// ڕووناکی نەرمی نەوشەیی لە پشتەوە — ژینگەی ئەپەکە قووڵتر و گەرمتر دەکات.
/// لە جیاتی blur، gradientی خڕ بەکاردەهێنێت تا خێرا بێت لەسەر مۆبایلی لاواز.
class GlowBackdrop extends StatelessWidget {
  const GlowBackdrop({super.key, required this.child, this.intensity = 1});

  final Widget child;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final colors = AppColors.of(context);
    final strength = intensity * colors.glowStrength;

    return ColoredBox(
      color: colors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -size.width * 0.45,
            right: -size.width * 0.32,
            child: _Glow(
              diameter: size.width * 1.15,
              color: AppColors.purple.withValues(alpha: 0.30 * strength),
            ),
          ),
          Positioned(
            bottom: -size.width * 0.5,
            left: -size.width * 0.38,
            child: _Glow(
              diameter: size.width * 1.05,
              color: AppColors.purpleDark.withValues(alpha: 0.26 * strength),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0), Colors.transparent],
            stops: const [0.0, 0.62, 1.0],
          ),
        ),
      ),
    );
  }
}
