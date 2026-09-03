import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/animation/fade_slide_in.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/kurdish_format.dart';
import '../../core/widgets/circle_back_button.dart';
import '../../core/widgets/glow_backdrop.dart';
import '../../data/models.dart';
import '../../data/api_service.dart';
import '../../core/session/session_controller.dart';

/// شاشەی ئاگادارییەکان — ناوخۆیی و پڕۆمۆ / کویز.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static List<AppNotification>? _cachedNotifications;

  List<AppNotification> _items = _cachedNotifications ?? [];
  bool _isLoading = _cachedNotifications == null;
  Timer? _realtimeTimer;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _realtimeTimer = Timer.periodic(const Duration(seconds: 22), (_) {
      _silentFetchNotifications();
    });
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    final session = SessionController.instance;
    if (session.user == null || session.token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final notifs = await ApiService.getNotifications(
        session.user!.id,
        session.token,
      );
      _cachedNotifications = notifs;
      if (mounted) {
        setState(() {
          _items = notifs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _silentFetchNotifications() async {
    final session = SessionController.instance;
    if (session.user == null || session.token == null) return;
    try {
      final notifs = await ApiService.getNotifications(
        session.user!.id,
        session.token,
      );
      _cachedNotifications = notifs;
      if (mounted) {
        setState(() {
          _items = notifs;
        });
      }
    } catch (_) {}
  }

  int get _unreadCount => _items.where((n) => !n.read).length;

  Future<void> _markAllRead() async {
    final session = SessionController.instance;
    if (session.user == null || session.token == null) return;

    setState(() {
      _items = _items.map((n) => n.copyWith(read: true)).toList();
    });

    try {
      await ApiService.markAllNotificationsRead(
        session.token!,
        session.user!.id,
      );
    } catch (_) {}
  }

  Future<void> _openItem(int index) async {
    final item = _items[index];
    if (!item.read) {
      setState(() {
        _items[index] = item.copyWith(read: true);
      });

      final session = SessionController.instance;
      if (session.user != null && session.token != null) {
        try {
          await ApiService.markNotificationRead(
            item.id,
            session.user!.id,
            session.token!,
          );
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final unread = _unreadCount;

    return Scaffold(
      body: GlowBackdrop(
        intensity: 0.45,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    const CircleBackButton(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.notificationsTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (unread > 0)
                      TextButton(
                        onPressed: _markAllRead,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.cta,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppStrings.markAllRead,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.cta,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (unread > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Text(
                    '${KurdishFormat.digits(unread)} · ${AppStrings.notificationsTitle}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                    ? const _EmptyNotifications()
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 40 * index),
                            child: _NotificationTile(
                              notification: _items[index],
                              onTap: () => _openItem(index),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final meta = _metaFor(notification, context);
    final unread = !notification.read;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131124) : colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unread
              ? AppColors.purple.withValues(alpha: 0.5)
              : colors.stroke.withValues(alpha: 0.2),
        ),
        boxShadow: unread && isDark
            ? [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: meta.color.withValues(alpha: 0.02),
          highlightColor: meta.color.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              spacing: 4,
              children: [
                Row(
                  spacing: 2,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        spacing: 6,
                        children: [
                          if (unread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: meta.color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: meta.color.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: Text(
                              notification.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: unread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _relativeTime(notification.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: meta.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Icon(meta.icon, color: meta.color, size: 28),
                    ),
                    const SizedBox(width: 10),
                    // Texts
                    Expanded(
                      child: Text(
                        notification.body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.textMuted,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 2),
                    // Time and Bell image
                    Stack(
                      children: [
                        if (unread)
                          Positioned(
                            top: 1,
                            right: 0,
                            child: Opacity(
                              opacity: 0.6,
                              child: Container(
                                width: 39,
                                height: 39,
                                decoration: BoxDecoration(
                                  color: meta.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        Image.asset(
                          'assets/images/bell.png',
                          width: 60,
                          height: 60,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ({IconData icon, Color color}) _metaFor(
    AppNotification notif,
    BuildContext context,
  ) {
    Color color;
    IconData icon;
    switch (notif.type) {
      case NotificationType.quizScheduled:
      case NotificationType.quizStarting:
        color = AppColors.cta;
        icon = Icons.quiz_rounded;
        break;
      case NotificationType.promo:
        color = const Color(0xFF0D9488);
        icon = Icons.local_offer_rounded;
        break;
      case NotificationType.success:
        color = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case NotificationType.warning:
        color = Theme.of(context).brightness == Brightness.light
            ? const Color(0xFFD97706) // Darker amber/orange for light mode
            : AppColors.warning;
        icon = Icons.warning_rounded;
        break;
      case NotificationType.error:
        color = AppColors.danger;
        icon = Icons.error_rounded;
        break;
      case NotificationType.info:
      case NotificationType.general:
        color = AppColors.cta;
        icon = Icons.info_rounded;
        break;
    }

    return (icon: icon, color: color);
  }

  String _relativeTime(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return AppStrings.notificationJustNow;
    if (diff.inMinutes < 60) {
      return '${KurdishFormat.digits(diff.inMinutes)} ${AppStrings.notificationMinutesAgo}';
    }
    if (diff.inHours < 24) {
      return '${KurdishFormat.digits(diff.inHours)} ${AppStrings.notificationHoursAgo}';
    }
    return KurdishFormat.date(at);
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.stroke),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 32,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppStrings.notificationsEmpty,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.notificationsEmptyHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textMuted,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
