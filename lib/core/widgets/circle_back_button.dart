import 'package:flutter/material.dart';

import '../animation/fade_slide_in.dart';
import '../theme/app_colors.dart';

/// دوگمەی گەڕانەوە بە شێوەی بازنە — ئاراستەکەی خۆکارانە لەگەڵ RTL دەگونجێت.
class CircleBackButton extends StatelessWidget {
  const CircleBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return PressableScale(
      onTap: onPressed ?? () => Navigator.of(context).maybePop(),
      scale: 0.9,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: colors.stroke),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          size: 20,
          color: colors.ink,
        ),
      ),
    );
  }
}
