import 'package:flutter/material.dart';

import '../support/support_screen.dart';
import '../support/legal_screen.dart';

import '../../core/animation/fade_slide_in.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/routing/transitions.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/kurdish_format.dart';
import '../../core/widgets/glow_backdrop.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../data/mock_data.dart';
import '../auth/login_screen.dart';
import 'claim_history_screen.dart';
import 'edit_profile_screen.dart';
import 'verify_phone_screen.dart';
import 'widgets/delete_account_sheet.dart';
import 'widgets/notification_settings_tile.dart';

import '../../data/api_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  int _unreadMessagesCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    final token = SessionController.instance.token;
    if (token == null) return;
    try {
      final messages = await ApiService.getSupportMessages(token);
      int unread = messages.where((m) => m.isFromAdmin && !m.isRead).length;
      if (mounted) {
        setState(() {
          _unreadMessagesCount = unread;
        });
      }
    } catch (_) {}
  }

  void _leaveToLogin(BuildContext context) {
    Navigator.of(
      context,
    ).pushAndRemoveUntil(fadeRoute(const LoginScreen()), (route) => false);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDeleteAccountSheet(context);
    if (confirmed && context.mounted) {
      try {
        await SessionController.instance.deleteAccount();
        if (context.mounted) _leaveToLogin(context);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LocaleController.instance.isSorani
                    ? 'سڕینەوەی هەژمار سەرکەوتوو نەبوو: $e'
                    : 'Hesab nehat jêbirin: $e',
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _refreshProfile(BuildContext context) async {
    _fetchUnreadCount();
    final success = await SessionController.instance.refreshSession();
    if (!success && context.mounted) {
      _leaveToLogin(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([
        SessionController.instance,
        LocaleController.instance,
        ThemeController.instance,
      ]),
      builder: (context, _) {
        final theme = Theme.of(context);
        final session = SessionController.instance;
        final user = session.user ?? MockData.user;
        final locale = LocaleController.instance;
        final themes = ThemeController.instance;
        final isSorani = locale.isSorani;
        final isDark = themes.isDark;

        return GlowBackdrop(
          intensity: 0.55,
          child: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () => _refreshProfile(context),
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                children: [
                  FadeSlideIn(
                    child: Text(
                      AppStrings.accountTitle,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),

                  const SizedBox(height: 12),

                  FadeSlideIn(
                    
                    child: _SettingsGroup(
                      children: [
                        _ProfileHeader(
                          initials: user.initials,
                          name: user.fullName,
                          username: user.username,
                          email: user.email,
                          avatarPath: user.avatarPath,
                          onEditTap: () {
                            Navigator.push(
                              context,
                              fadeRoute(const EditProfileScreen()),
                            );
                          },
                        ),
                        _InfoRow(
                          icon: Icons.badge_outlined,
                          label: AppStrings.fullName,
                          value: user.fullName,
                        ),
                        _InfoRow(
                          icon: Icons.phone_iphone_rounded,
                          label: AppStrings.phone,
                          value: KurdishFormat.phone(
                            '${user.phoneCode ?? ''}${user.phone}',
                          ),
                          // تەنها سۆرانی RTL — بادینی خۆی LTR ـە.
                          forceLtr: isSorani,
                          trailing: !user.verifyPhone && user.phone.isNotEmpty
                              ? TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      fadeRoute(const VerifyPhoneScreen()),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: AppColors.danger
                                        .withValues(alpha: 0.1),
                                    foregroundColor: AppColors.danger,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    isSorani ? 'سەلماندن' : 'Pejirandin',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : user.verifyPhone
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.verified_rounded,
                                        color: AppColors.success,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isSorani ? 'سەلمێندراوە' : 'Pejirandî',
                                        style: const TextStyle(
                                          color: AppColors.success,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),

                  FadeSlideIn(
                    
                    child: _StatsSection(
                      points: session.points,
                      winnings: session.user?.winnings ?? 0,
                      skip: session.user?.skip ?? 0,
                      quizzesPlayed: session.user?.quizzesPlayed ?? 0,
                      totalRewards: session.user?.totalRewards ?? 0,
                    ),
                  ),

                  const SizedBox(height: 22),
                  FadeSlideIn(
                    
                    child: _SettingsGroup(
                      children: [
                        _ActionRow(
                          icon: Icons.receipt_long_rounded,
                          title: AppStrings.claimHistory,
                          onTap: () {
                            Navigator.push(
                              context,
                              fadeRoute(const ClaimHistoryScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  FadeSlideIn(
                    
                    child: _SectionLabel(AppStrings.accountPreferences),
                  ),
                  const SizedBox(height: 8),
                  FadeSlideIn(
                    
                    child: _SettingsGroup(
                      children: [
                        _ActionRow(
                          icon: Icons.translate_rounded,
                          title: AppStrings.dialect,
                          subtitle: isSorani
                              ? AppStrings.dialectSorani
                              : AppStrings.dialectBadini,
                          trailing: Text(
                            isSorani
                                ? AppStrings.dialectBadini
                                : AppStrings.dialectSorani,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.purpleLight,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          onTap: locale.toggleDialect,
                        ),
                        if (PushNotificationService.instance.isSupported)
                          const NotificationSettingsTile(embedded: true),
                        _ActionRow(
                          icon: isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          title: AppStrings.appearance,
                          subtitle: isDark
                              ? AppStrings.lightMode
                              : AppStrings.darkMode,
                          trailing: Icon(
                            Icons.swap_horiz_rounded,
                            size: 20,
                            color: AppColors.of(context).textMuted,
                          ),
                          onTap: themes.toggle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  FadeSlideIn(
                    
                    child: _SectionLabel(isSorani ? 'پشتیوانی و ڕێنماییەکان' : 'Piştgirî û Rêwerz'),
                  ),
                  const SizedBox(height: 8),
                  FadeSlideIn(
                    
                    child: _SettingsGroup(
                      children: [
                        _ActionRow(
                          icon: Icons.help_outline_rounded,
                          title: isSorani ? 'یارمەتی و چاتی ڕاستەوخۆ' : 'Alîkarî û Danûstandina Zindî',
                          trailing: _unreadMessagesCount > 0
                              ? Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.danger,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                          onTap: () async {
                            await Navigator.push(context, fadeRoute(SupportScreen(hasUnreadMessages: _unreadMessagesCount > 0)));
                            _fetchUnreadCount();
                          },
                        ),
                        _ActionRow(
                          icon: Icons.shield_outlined,
                          title: isSorani ? 'یاسا و ڕێنماییەکان' : 'Qanûn û Rêwerz',
                          onTap: () {
                            Navigator.push(context, fadeRoute(const LegalScreen()));
                          },
                        ),

                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  FadeSlideIn(
                    
                    child: _SectionLabel(AppStrings.accountActions),
                  ),
                  const SizedBox(height: 8),
                  FadeSlideIn(
                    
                    child: _SettingsGroup(
                      children: [
                        _ActionRow(
                          icon: Icons.logout_rounded,
                          title: AppStrings.logout,
                          onTap: () async {
                            await SessionController.instance.signOut();
                            if (context.mounted) _leaveToLogin(context);
                          },
                        ),
                        _ActionRow(
                          icon: Icons.delete_outline_rounded,
                          title: AppStrings.deleteAccount,
                          danger: true,
                          onTap: () => _confirmDelete(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6, bottom: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.of(context).textMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 66,
                color: colors.stroke.withValues(alpha: 0.85),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, this.danger = false});

  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final tint = danger ? AppColors.danger : AppColors.purple;
    final iconColor = danger ? AppColors.danger : AppColors.purpleLight;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, size: 19, color: iconColor),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.forceLtr = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool forceLtr;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          _IconBox(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                if (forceLtr)
                  // سۆرانی RTL: ژمارە بە LTR دەخوێنرێتەوە (٠٧٥٠ …) بێ گۆڕینی شوێنی بادینی.
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      value,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final titleColor = danger ? AppColors.danger : colors.ink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              _IconBox(icon: icon, danger: danger),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                        height: 1.25,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.initials,
    required this.name,
    required this.username,
    required this.email,
    this.avatarPath,
    this.onEditTap,
  });

  final String initials;
  final String name;
  final String username;
  final String email;
  final String? avatarPath;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Row(
        children: [
          ProfileAvatar(
            initials: initials,
            imagePath: avatarPath,
            size: 68,
            fontSize: 21,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "@$username",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onEditTap != null)
                      GestureDetector(
                        onTap: onEditTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            AppStrings.editProfile,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.purpleLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // ئیمێڵی فەیک (بۆ بەکارهێنەرانی Phone) نیشان نادرێت
                if (!email.endsWith('@barav.app') &&
                    !email.startsWith('phone_'))
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.points,
    required this.winnings,
    required this.skip,
    required this.quizzesPlayed,
    required this.totalRewards,
  });

  final int points;
  final int winnings;
  final int skip;
  final int quizzesPlayed;
  final int totalRewards;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final isSorani = LocaleController.instance.isSorani;

    int getLevel(int points) {
      if (points <= 200) return 0;
      if (points <= 1000) return 1;
      if (points <= 2000) return 2;
      if (points <= 3300) return 3;
      if (points <= 5000) return 4;
      if (points <= 8500) return 5;
      if (points <= 12600) return 6;
      if (points <= 16000) return 7;
      if (points <= 21000) return 8;
      if (points <= 28000) return 9;
      if (points <= 40000) return 10;
      if (points <= 60000) return 11;
      if (points <= 80000) return 12;
      if (points <= 100000) return 13;
      if (points <= 130000) return 14;
      if (points <= 170000) return 15;
      if (points <= 220000) return 16;
      if (points <= 280000) return 17;
      if (points <= 350000) return 18;
      if (points <= 430000) return 19;
      if (points <= 520000) return 20;

      // Every additional 25,000 points = +1 level
      return 20 + ((points - 520000) ~/ 25000);
    }

    const levelThresholds = [
      200,
      1000,
      2000,
      3300,
      5000,
      8500,
      12600,
      16000,
      21000,
      28000,
      40000,
      60000,
      80000,
      100000,
      130000,
      170000,
      220000,
      280000,
      350000,
      430000,
      520000,
    ];

    int calculateLevel(int points) {
      for (var i = 0; i < levelThresholds.length; i++) {
        if (points <= levelThresholds[i]) {
          return i;
        }
      }

      return 20 + ((points - 520000) ~/ 25000);
    }

    double calculateProgress(int points) {
      final level = calculateLevel(points);

      final currentCap = level <= 20
          ? levelThresholds[level]
          : 520000 + ((level - 20) * 25000);

      final previousCap = level == 0
          ? 0
          : level <= 20
          ? levelThresholds[level - 1]
          : 520000 + ((level - 21) * 25000);

      return ((points - previousCap) / (currentCap - previousCap)).clamp(
        0.0,
        1.0,
      );
    }

    final level = calculateLevel(points);

    final nextLevelPoints = level <= 20
        ? levelThresholds[level]
        : 520000 + ((level - 20) * 25000);
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.stroke),
      ),
      child: Column(
        children: [
          // Level & Progress Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.purpleLight.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: AppColors.purpleLight,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          isSorani
                              ? 'لیڤڵی ( ${getLevel(points)} )'
                              : 'Asta ( ${getLevel(points)} )',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${KurdishFormat.number(points)} / ${KurdishFormat.number(nextLevelPoints)}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.purpleLight,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: calculateProgress(points),
                    minHeight: 12,
                    backgroundColor: colors.stroke,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.purpleLight,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: colors.stroke),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _StatItem(
                        icon: Icons.redeem_rounded,
                        color: Colors.purple,
                        value: '${KurdishFormat.number(totalRewards)} IQD',
                        label: isSorani ? 'کۆی خەڵاتەکان' : 'Xelat',
                      ),
                    ),
                    Container(width: 1, height: 40, color: colors.stroke),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.emoji_events_rounded,
                        color: Colors.orange,
                        value: KurdishFormat.number(winnings),
                        label: isSorani ? 'کۆی براوەبوون' : 'Serkeftin',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: 1, thickness: 1, color: colors.stroke),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _StatItem(
                        icon: Icons.sports_esports_rounded,
                        color: Colors.green,
                        value: KurdishFormat.number(quizzesPlayed),
                        label: isSorani ? 'یارییەکان' : 'Lîstok',
                      ),
                    ),
                    Container(width: 1, height: 40, color: colors.stroke),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.fast_forward_rounded,
                        color: Colors.blueAccent,
                        value: KurdishFormat.number(skip),
                        label: isSorani ? 'سکیپ' : 'Skip',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: colors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
