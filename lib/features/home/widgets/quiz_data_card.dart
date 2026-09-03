import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/kurdish_format.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../data/models.dart';

class QuizDataCard extends StatefulWidget {
  const QuizDataCard({
    super.key,
    required this.quiz,
    this.onJoin,
    this.onEnter,
    this.onReady,
  });

  final QuizData quiz;
  final VoidCallback? onJoin;
  final VoidCallback? onEnter;
  final VoidCallback? onReady;

  @override
  State<QuizDataCard> createState() => _QuizDataCardState();
}

class _QuizDataCardState extends State<QuizDataCard> {
  Timer? _timer;
  int? _countdownSeconds;
  bool _autoEntered = false;

  // Track if we are within the 30-minute window (1800 seconds)
  bool _isWithinReadyWindow = false;

  @override
  void initState() {
    super.initState();
    _checkTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _checkTime());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant QuizDataCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quiz.isJoined != widget.quiz.isJoined ||
        oldWidget.quiz.sessionStatus != widget.quiz.sessionStatus) {
      _checkTime();
    }
  }

  void _checkTime() {
    if (widget.quiz.scheduledAt == null) return;
    final now = DateTime.now().toUtc();
    final target = widget.quiz.scheduledAt!.toUtc();
    final diff = target.difference(now);

    final seconds = diff.inSeconds;

    if (seconds >= 0) {
      if (mounted) {
        setState(() {
          _countdownSeconds = seconds;
          _isWithinReadyWindow = seconds <= 3600; // 1 hour
        });
      }

      if (seconds == 0 &&
          !_autoEntered &&
          widget.quiz.isJoined &&
          widget.quiz.sessionStatus?.toUpperCase() != 'FINISHED') {
        if (widget.quiz.sessionStatus == 'ready' ||
            widget.quiz.participantStatus == 'READY') {
          _autoEntered = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onEnter?.call();
          });
        }
      }
    } else {
      if (mounted && _countdownSeconds != null) {
        setState(() {
          _countdownSeconds = null;
          _isWithinReadyWindow = false;
        });
      }

      if (!_autoEntered &&
          widget.quiz.isJoined &&
          widget.quiz.sessionStatus?.toUpperCase() != 'FINISHED' &&
          (widget.quiz.sessionStatus == 'ready' ||
              widget.quiz.participantStatus == 'READY')) {
        _autoEntered = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onEnter?.call();
        });
      }
    }
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return 'دەستی پێکرد';
    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (days > 0) {
      return '$days ڕۆژ ${hours > 0 ? '$hours کاتژمێر' : ''}'.trim();
    }
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getButtonText(
    QuizData quiz,
    bool isWithinReadyWindow,
    DateTime? targetDate,
  ) {
    if (!quiz.isJoined) {
      if (quiz.status == 'PUBLISHED' ||
          quiz.status == 'published' ||
          quiz.status == 'running') {
        return 'بەشداریکردن لە کویز';
      }
      if ((quiz.sessionStatus == 'WAITING' || quiz.status == 'ready')) {
        return 'هێشتا کاتی بەشداریکردن نەهاتووە';
      }
      if ((quiz.sessionStatus == 'LIVE' || quiz.status == 'live')) {
        return 'کویزەکە دەستی پێکردووە';
      }
      return 'کۆتایی هاتووە';
    }

    final pStatus = quiz.participantStatus?.toUpperCase();
    final sStatus = quiz.sessionStatus?.toUpperCase();

    if (pStatus == 'FINISHED') return 'کویزت تەواو کرد';
    if (pStatus == 'DISCONNECTED') return 'پەیوەندیت پچڕاوە';

    if (sStatus == 'FINISHED') return 'کویزەکە کۆتایی هاتووە';
    if (sStatus == 'CANCELLED') return 'کویزەکە هەڵوەشایەوە';

    if (sStatus == 'LIVE') {
      if (quiz.isJoined &&
          (pStatus == 'PLAYING' || pStatus == 'READY' || pStatus == 'JOINED')) {
        return 'چوونە ژوورەوە';
      }
      return 'کویزەکە لە کاتی کارکردندایە';
    }

    final bool canEnterNow =
        (quiz.sessionStatus == 'LIVE' || quiz.status == 'live') ||
        (targetDate != null &&
            targetDate.difference(DateTime.now()).inSeconds <= 7200);

    if (!canEnterNow) return 'چاوەڕێبە بۆ ئامادە بوون';

    // ئەگەر پێشتر ئامادەیی ڕاگەیاند، پەیامی چاوەڕێ نیشان بدە
    if (pStatus == 'READY') return 'ئامادەیت ✓ — چاوەڕێ بکە';

    return 'ئامادەم';
  }

  bool _isButtonEnabled(
    QuizData quiz,
    bool isWithinReadyWindow,
    DateTime? targetDate,
  ) {
    if (!quiz.isJoined) {
      return quiz.status == 'PUBLISHED' ||
          quiz.status == 'published' ||
          quiz.status == 'running';
    }

    final pStatus = quiz.participantStatus?.toUpperCase();
    final sStatus = quiz.sessionStatus?.toUpperCase();

    if (pStatus == 'FINISHED' ||
        pStatus == 'DISCONNECTED' ||
        sStatus == 'FINISHED' ||
        sStatus == 'CANCELLED') {
      return false;
    }

    if (sStatus == 'LIVE') {
      if (quiz.isJoined &&
          (pStatus == 'PLAYING' || pStatus == 'READY' || pStatus == 'JOINED')) {
        return true;
      }
      return false;
    }

    final bool canEnterNow =
        (quiz.sessionStatus == 'LIVE' || quiz.status == 'live') ||
        (targetDate != null &&
            targetDate.difference(DateTime.now()).inSeconds <= 7200);

    // ئەگەر READY بوو بەڵام LIVE نەبووە، بەتنەکە غەیری چالاک بخرێت
    if (pStatus == 'READY' && sStatus != 'LIVE') return false;

    if (canEnterNow) return true;

    // Disabled until start time arrives
    return false;
  }

  void _onButtonPressed(QuizData quiz, DateTime? targetDate) {
    if (!quiz.isJoined) {
      if (quiz.status == 'PUBLISHED' ||
          quiz.status == 'published' ||
          quiz.status == 'running') {
        widget.onJoin?.call();
      }
      return;
    }

    final pStatus = quiz.participantStatus?.toUpperCase();
    final sStatus = quiz.sessionStatus?.toUpperCase();

    // کویزەکە LIVE ە: چوونە ناوە
    if (sStatus == 'LIVE' &&
        (pStatus == 'PLAYING' || pStatus == 'READY' || pStatus == 'JOINED')) {
      widget.onEnter?.call();
      return;
    }

    // JOINED بوو بەڵام LIVE نەبووە: تەنها ئامادەیی ڕابگرە، نەچێت پەیجی تر
    if (pStatus == 'JOINED') {
      widget.onReady?.call();
      return;
    }

    // READY بوو بەڵام هێشتا LIVE نەبووە — چاوەڕێبە
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quiz;
    final theme = Theme.of(context);
    final sStatus = quiz.sessionStatus?.toUpperCase();
    final colors = AppColors.of(context);
    final targetDate = quiz.scheduledAt;

    final String dayName = targetDate != null
        ? KurdishFormat.weekdays[targetDate.weekday - 1]
        : 'دیارینەکراوە';

    final String dateText = targetDate != null
        ? '${targetDate.year}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.day.toString().padLeft(2, '0')}'
        : '-';

    final int hour12 = targetDate != null
        ? (targetDate.hour % 12 == 0 ? 12 : targetDate.hour % 12)
        : 0;
    final String period = targetDate != null
        ? (targetDate.hour >= 12 ? 'ئێوارە' : 'بەیانی')
        : '';
    final String timeText = targetDate != null
        ? '${hour12.toString().padLeft(2, '0')}:${targetDate.minute.toString().padLeft(2, '0')} $period'
        : 'کات دیارینەکراوە';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.stroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Logo + Title and Countdown Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Quiz Logo / Avatar with Fallback to Project App Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.stroke.withValues(alpha: 0.8),
                  ),
                  color: colors.surfaceHigh,
                ),
                clipBehavior: Clip.antiAlias,
                child:
                    (quiz.avatarUrl != null &&
                        quiz.avatarUrl!.trim().isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: quiz.avatarUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, error, stackTrace) =>
                            Image.asset(
                              'assets/images/app_icon.png',
                              fit: BoxFit.cover,
                            ),
                      )
                    : Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  quiz.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Countdown badge
              if (_countdownSeconds != null && _countdownSeconds! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.purpleLight.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.purpleLight.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: AppColors.purpleLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDuration(_countdownSeconds!),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.purpleLight,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          if (quiz.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              quiz.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textMuted,
                height: 1.4,
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),

          // Details Grid (Difficulty, Questions, Participants, Winners, Rewards)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                if (sStatus != 'FINISHED') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _InfoItem(
                        icon: Icons.speed_rounded,
                        label: 'ئاست',
                        value: quiz.difficulty == 'easy'
                            ? 'ئاسان'
                            : (quiz.difficulty == 'medium'
                                  ? 'مامناوەند'
                                  : 'قورس'),
                        valueColor: quiz.difficulty == 'easy'
                            ? AppColors.success
                            : (quiz.difficulty == 'medium'
                                  ? AppColors.warning
                                  : AppColors.danger),
                      ),
                      _InfoItem(
                        icon: Icons.format_list_bulleted_rounded,
                        label: 'پرسیار',
                        value: KurdishFormat.number(quiz.questionCount),
                      ),
                      _InfoItem(
                        icon: Icons.people_rounded,
                        label: 'بەشداربوو',
                        value: KurdishFormat.number(quiz.participantCount),
                      ),
                    ],
                  ),
                ],
                // Finished quiz section
                if (sStatus == 'FINISHED') ...[
                  if (quiz.winners.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.emoji_events_rounded,
                              size: 20,
                              color: AppColors.purpleLight,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'براوەکانی کویز',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.purpleLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...quiz.winners.map((w) {
                          final rank = (w['rank'] as num?)?.toInt() ?? 1;
                          final name =
                              (w['username'] ?? w['userName'] ?? 'یاریزان')
                                  .toString();
                          final prizeRaw = w['prize'];
                          String prize = '';
                          if (prizeRaw != null && prizeRaw.toString().isNotEmpty) {
                            final parsed = int.tryParse(prizeRaw.toString());
                            prize = parsed != null ? KurdishFormat.moneyIqd(parsed) : prizeRaw.toString();
                          }
                          final avatarUrl =
                              w['avatarUrl'] as String? ??
                              w['avatarKey'] as String?;
                          final score = (w['score'] as num?)?.toInt() ?? 0;

                          final bool isTop3 = rank <= 3;
                          Color rankColor;
                          if (rank == 1) {
                            rankColor = AppColors.warning;
                          } else if (rank == 2) {
                            rankColor = const Color(0xFFC0C0C0);
                          } else if (rank == 3) {
                            rankColor = const Color(0xFFCD7F32);
                          } else {
                            rankColor = colors.textMuted;
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isTop3
                                      ? rankColor.withValues(alpha: 0.3)
                                      : colors.stroke.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Rank Badge
                                  Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isTop3
                                          ? rankColor.withValues(alpha: 0.15)
                                          : colors.surfaceHigh,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      KurdishFormat.digits(rank),
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: rankColor,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // User Avatar
                                  ProfileAvatar(
                                    initials: initialsFromName(name),
                                    imagePath: avatarUrl,
                                    size: 36,
                                    fontSize: 14,
                                    showRing: false,
                                  ),
                                  const SizedBox(width: 12),

                                  // User Name & Score
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'خاڵ: ${KurdishFormat.number(score)}',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: colors.textMuted,
                                                fontSize: 12,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Prize Badge
                                  if (prize.isNotEmpty)
                                    Container(
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
                                      child: Text(
                                        prize,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.success,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.stroke.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sentiment_dissatisfied_rounded,
                            size: 18,
                            color: colors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'کویزەکە تەواو بوو بێ براوە',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ] else if (quiz.rewards.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: colors.stroke.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  ...quiz.rewards.map((r) {
                    final rank = (r['rank'] as num?)?.toInt() ?? 0;
                    final amount = (r['amount'] as num?)?.toInt() ?? 0;
                    final rankText = rank == 1
                        ? 'براوەی یەکەم'
                        : (rank == 2
                              ? 'براوەی دووەم'
                              : (rank == 3 ? 'براوەی سێیەم' : 'براوەی $rank'));
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                rank == 1
                                    ? Icons.emoji_events_rounded
                                    : Icons.star_rounded,
                                size: 16,
                                color: rank == 1
                                    ? AppColors.warning
                                    : (rank == 2
                                          ? const Color(0xFFC0C0C0)
                                          : (rank == 3
                                                ? const Color(0xFFCD7F32)
                                                : colors.textMuted)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                rankText,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: rank == 1
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              KurdishFormat.moneyIqd(amount),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Date and Day Row at the bottom (ONLY shown for upcoming/active quizzes, hidden for finished quizzes)
          if (targetDate != null &&
              quiz.sessionStatus?.toUpperCase() != 'FINISHED' &&
              quiz.status != 'ARCHIVED' &&
              quiz.status != 'archived') ...[
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.purpleLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.purpleLight,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dateText  ·  $timeText',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],

          // Action Button — only show when start time is set
          if (targetDate != null &&
              (widget.onJoin != null ||
                  widget.onEnter != null ||
                  widget.onReady != null)) ...[
            if (sStatus == 'LIVE' && !quiz.isJoined)
              const SizedBox.shrink()
            else ...[
              const SizedBox(height: 20),
              if (quiz.participantStatus?.toUpperCase() == 'READY' &&
                  quiz.sessionStatus?.toUpperCase() != 'LIVE' &&
                  !((quiz.sessionStatus == 'LIVE' || quiz.status == 'live') ||
                      (targetDate.difference(DateTime.now()).isNegative)))
                // Render text only instead of button
                Center(
                  child: Text(
                    'چاوەڕێبە تا دەست پێدەکات',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed:
                        _isButtonEnabled(quiz, _isWithinReadyWindow, targetDate)
                        ? () => _onButtonPressed(quiz, targetDate)
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient:
                            _isButtonEnabled(
                              quiz,
                              _isWithinReadyWindow,
                              targetDate,
                            )
                            ? AppColors.purpleGradient
                            : null,
                        color:
                            _isButtonEnabled(
                              quiz,
                              _isWithinReadyWindow,
                              targetDate,
                            )
                            ? null
                            : (quiz.isJoined
                                  ? AppColors.purpleLight.withValues(
                                      alpha: 0.12,
                                    )
                                  : colors.stroke),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            quiz.isJoined &&
                                !_isButtonEnabled(
                                  quiz,
                                  _isWithinReadyWindow,
                                  targetDate,
                                )
                            ? Border.all(
                                color: AppColors.purpleLight.withValues(
                                  alpha: 0.3,
                                ),
                              )
                            : null,
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (quiz.isJoined &&
                                !_isButtonEnabled(
                                  quiz,
                                  _isWithinReadyWindow,
                                  targetDate,
                                )) ...[
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.purpleLight,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              _getButtonText(
                                quiz,
                                _isWithinReadyWindow,
                                targetDate,
                              ),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color:
                                    _isButtonEnabled(
                                      quiz,
                                      _isWithinReadyWindow,
                                      targetDate,
                                    )
                                    ? Colors.white
                                    : (quiz.isJoined
                                          ? AppColors.purpleLight
                                          : colors.textMuted),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: colors.textMuted),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.textMuted,
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? colors.ink,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
