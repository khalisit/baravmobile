import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// لۆگۆی ئەپەکە لەناو چوارگۆشەیەکی خڕکراو لەگەڵ ڕووناکی نەوشەیی.
class BaravLogo extends StatelessWidget {
  const BaravLogo({super.key, this.size = 96, this.glow = true});

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final glowAlpha = Theme.of(context).brightness == Brightness.dark
        ? 0.42
        : 0.22;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.35)),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: glowAlpha),
                  blurRadius: size * 0.5,
                  spreadRadius: -size * 0.08,
                  offset: Offset(0, size * 0.1),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

/// ناوی ئەپەکە بە دوو ڕەنگ — «BARAV» سپی/ڕەش و «QUIZ» نەوشەیی.
class BaravWordmark extends StatelessWidget {
  const BaravWordmark({super.key, this.fontSize = 26});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'BARAV ', style: TextStyle(color: colors.ink)),
          const TextSpan(
            text: 'QUIZ',
            style: TextStyle(color: AppColors.purpleLight),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        height: 1.2,
      ),
    );
  }
}
