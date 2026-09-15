import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/extra_life/extra_life_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_backdrop.dart';
import '../../data/live_quiz_models.dart';
import 'live_quiz_audio.dart';
import 'live_quiz_controller.dart';
import '../../core/session/session_controller.dart';
import '../../core/utils/player_progress.dart';
import 'widgets/live_quiz_sponsor_banner.dart';
import 'widgets/points_gain_toast.dart';
import 'widgets/level_up_toast.dart';
import 'widgets/waiting_fallback.dart';
import 'widgets/lobby_view.dart';
import 'widgets/option_vote_badge.dart';
import 'widgets/spectator_status_bar.dart';
import 'widgets/skip_question_chip.dart';
import 'widgets/skip_chance_chip.dart';
import 'widgets/elimination_overlay.dart';
import 'widgets/winners_view.dart';
import 'widgets/question_phase_body.dart';

void _leaveLiveQuiz(BuildContext context) {
  LiveQuizController.instance.leaveSession();
  Navigator.of(context).pop();
}

/// سکرینی یەکگرتووی کویزی زیندوو — لۆبی / پرسیار / دەرکردن / براوە.
class LiveQuizHostScreen extends StatefulWidget {
  const LiveQuizHostScreen({super.key});

  @override
  State<LiveQuizHostScreen> createState() => _LiveQuizHostScreenState();
}

