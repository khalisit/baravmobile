import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/routing/transitions.dart';
import '../../../core/services/live_quiz_access_guard.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/kurdish_format.dart';
import '../../../core/widgets/barav_button.dart';
import '../../../data/live_quiz_models.dart';
import '../../../core/session/session_controller.dart';
import '../../../data/models.dart';
import '../../live_quiz/live_quiz_controller.dart';
import '../../live_quiz/live_quiz_host_screen.dart';
import 'level_up_presenter.dart';

/// کارتی کویزی داهاتوو — ژمێرەری پێچەوانە لەگەڵ کات و بەرواری دەستپێکردن.
class NextQuizCard extends StatefulWidget {
  const NextQuizCard({super.key, required this.quiz});

  final QuizData quiz;

  @override
  State<NextQuizCard> createState() => _NextQuizCardState();
}

class _NextQuizCardState extends State<NextQuizCard> {
  late Duration _remaining = _computeRemaining();
  Timer? _timer;

  Duration _computeRemaining() {
    if (widget.quiz.scheduledAt == null) return Duration.zero;
    final diff = widget.quiz.scheduledAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  void initState() {
    super.initState();
    // Initialize controller with this quiz
    final token = SessionController.instance.token;
    LiveQuizController.instance.initializeWithQuiz(widget.quiz, token: token);

    if (_remaining == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoEnterQuiz();
      });
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final newRemaining = _computeRemaining();
        if (newRemaining == Duration.zero && _remaining != Duration.zero) {
          // It just hit zero!
          _autoEnterQuiz();
        }
        setState(() => _remaining = newRemaining);
      }
    });
  }

  bool _autoEntered = false;

  void _autoEnterQuiz() {
    if (_autoEntered) return;
    _autoEntered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openLiveQuiz();
    });
  }

  @override
  void didUpdateWidget(covariant NextQuizCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quiz.id != widget.quiz.id ||
        oldWidget.quiz.scheduledAt != widget.quiz.scheduledAt) {
      final token = SessionController.instance.token;
      LiveQuizController.instance.initializeWithQuiz(widget.quiz, token: token);
      _remaining = _computeRemaining();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _openLiveQuiz() async {
    final allowed = await guardLiveQuizAccess(context);
    if (!allowed || !mounted) return;

    final token = SessionController.instance.token;
    if (token == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final c = LiveQuizController.instance;
      await c.initializeWithQuiz(widget.quiz, token: token);

      if (!mounted) return;
      Navigator.of(context).pop(); // close loading dialog

      if (!c.isReady) {
        c.markReady();
      }
      if (c.phase == LiveQuizPhase.scheduled) {
        c.checkSchedule();
      }
      if (c.isLivePhase) {
        Navigator.of(context).push(fadeRoute(const LiveQuizHostScreen())).then((
          _,
        ) {
          if (!mounted) return;
          unawaited(LevelUpPresenter.presentIfPending(context));
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          c.onHostOpened();
        });
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading dialog
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ڕوودانی هەڵە لە بارکردنی پرسیارەکان: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return ListenableBuilder(
      listenable: LiveQuizController.instance,
      builder: (context, _) {
        final c = LiveQuizController.instance;
        final isLive = _remaining == Duration.zero || c.isLivePhase;
        final inLobby = c.phase == LiveQuizPhase.lobby;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isLive
                  ? AppColors.purple.withValues(alpha: 0.45)
                  : colors.stroke,
            ),
            boxShadow: isLive
                ? [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                      spreadRadius: -10,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isLive
                          ? AppColors.purple.withValues(alpha: 0.16)
                          : colors.surfaceHigh,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      isLive ? AppStrings.liveNow : AppStrings.nextQuiz,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isLive
                            ? AppColors.purpleLight
                            : colors.textMuted,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (c.quiz != null)
                    Text(
                      c.quiz!.title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              if (!isLive) ...[
                Row(
                  children: [
                    _TimeBlock(
                      value: _remaining.inDays,
                      label: AppStrings.days,
                    ),
                    const SizedBox(width: 8),
                    _TimeBlock(
                      value: _remaining.inHours % 24,
                      label: AppStrings.hours,
                    ),
                    const SizedBox(width: 8),
                    _TimeBlock(
                      value: _remaining.inMinutes % 60,
                      label: AppStrings.minutes,
                    ),
                    const SizedBox(width: 8),
                    _TimeBlock(
                      value: _remaining.inSeconds % 60,
                      label: AppStrings.seconds,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${AppStrings.lobbyStartsIn} ${KurdishFormat.time(widget.quiz.scheduledAt!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 14),
                BaravButton(
                  label: _remaining.inSeconds <= 7200
                      ? 'ئامادەم'
                      : 'چاوەڕێبە بۆ ئامادە بوون',
                  onPressed: _remaining.inSeconds <= 7200
                      ? _openLiveQuiz
                      : null,
                ),
              ] else if (widget.quiz.sessionStatus == 'LIVE' ||
                  c.phase == LiveQuizPhase.question ||
                  c.phase == LiveQuizPhase.reveal) ...[
                if (widget.quiz.isJoined) ...[
                  BaravButton(
                    label: AppStrings.joinLiveQuiz,
                    onPressed: _openLiveQuiz,
                  ),
                ] else ...[
                  Text(
                    'کویزەکە دەستی پێکردووە و ناتوانیت بەشداربیت',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ] else if (widget.quiz.sessionStatus == 'FINISHED' ||
                  c.phase == LiveQuizPhase.finished) ...[
                Text(
                  'کویزەکە کۆتایی پێهاتووە',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ] else if (inLobby) ...[
                BaravButton(
                  label: AppStrings.joinLiveQuiz,
                  onPressed: _openLiveQuiz,
                ),
              ] else ...[
                BaravButton(
                  label: AppStrings.joinLiveQuiz,
                  onPressed: _openLiveQuiz,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TimeBlock extends StatelessWidget {
  const _TimeBlock({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              KurdishFormat.padded(value),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
