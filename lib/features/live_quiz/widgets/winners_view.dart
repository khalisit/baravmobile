import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/kurdish_format.dart';
import '../../../core/widgets/barav_button.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/session/session_controller.dart';
import '../../../data/live_quiz_models.dart';
import '../live_quiz_controller.dart';

// ─────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────
String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
  }
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

String _resolveAvatarUrl(String? key) {
  if (key == null || key.isEmpty) return '';
  if (key.startsWith('http')) return key;
  const cdn = 'https://barav-backend.arkanstudiokrd.workers.dev/media/';
  String k = key;
  if (!k.startsWith('users/') && !k.startsWith('admin/')) {
    k = k.startsWith('avatars/') ? 'users/$k' : 'users/avatars/$k';
  }
  return '$cdn$k';
}

// ─────────────────────────────────────────────
// MAIN WIDGET
// ─────────────────────────────────────────────
class WinnersView extends StatelessWidget {
  const WinnersView({super.key});

  void _leave(BuildContext context) {
    LiveQuizController.instance.leaveSession();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final c = LiveQuizController.instance;
    final me = SessionController.instance.user;
    final all = c.winners; // full leaderboard (winners + others)
    final actualWinners = all.where((w) => w.isWinner).toList();

    // Sort to be extra sure
    final sorted = List<QuizWinner>.from(actualWinners)
      ..sort((a, b) => a.rank.compareTo(b.rank));

    // Podium top 3
    QuizWinner? first;
    QuizWinner? second;
    QuizWinner? third;
    for (final w in sorted) {
      if (w.rank == 1) first = w;
      if (w.rank == 2) second = w;
      if (w.rank == 3) third = w;
    }

    // Rest of players (rank 4+)
    final others = sorted.where((w) => w.rank > 3).toList();

    return Column(
      children: [
        // ── Header ──
        _buildHeader(theme, colors, c.isWinner, actualWinners.isEmpty),

        // ── Body ──
        Expanded(
          child: c.isLoadingResults && actualWinners.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : actualWinners.isEmpty
              ? _buildNoWinners(theme, colors)
              : CustomScrollView(
                  slivers: [
                    // Podium layout (top 3)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _buildPodium(
                          context,
                          first,
                          second,
                          third,
                          colors,
                          theme,
                        ),
                      ),
                    ),

                    if (others.isNotEmpty) ...[
                      // Elegant separator divider
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: colors.stroke,
                                  thickness: 0.8,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  '· · ·',
                                  style: TextStyle(
                                    color: colors.textFaint,
                                    fontSize: 11,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: colors.stroke,
                                  thickness: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Rest of leaderboard
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _LeaderboardRow(
                            winner: others[i],
                            index: i,
                            isYou: _isMe(others[i], me),
                            colors: colors,
                            theme: theme,
                          ),
                          childCount: others.length,
                        ),
                      ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],
                ),
        ),

        // ── Footer button ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: BaravButton(
            label: AppStrings.backToHome,
            onPressed: () => _leave(context),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    AppColors colors,
    bool isWinner,
    bool isEmpty,
  ) {
    // full leaderboard (winners + others)
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          Text(
            AppStrings.winnersTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          if (!isEmpty) ...[
            const SizedBox(height: 8),
            () {
              final isDark = ThemeController.instance.isDark;
              final goldColor = isDark
                  ? const Color(0xFFFFD700)
                  : const Color(0xFFB58000);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isWinner
                      ? goldColor.withValues(alpha: 0.12)
                      : colors.surfaceHigh,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isWinner
                        ? goldColor.withValues(alpha: 0.35)
                        : colors.stroke,
                    width: 1,
                  ),
                ),
                child: Text(
                  isWinner
                      ? 'پیرۆزە! تۆ یەکێکیت لە براوە بەختەوەرەکان 🏆'
                      : 'پیرۆزبایی لە سەرجەم براوەکانی ئەمڕۆ دەکەین 👏',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isWinner ? goldColor : colors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }(),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildNoWinners(ThemeData theme, AppColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sentiment_dissatisfied_rounded,
              size: 48,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'کەس نەبووە براوە لەم کویزەدا! 😔',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'هیچ یاریزانێک نەگەیشتە وەڵامی کۆتایی.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(
    BuildContext context,
    QuizWinner? first,
    QuizWinner? second,
    QuizWinner? third,
    AppColors colors,
    ThemeData theme,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final totalWidth = screenWidth - 28; // Padding is 14 on left/right
    final colWidth = totalWidth / 3.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6),
      width: totalWidth,
      height: 230, // Fits avatar top overlap + pedestal base
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Rank 2 (Left) - drawn first
          Positioned(
            left: 0,
            bottom: 0,
            width: colWidth + 2, // Slight overlap to touch seamlessly
            child: _buildPedestal(
              winner: second,
              rank: 2,
              colors: colors,
              theme: theme,
              height: 125,
            ),
          ),
          // 2. Rank 3 (Right) - drawn second
          Positioned(
            right: 0,
            bottom: 0,
            width: colWidth + 2, // Slight overlap to touch seamlessly
            child: _buildPedestal(
              winner: third,
              rank: 3,
              colors: colors,
              theme: theme,
              height: 125,
            ),
          ),
          // 3. Rank 1 (Middle) - drawn last, overlaps left & right, has shadow
          Positioned(
            left: colWidth - 2,
            right: colWidth - 2,
            bottom: 0,
            child: _buildPedestal(
              winner: first,
              rank: 1,
              colors: colors,
              theme: theme,
              height: 160,
              hasShadow: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPedestal({
    required QuizWinner? winner,
    required int rank,
    required AppColors colors,
    required ThemeData theme,
    required double height,
    bool hasShadow = false,
  }) {
    final isFirst = rank == 1;
    final isSecond = rank == 2;
    final avatarSize = isFirst ? 76.0 : 60.0;

    final isDark = ThemeController.instance.isDark;
    Color accentColor;
    Color scoreColor;
    if (isFirst) {
      accentColor = const Color(0xFFFFD700); // Gold
      scoreColor = isDark
          ? const Color(0xFFFFD700)
          : const Color(
              0xFFB58000,
            ); // Bright gold in dark mode, deep gold in light mode
    } else if (isSecond) {
      accentColor = isDark
          ? const Color(0xFFCBD5E1)
          : const Color(0xFF64748B); // Silver border
      scoreColor = isDark
          ? const Color(0xFFE2E8F0)
          : const Color(0xFF475569); // Text color
    } else {
      accentColor = const Color(0xFFCD7F32); // Bronze
      scoreColor = isDark
          ? const Color(0xFFF97316)
          : const Color(
              0xFFC2410C,
            ); // Orange-bronze in dark mode, deep red-orange in light mode
    }

    final name = winner != null
        ? (winner.username?.isNotEmpty == true
              ? '${winner.username}'
              : winner.name)
        : '-';
    final score = winner?.score;
    final prize = winner?.prize ?? '-';
    final avatarUrl = winner != null
        ? _resolveAvatarUrl(winner.avatarPath)
        : '';

    return SizedBox(
      height: height + (avatarSize / 2),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // 1. Pedestal Base Card
          Positioned(
            top: avatarSize / 2,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                  bottom: Radius.circular(16),
                ),
                border: Border.all(
                  color: winner != null
                      ? accentColor.withValues(alpha: 0.35)
                      : colors.stroke,
                  width: isFirst ? 1.5 : 1.0,
                ),
                boxShadow: [
                  if (hasShadow && winner != null) ...[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 18,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.15),
                      blurRadius: 24,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  if (!hasShadow && winner != null)
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  if (winner == null)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  4.0,
                  (avatarSize / 2) + 8.0,
                  4.0,
                  8.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Full name / Username (only one main identifier)
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: isFirst ? 15.5 : 13.5,
                        color: winner != null ? colors.ink : colors.textFaint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Prize (large text)
                    Text(
                      prize,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: winner != null ? scoreColor : colors.textFaint,
                        fontWeight: FontWeight.w900,
                        fontSize: isFirst ? 17.5 : 14.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Score (smaller text)
                    if (score != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 13,
                            color: colors.textFaint,
                          ),
                          const SizedBox(width: 1),
                          Text(
                            '${KurdishFormat.digits(score)} خاڵ',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        '-',
                        style: TextStyle(
                          color: colors.textFaint,
                          fontSize: 10.5,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // 2. Avatar
          Positioned(
            top: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: winner != null ? accentColor : colors.stroke,
                  width: isFirst ? 3.0 : 2.0,
                ),
                boxShadow: winner != null
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.25),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: ProfileAvatar(
                initials: winner != null ? _initials(name) : '?',
                imagePath: avatarUrl.isNotEmpty ? avatarUrl : null,
                size: avatarSize,
                fontSize: isFirst ? 18 : 14,
              ),
            ),
          ),
          // 3. Crown for 1st place
          if (isFirst)
            const Positioned(
              top: -32,
              child: Text('👑', style: TextStyle(fontSize: 35)),
            ),
          // 4. Rank badge at bottom of avatar
          Positioned(
            top: avatarSize - 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: winner != null ? accentColor : colors.stroke,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                rank.toString(),
                style: TextStyle(
                  color: winner != null ? Colors.black : colors.textMuted,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} // Closes WinnersView

bool _isMe(QuizWinner w, dynamic me) {
  if (me == null) return false;
  if (w.userId != null && w.userId == me.id) return true;
  if (w.username != null && w.username == me.username) return true;
  return false;
}

// ─────────────────────────────────────────────
// LEADERBOARD ROW  (ناو-براوەکان)
// ─────────────────────────────────────────────
class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.winner,
    required this.index,
    required this.isYou,
    required this.colors,
    required this.theme,
  });

  final QuizWinner winner;
  final int index;
  final bool isYou;
  final AppColors colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _resolveAvatarUrl(winner.avatarPath);

    return TweenAnimationBuilder<double>(
      key: ValueKey(winner.userId ?? index),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 280 + index * 40),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - t)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        child: Container(
          decoration: BoxDecoration(
            color: isYou
                ? AppColors.purple.withValues(alpha: 0.10)
                : colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isYou
                  ? AppColors.purpleLight.withValues(alpha: 0.4)
                  : colors.stroke,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Rank number
                SizedBox(
                  width: 28,
                  child: Text(
                    KurdishFormat.digits(winner.rank),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isYou ? AppColors.purpleLight : colors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Avatar
                ProfileAvatar(
                  initials: _initials(winner.displayName),
                  imagePath: avatarUrl.isNotEmpty ? avatarUrl : null,
                  size: 36,
                  fontSize: 11,
                ),
                const SizedBox(width: 10),
                // Name + Score inside Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        winner.username?.isNotEmpty == true
                            ? '@${winner.username}'
                            : winner.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isYou ? FontWeight.w700 : FontWeight.w500,
                          color: colors.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (winner.score != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 12,
                              color: colors.textFaint,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${KurdishFormat.digits(winner.score!)} خاڵ',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Beautiful Prize Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceHigh,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.stroke, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 12,
                        color: colors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        winner.prize,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isYou) ...[
                  const SizedBox(width: 8),
                  _YouBadge(theme: theme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// "YOU" BADGE
// ─────────────────────────────────────────────
class _YouBadge extends StatelessWidget {
  const _YouBadge({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDark;
    final badgeColor = isDark ? AppColors.purpleLight : AppColors.purple;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Text(
        AppStrings.youBadge,
        style: theme.textTheme.labelSmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
