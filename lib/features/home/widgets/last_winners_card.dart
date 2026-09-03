import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/kurdish_format.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../data/live_quiz_models.dart';
import '../../live_quiz/live_quiz_controller.dart';

/// براوەکانی کویزی پێشوو — پۆدیۆمی گۆڵد/سیلڤەر/برۆنز + کاونتداونی ڕاستەوخۆ دوای ۲ خولەک
class LastWinnersCard extends StatefulWidget {
  const LastWinnersCard({super.key});

  static const _gold = Color(0xFFFFD700);
  static const _silver = Color(0xFFC0C0C0);
  static const _bronze = Color(0xFFCD7F32);

  static Color accentForRank(int rank) {
    switch (rank) {
      case 1:
        return _gold;
      case 2:
        return _silver;
      case 3:
        return _bronze;
      default:
        return AppColors.cta;
    }
  }

  @override
  State<LastWinnersCard> createState() => _LastWinnersCardState();
}

class _LastWinnersCardState extends State<LastWinnersCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    final endedAt = LiveQuizController.instance.lastWinnersEndedAt;
    if (endedAt == null) return;

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final nowUtc = DateTime.now().toUtc();
      final elapsed = nowUtc.difference(endedAt.toUtc()).inSeconds;
      if (elapsed >= 120 || elapsed < -30) {
        timer.cancel();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final c = LiveQuizController.instance;
    final winners = c.lastWinners;
    final endedAt = c.lastWinnersEndedAt;

    final nowUtc = DateTime.now().toUtc();
    final endedAtUtc = endedAt?.toUtc();

    int elapsedSeconds = 0;
    bool isWithin2Minutes = false;
    if (endedAtUtc != null) {
      elapsedSeconds = nowUtc.difference(endedAtUtc).inSeconds;
      isWithin2Minutes = elapsedSeconds >= -30 && elapsedSeconds < 120;
    }

    final bool isExpired = winners.isEmpty || !isWithin2Minutes;

    Widget content;
    if (isExpired) {
      content = const SizedBox.shrink(key: ValueKey('empty_last_winners'));
    } else {
      // Calculate remaining countdown time MM:SS
      final remainingSeconds = (120 - elapsedSeconds).clamp(0, 120);
      final minutes = remainingSeconds ~/ 60;
      final seconds = remainingSeconds % 60;
      final timerString =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      final activeGold = isDark ? LastWinnersCard._gold : const Color(0xFFB58000);

      content = Container(
        key: const ValueKey('active_last_winners_card'),
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141724) : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activeGold.withValues(
              alpha: isDark ? 0.35 : 0.45,
            ),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: activeGold.withValues(
                alpha: isDark ? 0.12 : 0.16,
              ),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // -- Header (Compact with Ticking Countdown Pill) --
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    activeGold.withValues(alpha: 0.16),
                    isDark ? const Color(0xFF1A1A2E) : colors.surface,
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: colors.stroke.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: activeGold.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.lastWinners,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                            fontSize: 15,
                          ),
                        ),
                        if (c.lastWinnersQuizTitle != null &&
                            c.lastWinnersQuizTitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            c.lastWinnersQuizTitle!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // -- Ticking Countdown Pill --
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: activeGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: activeGold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 13,
                          color: activeGold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          KurdishFormat.digits(timerString),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: activeGold,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // -- Winners Count Badge --
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: activeGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: activeGold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_alt_rounded,
                          size: 13,
                          color: activeGold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          KurdishFormat.digits(winners.length),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: activeGold,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // -- Podium (Top 3 - Compact Padding) --
            if (winners.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                child: _Podium(winners: winners.take(3).toList()),
              ),

            // -- Other Winners List (Rank 4+ - Compact Padding) --
            if (winners.length > 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Column(
                  children: [
                    for (var i = 3; i < winners.length; i++) ...[
                      if (i > 3) const SizedBox(height: 6),
                      _WinnerRow(winner: winners[i]),
                    ],
                  ],
                ),
              ),
          ],
        ),
      );
    }

    // Smooth real-time fade & collapse transition when hiding
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: content,
    );
  }
}

class _Podium extends StatelessWidget {
  final List<QuizWinner> winners;
  const _Podium({required this.winners});

