import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/theme/app_colors.dart';

/// Toggle / enable external push notifications from account settings.
class NotificationSettingsTile extends StatefulWidget {
  const NotificationSettingsTile({super.key, this.embedded = false});

  /// کاتێک لەناو گرووپی ڕێکخستن دایە — بێ چوارچێوەی دەرەوە.
  final bool embedded;

  @override
  State<NotificationSettingsTile> createState() =>
      _NotificationSettingsTileState();
}

class _NotificationSettingsTileState extends State<NotificationSettingsTile> {
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final push = PushNotificationService.instance;
    if (!push.isSupported) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final systemGranted = await push.hasPermission();
      if (mounted) {
        setState(() {
          _enabled = push.isEnabled && systemGranted;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _enabled = false;
          _loading = false;
        });
      }
    }
  }

  Future<void> _onChanged(bool value) async {
    if (_loading) return;
    final push = PushNotificationService.instance;
    if (!push.isSupported) return;

    setState(() => _loading = true);

    if (value) {
      final systemGranted = await push.hasPermission();
      if (!systemGranted) {
        final granted = await push.requestPermission();
        if (!mounted) return;

        if (!granted) {
          if (Platform.isAndroid) {
            final status = await Permission.notification.status;
            if (!mounted) return;
            if (status.isPermanentlyDenied) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppStrings.pushPermissionOpenSettings)),
              );
              await push.openSystemSettings();
            } else {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppStrings.pushPermissionDenied)),
              );
            }
          } else {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppStrings.pushPermissionOpenSettings)),
            );
            await push.openSystemSettings();
          }
          await push.setEnabledSetting(false);
        } else {
          await push.setEnabledSetting(true);
        }
      } else {
        await push.setEnabledSetting(true);
      }
    } else {
      await push.setEnabledSetting(false);
    }

    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);
    final push = PushNotificationService.instance;
    if (!push.isSupported) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 19,
              color: AppColors.purpleLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.pushNotificationsLabel,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _enabled
                      ? AppStrings.pushNotificationsEnabled
                      : AppStrings.pushNotificationsDisabled,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.textMuted,
              ),
            )
          else
            Switch.adaptive(
              value: _enabled,
              onChanged: _onChanged,
              activeTrackColor: AppColors.cta.withValues(alpha: 0.55),
              activeThumbColor: AppColors.cta,
            ),
        ],
      ),
    );

    if (widget.embedded) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading
              ? null
              : () => _onChanged(!_enabled),
          child: row,
        ),
      );
    }

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: _loading ? null : () => _onChanged(!_enabled),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.stroke),
          ),
          child: row,
        ),
      ),
    );
  }
}
