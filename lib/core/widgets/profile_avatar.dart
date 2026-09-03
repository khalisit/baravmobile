import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/api_service.dart';
import '../theme/app_colors.dart';

/// ئەڤاتاری بەکارهێنەر — وێنە یان پیتەکان.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.initials,
    this.imagePath,
    this.size = 44,
    this.fontSize,
    this.showRing = true,
    this.onTap,
    this.badge,
  });

  final String initials;
  final String? imagePath;
  final double size;
  final double? fontSize;
  final bool showRing;
  final VoidCallback? onTap;
  final Widget? badge;

  String? get _resolvedPath {
    final path = imagePath;
    if (path == null || path.trim().isEmpty) return null;
    final clean = path.trim();
    if (clean.startsWith('http') || clean.startsWith('assets/')) return clean;
    if (File(clean).existsSync()) return clean;

    // Relative media key from backend
    String key = clean;
    if (!key.startsWith('users/') && !key.startsWith('admin/')) {
      if (key.startsWith('avatars/')) {
        key = 'users/$key';
      } else {
        key = 'users/avatars/$key';
      }
    }
    final rootUrl = ApiService.baseUrl.replaceAll('/api', '');
    return '$rootUrl/media/$key';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final resolvedFont = fontSize ?? (size * 0.32).clamp(11.0, 22.0);
    final resolved = _resolvedPath;
    final isNetwork = resolved != null && resolved.startsWith('http');
    final isAsset = resolved != null && resolved.startsWith('assets/');
    final isFile = resolved != null && !isNetwork && !isAsset && File(resolved).existsSync();

    Widget avatar = Container(
      width: size,
      height: size,
      padding: showRing ? EdgeInsets.all(size * 0.045) : EdgeInsets.zero,
      decoration: showRing
          ? const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.purpleGradient,
            )
          : null,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: isNetwork
            ? Image.network(
                resolved,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, _, _) => _InitialsText(
                  initials: initials,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.purpleLight,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    fontSize: resolvedFont,
                  ),
                ),
              )
            : (isAsset
                ? Image.asset(
                    resolved,
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                    errorBuilder: (_, _, _) => _InitialsText(
                      initials: initials,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.purpleLight,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        fontSize: resolvedFont,
                      ),
                    ),
                  )
                : (isFile
                    ? Image.file(
                        File(resolved),
                        fit: BoxFit.cover,
                        width: size,
                        height: size,
                        errorBuilder: (_, _, _) => _InitialsText(
                          initials: initials,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.purpleLight,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                            fontSize: resolvedFont,
                          ),
                        ),
                      )
                    : _InitialsText(
                        initials: initials,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.purpleLight,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          fontSize: resolvedFont,
                        ),
                      ))),
      ),
    );

    if (badge != null || onTap != null) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (badge != null)
            PositionedDirectional(
              end: 0,
              bottom: 0,
              child: badge!,
            ),
        ],
      );
    }

    if (onTap == null) return avatar;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatar,
      ),
    );
  }
}

class _InitialsText extends StatelessWidget {
  const _InitialsText({required this.initials, required this.style});

  final String initials;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(initials, style: style);
  }
}

/// پیتی یەکەم لە ناو بۆ براوەکانی بێ وێنە.
String initialsFromName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first;
  return '${parts[0].characters.first}${parts[1].characters.first}';
}