class _LiveQuizHostScreenState extends State<LiveQuizHostScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LiveQuizController.instance.onHostOpened();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LiveQuizController.instance.onHostClosed();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      LiveQuizController.instance.onAppResumed();
    }
  }

  String _pageKey(LiveQuizController c) {
    switch (c.phase) {
      case LiveQuizPhase.lobby:
        return 'lobby';
      case LiveQuizPhase.question:
      case LiveQuizPhase.reveal:
        // key جێگیر — گۆڕینی پرسیار پەیج remount ناکاتەوە.
        return 'question';
      case LiveQuizPhase.finished:
        return 'finished';
      case LiveQuizPhase.scheduled:
      case LiveQuizPhase.idle:
        return 'wait';
    }
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSorani = LocaleController.instance.isSorani;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF151828) : colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colors.stroke.withValues(alpha: isDark ? 0.3 : 0.7),
            width: 1,
          ),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.danger,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              isSorani ? 'دەرچوون لە کویز' : 'Dercûn ji Quizê',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: colors.ink,
              ),
            ),
          ],
        ),
        content: Text(
          isSorani
              ? 'دڵنیای لە دەرچوون؟ ئەگەر ئێستا بچیتە دەرەوە ناتوانیت بەردەوام بیت لە یاریکردن.'
              : 'Ma tu ewle yî ji derketinê? Heke tu niha derkevy tu nikarî berdewam bî li yarîkirinê.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.textMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              isSorani ? 'پاشگەزبوونەوە' : 'Paşgezgerîn',
              style: TextStyle(
                color: colors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              isSorani ? 'دەرچوون' : 'Derketin',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);
    final controller = LiveQuizController.instance;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final canLeave =
            controller.phase == LiveQuizPhase.finished ||
            controller.phase == LiveQuizPhase.scheduled ||
            controller.phase == LiveQuizPhase.idle ||
            controller.isEliminated;
        return PopScope(
          canPop: canLeave,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) {
              if (controller.isEliminated) {
                controller.leaveSession();
              }
              return;
            }
            final leave = await _showExitConfirmationDialog(context);
            if (leave && context.mounted) {
              controller.leaveSession();
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                GlowBackdrop(
                  intensity: 0.7,
                  child: SafeArea(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 480),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final slide = Tween<Offset>(
                          begin: const Offset(0, 0.06),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(_pageKey(controller)),
                        child: _buildBody(controller),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(LiveQuizController c) {
    switch (c.phase) {
      case LiveQuizPhase.lobby:
        return const LobbyView();
      case LiveQuizPhase.question:
      case LiveQuizPhase.reveal:
        // دوای دەرکردنیش پرسیارەکان وەک بینەر دەبینرێن.
        return const _QuestionView();
      case LiveQuizPhase.finished:
        return const WinnersView();
      case LiveQuizPhase.scheduled:
      case LiveQuizPhase.idle:
        return const WaitingFallback();
    }
  }
}

/// پرسیار — هاتنەژوورەوەی نەرم + تایمەری سمووس.
class _QuestionView extends StatefulWidget {
  const _QuestionView();

  @override
  State<_QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends State<_QuestionView>
    with TickerProviderStateMixin {
  final _controller = LiveQuizController.instance;

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
    animationBehavior: AnimationBehavior.preserve,
  );

  late final AnimationController _elimEntr = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    animationBehavior: AnimationBehavior.preserve,
  );

  late final AnimationController _pointsPop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
    animationBehavior: AnimationBehavior.preserve,
  );

  late final AnimationController _levelPop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
    animationBehavior: AnimationBehavior.preserve,
  );

  int _boundQuestion = -1;
  bool _wasEliminated = false;
  bool _showElimOverlay = false;
  int _pointsToastShownFor = -1;
  int _pointsBeforeQuestion = 0;
  int _sessionAccumulatedScore = 0;

  /// لیڤڵی یاریزانەکە لە سەرەتای ئەو پرسیارە — بۆ دیارکردنی لیڤڵ ئاپ لە کاتی وەرگرتنی خاڵ.
  int _levelBeforeQuestion = 0;
  int _levelUpTo = -1;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onController);
    ExtraLifeController.instance.addListener(_onExtraLife);
    _bindQuestion(animateEnter: true);
    if (_controller.isEliminated) {
      _wasEliminated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _presentElimination();
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onController);
    ExtraLifeController.instance.removeListener(_onExtraLife);
    _enter.dispose();
    _elimEntr.dispose();
    _pointsPop.dispose();
    _levelPop.dispose();
    super.dispose();
  }

  void _onExtraLife() {
    if (mounted) setState(() {});
  }

  void _onController() {
    if (!mounted) return;
    if (_controller.isEliminated && !_wasEliminated) {
      _wasEliminated = true;
      _presentElimination();
    }
    if (_controller.questionIndex != _boundQuestion) {
      _bindQuestion(animateEnter: true);
      return;
    }
    _maybeShowPointsToast();
    setState(() {});
  }

  void _maybeShowPointsToast() {
    final awarded = _controller.lastAwardedPoints;
    if (awarded <= 0) return;
    if (_controller.phase != LiveQuizPhase.reveal) return;
    if (_pointsToastShownFor == _controller.questionIndex) return;
    _pointsToastShownFor = _controller.questionIndex;

    // Check if player leveled up from the awarded points.
    final session = SessionController.instance;
    final pointsNow = _pointsBeforeQuestion + awarded;
    final levelNow = PlayerProgress.forPoints(pointsNow).level;

    // debugPrint("[LevelUpCheck] awarded=$awarded, pointsBefore=$_pointsBeforeQuestion, levelBefore=$_levelBeforeQuestion, pointsNow=$pointsNow, levelNow=$levelNow");

    _levelUpTo = -1;
    if (levelNow > _levelBeforeQuestion) {
      _levelUpTo = levelNow;
      // debugPrint("[LevelUpCheck] Level Up Detected! _levelUpTo=$_levelUpTo");
      // Also consume any pending level-up flag so LevelUpPresenter won't double-play.
      session.consumePendingLevelUp();
    } else if (session.hasPendingLevelUp) {
      // Fallback: honour a server-side pending level-up if our local check missed it.
      final pending = session.consumePendingLevelUp();
      if (pending != null) {
        _levelUpTo = pending.to;
        // debugPrint("[LevelUpCheck] Server Pending Level Up Detected! _levelUpTo=$_levelUpTo");
      }
    }

    _sessionAccumulatedScore += awarded;

    _pointsPop.forward(from: 0).then((_) {
      // debugPrint("[LevelUpCheck] _pointsPop finished. _levelUpTo=$_levelUpTo");
      if (_levelUpTo > 0 && mounted) {
        // debugPrint("[LevelUpCheck] Playing LevelUp Sound and starting _levelPop!");
        unawaited(LiveQuizAudio.instance.playLevelUp());
        _levelPop.forward(from: 0).then((_) {
          if (mounted) {
            setState(() {
              _levelUpTo = -1;
            });
          }
        });
        setState(() {});
      }
    });
  }

  void _presentElimination() {
    unawaited(() async {
      await LocaleController.instance.load();
      if (!mounted) return;
      setState(() => _showElimOverlay = true);
      _elimEntr.forward(from: 0);
    }());
  }

  void _dismissEliminationOverlay() {
    _elimEntr.reverse().then((_) {
      if (mounted) setState(() => _showElimOverlay = false);
    });
  }

  void _bindQuestion({required bool animateEnter}) {
    final q = _controller.currentQuestion;
    if (q == null) return;
    _boundQuestion = _controller.questionIndex;
    if (_boundQuestion == 0) {
      _sessionAccumulatedScore = 0;
    }
    _levelUpTo = -1;
    _levelPop.reset();
    // شودەکانی لیڤڵی یاریزانەکە لە سەرەتای ھەر پرسیارێک — بۆ دیارکردنی لیڤڵ ئاپ لە کاتی ئاشکرابوونی خاڵەکە.
    _pointsBeforeQuestion =
        SessionController.instance.points + _sessionAccumulatedScore;
    _levelBeforeQuestion = PlayerProgress.forPoints(
      _pointsBeforeQuestion,
    ).level;

    // debugPrint("[LevelUpCheck] _bindQuestion index=$_boundQuestion, _pointsBeforeQuestion=$_pointsBeforeQuestion, _levelBeforeQuestion=$_levelBeforeQuestion, sessionPoints=${SessionController.instance.points}, sessionAccumScore=$_sessionAccumulatedScore");

    if (animateEnter) {
      _enter.forward(from: 0);
    }
    setState(() {});
  }

  Future<void> _showSkipConfirmDialog(BuildContext context) async {
    final isSorani = LocaleController.instance.isSorani;
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isSorani ? 'بەکارهێنانی هەلی سکایپ' : 'Bikaranîna Derbasbûnê',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.ink,
          ),
        ),
        content: Text(
          isSorani
              ? 'ئایا دڵنیای دەتەوێت هەلی سکایپ بەکاربهێنیت؟ تەنها یەکجار بۆت هەیە لە هەر کویزێکدا، و وەڵامە ڕاستەکەت بۆ هەڵدەبژێرێت.'
              : 'Ma tu ewle yî tu dixwazî derbasbûnê bikar bînî? Tu dikarî tenê carekê di quizê de bikar bînî.',
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              isSorani ? 'نەخێر' : 'Nexêr',
              style: TextStyle(color: colors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              isSorani ? 'بەڵێ، بەکاریبهێنە' : 'Erê, bikar bîne',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await LiveQuizController.instance.useSkipOpportunity();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final question = _controller.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    final revealing = _controller.phase == LiveQuizPhase.reveal;
    final total = question.durationSeconds;
    final qIndex = _controller.questionIndex;
    final spectating = _controller.isEliminated;

    final quizBody = Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_controller.quiz case final quiz? when quiz.hasSponsors) ...[
            LiveQuizSponsorBanner(sponsors: quiz.sponsors),
            const SizedBox(height: 14),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.25),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Row(
                    key: ValueKey(qIndex),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${AppStrings.questionLabel} ${qIndex + 1}/${_controller.questionCount}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: spectating
                              ? AppColors.danger.withValues(alpha: 0.85)
                              : AppColors.purpleLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (question.category != null &&
                          question.category!.trim().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            question.category!.trim(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.purpleLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (!revealing) ...[
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: ListenableBuilder(
                            listenable: _controller,
                            builder: (context, _) {
                              final displaySecs = _controller.secondsLeft;
                              final remainingRatio = total == 0
                                  ? 1.0
                                  : (displaySecs / total).clamp(0.0, 1.0);
                              final urgent = displaySecs <= 5;
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: remainingRatio,
                                    strokeWidth: 2.6,
                                    strokeCap: StrokeCap.round,
                                    backgroundColor: colors.stroke,
                                    color: urgent
                                        ? AppColors.danger
                                        : AppColors.purpleLight,
                                  ),
                                  Text(
                                    '$displaySecs',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: urgent
                                              ? AppColors.danger
                                              : colors.ink,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                        ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                if (spectating) ...[
                  SpectatorStatusBar(onLeave: () => _leaveLiveQuiz(context)),
                  const SizedBox(width: 8),
                ] else if (!revealing) ...[
                  SkipChanceChip(
                    disabled: !_controller.canUseSkipChance,
                    onTap: () => _showSkipConfirmDialog(context),
                  ),
                  const SizedBox(width: 8),
                  if (_controller.canSkipWithExtraLife ||
                      _controller.passArmed) ...[
                    SkipQuestionChip(
                      selected: _controller.passArmed,
                      onTap: _controller.togglePassArmed,
                    ),
                    const SizedBox(width: 10),
                  ],
                ],
                Icon(
                  Icons.people_alt_rounded,
                  size: 16,
                  color: spectating
                      ? AppColors.danger.withValues(alpha: 0.7)
                      : colors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_controller.aliveCount}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: spectating
                        ? AppColors.danger.withValues(alpha: 0.7)
                        : colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topCenter,
                  children: [...previousChildren, ?currentChild],
                );
              },
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.05),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Padding(
                key: ValueKey(
                  '${_controller.questionIndex}_${_controller.phase}',
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: QuestionPhaseBody(
                  question: question,
                  revealing: revealing,
                  spectating: spectating,
                  totalSeconds: total,
                  selectedOption: _controller.selectedOption,
                  buildOptionTile: _buildOptionTile,
                  enterAnimation: _enter,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        quizBody,
        if (_controller.lastAwardedPoints > 0)
          Align(
            alignment: const Alignment(0, -0.12),
            child: PointsGainToast(
              points: _controller.lastAwardedPoints,
              animation: _pointsPop,
            ),
          ),
        if (_levelUpTo > 0)
          Align(
            alignment: const Alignment(0, -0.12),
            child: LevelUpToast(level: _levelUpTo, animation: _levelPop),
          ),
        if (_showElimOverlay)
          EliminationOverlay(
            animation: _elimEntr,
            onContinue: _dismissEliminationOverlay,
            onLeave: () => _leaveLiveQuiz(context),
          ),
      ],
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required ThemeData theme,
    required AppColors colors,
    required int index,
    required QuizOption opt,
    required bool selected,
    required bool revealing,
    required bool spectating,
  }) {
    const letters = ['A', 'B', 'C', 'D'];
    final letter = letters[index.clamp(0, letters.length - 1)];
    final voteCount = revealing ? _controller.optionVoteCount(index) : 0;

    // بنەڕەت — قەڵەو و ئاسوودە.
    Color border = colors.stroke.withValues(alpha: 0.75);
    Color bg = colors.surface;
    Color letterBorder = AppColors.cta.withValues(alpha: 0.28);
    Color letterBg = AppColors.cta.withValues(alpha: 0.08);
    Color letterFg = AppColors.cta;
    Color? textColor = colors.ink;
    IconData? trailingIcon;
    Color? trailingColor;
    Color voteColor = colors.textMuted;
    double borderWidth = 1.8;
    FontWeight textWeight = FontWeight.w700;

    if (revealing) {
      if (opt.isCorrect) {
        border = AppColors.success;
        bg = AppColors.success.withValues(alpha: 0.14);
        letterBorder = AppColors.success;
        letterBg = AppColors.success;
        letterFg = Colors.white;
        trailingIcon = Icons.check_rounded;
        trailingColor = AppColors.success;
        voteColor = AppColors.success;
        borderWidth = 2;
        textWeight = FontWeight.w800;
      } else if (selected) {
        border = AppColors.danger;
        bg = AppColors.danger.withValues(alpha: 0.12);
        letterBorder = AppColors.danger;
        letterBg = AppColors.danger;
        letterFg = Colors.white;
        trailingIcon = Icons.close_rounded;
        trailingColor = AppColors.danger;
        voteColor = AppColors.danger;
        borderWidth = 2;
        textWeight = FontWeight.w800;
      } else if (spectating) {
        border = AppColors.danger.withValues(alpha: 0.28);
        bg = AppColors.danger.withValues(alpha: 0.05);
        letterBorder = AppColors.danger.withValues(alpha: 0.35);
        letterBg = AppColors.danger.withValues(alpha: 0.1);
        letterFg = AppColors.danger.withValues(alpha: 0.75);
        textColor = colors.textMuted;
        textWeight = FontWeight.w500;
      } else {
        letterFg = colors.textFaint;
        letterBorder = colors.stroke;
        letterBg = colors.surfaceHigh;
        textColor = colors.textMuted;
        textWeight = FontWeight.w500;
        border = colors.stroke.withValues(alpha: 0.7);
      }
    } else if (spectating) {
      border = AppColors.danger.withValues(alpha: 0.4);
      bg = AppColors.danger.withValues(alpha: 0.07);
      letterBorder = AppColors.danger.withValues(alpha: 0.45);
      letterBg = AppColors.danger.withValues(alpha: 0.14);
      letterFg = AppColors.danger;
      textColor = colors.textMuted;
      trailingIcon = Icons.lock_outline_rounded;
      trailingColor = AppColors.danger.withValues(alpha: 0.55);
      textWeight = FontWeight.w500;
    } else if (selected) {
      border = AppColors.cta;
      bg = AppColors.cta.withValues(alpha: 0.14);
      letterBorder = AppColors.cta;
      letterBg = AppColors.cta;
      letterFg = Colors.white;
      borderWidth = 2.1;
      textWeight = FontWeight.w800;
    }

    final start = (0.18 + index * 0.1).clamp(0.0, 0.8);

    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) {
        final raw = ((_enter.value - start) / (1 - start)).clamp(0.0, 1.0);
        final t = Curves.easeOutCubic.transform(raw);
        return Opacity(
          opacity: t * (spectating && !revealing ? 0.72 : 1),
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Opacity(
        opacity: spectating && !revealing ? 0.72 : 1.0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: revealing || spectating
                ? null
                : () => _controller.submitAnswer(index),
            borderRadius: BorderRadius.circular(15),
            splashColor: AppColors.cta.withValues(alpha: 0.08),
            highlightColor: AppColors.cta.withValues(alpha: 0.04),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              height: double.infinity,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: border, width: borderWidth),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: letterBg,
                      border: Border.all(color: letterBorder, width: 1.5),
                    ),
                    child: Text(
                      letter,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: letterFg,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      opt.text,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: textColor,
                        fontWeight: textWeight,
                        fontSize: 15.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (revealing && voteCount > 0) ...[
                          OptionVoteBadge(
                            count: voteCount,
                            color: voteColor,
                            theme: theme,
                          ),
                          if (trailingIcon != null) const SizedBox(width: 8),
                        ],
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: Tween<double>(begin: 0.6, end: 1.0)
                                  .animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutBack,
                                    ),
                                  ),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: trailingIcon != null
                              ? Icon(
                                  key: ValueKey(trailingIcon),
                                  trailingIcon,
                                  size: 22,
                                  color: trailingColor,
                                )
                              : const SizedBox(
                                  key: ValueKey('empty'),
                                  width: 0,
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