  @override
  Widget build(BuildContext context) {
    final first = winners.isNotEmpty ? winners[0] : null;
    final second = winners.length > 1 ? winners[1] : null;
    final third = winners.length > 2 ? winners[2] : null;

    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final colWidth = totalWidth / 3.0;

        return SizedBox(
          width: totalWidth,
          height: 145, // Fits scaled down avatar + pedestal
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (second != null)
                Positioned(
                  left: 0,
                  bottom: 0,
                  width: colWidth + 2,
                  child: _buildPedestal(
                    winner: second,
                    rank: 2,
                    colors: colors,
                    theme: theme,
                    height: 80,
                  ),
                ),
              if (third != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  width: colWidth + 2,
                  child: _buildPedestal(
                    winner: third,
                    rank: 3,
                    colors: colors,
                    theme: theme,
                    height: 80,
                  ),
                ),
              if (first != null)
                Positioned(
                  left: colWidth - 2,
                  right: colWidth - 2,
                  bottom: 0,
                  child: _buildPedestal(
                    winner: first,
                    rank: 1,
                    colors: colors,
                    theme: theme,
                    height: 105,
                    hasShadow: true,
                  ),
                ),
            ],
          ),
        );
      },
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
    final avatarSize = isFirst ? 50.0 : 40.0;

    final isDark = theme.brightness == Brightness.dark;
    Color accentColor;
    Color scoreColor;
    if (isFirst) {
      accentColor = const Color(0xFFFFD700); // Gold
      scoreColor = isDark ? const Color(0xFFFFD700) : const Color(0xFFB58000);
    } else if (isSecond) {
      accentColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);
      scoreColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569);
    } else {
      accentColor = const Color(0xFFCD7F32); // Bronze
      scoreColor = isDark ? const Color(0xFFF97316) : const Color(0xFFC2410C);
    }

    final name = winner != null
        ? (winner.username?.isNotEmpty == true
              ? '${winner.username}'
              : winner.name)
        : '-';
    final prize = winner?.prize ?? '-';

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
                  top: Radius.circular(16),
                  bottom: Radius.circular(12),
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
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  2.0,
                  (avatarSize / 2) + 4.0,
                  2.0,
                  4.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                        fontSize: isFirst ? 12 : 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (winner?.score != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bolt_rounded, size: 10, color: scoreColor),
                          const SizedBox(width: 2),
                          Text(
                            KurdishFormat.digits(winner!.score!),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scoreColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        prize,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                  width: isFirst ? 2.5 : 1.5,
                ),
              ),
              child: ProfileAvatar(
                initials: winner != null ? initialsFromName(name) : '?',
                imagePath: winner?.avatarPath,
                size: avatarSize,
                fontSize: isFirst ? 16 : 13,
                showRing: false,
              ),
            ),
          ),
          // 3. Crown for 1st
          if (isFirst)
            const Positioned(
              top: -20,
              child: Text('👑', style: TextStyle(fontSize: 24)),
            ),
          // 4. Rank badge
          Positioned(
            top: avatarSize - 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: winner != null ? accentColor : colors.stroke,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.black : Colors.white,
                  width: 1.0,
                ),
              ),
              child: Text(
                rank.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WinnerRow extends StatelessWidget {
  const _WinnerRow({required this.winner});

  final QuizWinner winner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    final name = winner.username?.isNotEmpty == true
        ? '@${winner.username}'
        : winner.name;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.stroke, width: 0.8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 24,
            child: Text(
              KurdishFormat.digits(winner.rank),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Avatar
          ProfileAvatar(
            initials: initialsFromName(winner.displayName),
            imagePath: winner.avatarPath,
            size: 32,
            fontSize: 11,
            showRing: false,
          ),
          const SizedBox(width: 8),
          // Name + Score
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (winner.score != null) ...[
                  const SizedBox(height: 1),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 10,
                        color: colors.textFaint,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${KurdishFormat.digits(winner.score!)} خاڵ',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                          fontWeight: FontWeight.w500,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Prize Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: colors.surfaceHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.stroke, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.card_giftcard_rounded,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  winner.prize,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
