import 'package:flutter/material.dart';

import '../animation/fade_slide_in.dart';
import '../theme/app_colors.dart';

enum SocialProvider { google, apple, phone }

/// دوگمەی چوونەژوورەوە بە هەژماری دەرەکی.
class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    super.key,
    required this.provider,
    required this.label,
    this.onPressed,
    this.height = 54,
    this.borderRadius = 18,
  });

  final SocialProvider provider;
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return PressableScale(
      onTap: onPressed,
      scale: 0.97,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: colors.stroke),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 22, height: 22, child: _ProviderGlyph(provider)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 13.5,
                  color: colors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderGlyph extends StatelessWidget {
  const _ProviderGlyph(this.provider);

  final SocialProvider provider;

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.of(context).ink;
    switch (provider) {
      case SocialProvider.apple:
        return Icon(Icons.apple, size: 22, color: ink);

      case SocialProvider.google:
        return Image.asset(
          'assets/images/google.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        );
      case SocialProvider.phone:
        return Icon(Icons.phone_rounded, size: 22, color: ink);
    }
  }
}
