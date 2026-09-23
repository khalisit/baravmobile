import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_backdrop.dart';
import '../../data/live_quiz_models.dart';
import '../../data/mock_data.dart';
import '../live_quiz/widgets/question_phase_body.dart';
import '../live_quiz/widgets/points_gain_toast.dart';
import '../live_quiz/widgets/option_vote_badge.dart';
import '../live_quiz/widgets/skip_chance_chip.dart';
import '../live_quiz/live_quiz_audio.dart';
import 'test_winners_view.dart';

class TestQuizScreen extends StatefulWidget {
  const TestQuizScreen({super.key});

  @override
  State<TestQuizScreen> createState() => _TestQuizScreenState();
}

class _TestQuizScreenState extends State<TestQuizScreen>
    with TickerProviderStateMixin {
  final List<LiveQuestion> _questions = MockData.sampleLiveQuestions;
  late List<String> _dummyPlayers;

  int _currentQuestionIndex = 0;
  int _secondsLeft = 10;
  Timer? _timer;

  bool _revealing = false;
  int? _selectedOption;
  int? _userAnsweredAtSeconds;

  int _userScore = 0;
  final Map<String, int> _dummyScores = {};

  // For dummy votes
  late List<int> _dummyVotes;

  late final AnimationController _enterAnimation;
  late final AnimationController _pointsPop;

  int _lastAwardedPoints = 0;

  bool _testSkipUsed = false;

  @override
  void initState() {
    super.initState();
    _enterAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pointsPop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Pick 15 random dummy players
    final rng = Random();
    final allNames = List<String>.from(MockData.mockPlayerNames)..shuffle(rng);
    _dummyPlayers = allNames.take(15).toList();
    for (final p in _dummyPlayers) {
      _dummyScores[p] = 0;
    }

    LiveQuizAudio.instance.warmUp().then((_) {
      if (mounted) {
        _startQuestion();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    LiveQuizAudio.instance.stopAll();
    _enterAnimation.dispose();
    _pointsPop.dispose();
    super.dispose();
  }

  void _startQuestion() {
    setState(() {
      _revealing = false;
      _selectedOption = null;
      _userAnsweredAtSeconds = null;
      _secondsLeft = 10;
      _lastAwardedPoints = 0;
      _dummyVotes = List.filled(
        _questions[_currentQuestionIndex].options.length,
        0,
      );
    });
    _enterAnimation.forward(from: 0);

    LiveQuizAudio.instance.startQuestionTimer(
      remaining: const Duration(seconds: 10),
      total: const Duration(seconds: 10),
      forceRestart: true,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          _secondsLeft = 0;
          _revealAnswer();
        }
      });
    });
  }

  void _revealAnswer() {
    _timer?.cancel();
    LiveQuizAudio.instance.stopQuestionTimer();

    final question = _questions[_currentQuestionIndex];
    final rng = Random();

    // Simulate dummy votes
    _dummyVotes = List.filled(question.options.length, 0);
    for (final p in _dummyPlayers) {
      int choice;
      if (rng.nextDouble() < 0.4) {
        choice = question.options.indexWhere((o) => o.isCorrect);
      } else {
        choice = rng.nextInt(question.options.length);
      }

      int botSecondsLeft = rng.nextInt(10);

      if (choice >= 0 && choice < _dummyVotes.length) {
        _dummyVotes[choice]++;
        if (question.options[choice].isCorrect) {
          int points = 50 + (botSecondsLeft * 5);
          _dummyScores[p] = (_dummyScores[p] ?? 0) + points;
        }
      }
    }

    if (_selectedOption != null &&
        question.options[_selectedOption!].isCorrect) {
      int userSecs = _userAnsweredAtSeconds ?? 0;
      int points = 50 + (userSecs * 5);
      _userScore += points;
      _lastAwardedPoints = points;
      LiveQuizAudio.instance.playAnswerCorrect();
    } else {
      LiveQuizAudio.instance.playAnswerWrong();
    }

    setState(() {
      _revealing = true;
    });

    if (_lastAwardedPoints > 0) {
      _pointsPop.forward(from: 0);
    }

    // Move to next question after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
        });
        LiveQuizAudio.instance.playNextQuestion();
        _startQuestion();
      } else {
        setState(() {
          _currentQuestionIndex = _questions.length;
        });
        LiveQuizAudio.instance.playWinners();
      }
    });
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
    final voteCount = revealing ? (_dummyVotes[index] + (selected ? 1 : 0)) : 0;

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
      } else {
        letterFg = colors.textFaint;
        letterBorder = colors.stroke;
        letterBg = colors.surfaceHigh;
        textColor = colors.textMuted;
        textWeight = FontWeight.w500;
        border = colors.stroke.withValues(alpha: 0.7);
      }
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
      animation: _enterAnimation,
      builder: (context, child) {
        final raw = ((_enterAnimation.value - start) / (1 - start)).clamp(
          0.0,
          1.0,
        );
        final t = Curves.easeOutCubic.transform(raw);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!_revealing && _selectedOption == null) {
              setState(() {
                _selectedOption = index;
                _userAnsweredAtSeconds = _secondsLeft;
              });
            }
          },
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
                            scale: Tween<double>(begin: 0.6, end: 1.0).animate(
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
                            : const SizedBox(key: ValueKey('empty'), width: 0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSkipConfirmDialog(BuildContext context) async {
    if (_selectedOption != null || _revealing) return;

    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Use Skip Chance',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.ink,
          ),
        ),
        content: Text(
          'Are you sure you want to use the skip chance? You only have one for this test, and it will select the correct answer for you.',
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('No', style: TextStyle(color: colors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Yes, use it',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() {
        _testSkipUsed = true;
        final question = _questions[_currentQuestionIndex];
        final correctIndex = question.options.indexWhere((o) => o.isCorrect);
        _selectedOption = correctIndex;
        _userAnsweredAtSeconds = _secondsLeft;
      });
    }
  }

  Widget _buildWinnersView() {
    final user = SessionController.instance.user;
    final username = user?.username ?? 'You';

    final allScores = <String, int>{username: _userScore, ..._dummyScores};
    final sortedPlayers = allScores.keys.toList()
      ..sort((a, b) => allScores[b]!.compareTo(allScores[a]!));

    final winnersList = sortedPlayers.asMap().entries.map((entry) {
      final rank = entry.key + 1;
      final player = entry.value;
      final score = allScores[player]!;
      final isMe = player == username;
      return QuizWinner(
        userId: isMe ? (user?.id ?? 'me') : null,
        username: player,
        name: player,
        rank: rank,
        score: score,
        isWinner: rank <= 3,
        prize: rank == 1
            ? '1000'
            : (rank == 2 ? '500' : (rank == 3 ? '250' : '')),
      );
    }).toList();

    return TestWinnersView(
      winners: winnersList,
      isWinner: winnersList.firstWhere((w) => w.username == username).rank <= 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    if (_currentQuestionIndex >= _questions.length) {
      return Scaffold(
        body: GlowBackdrop(
          intensity: 0.7,
          child: SafeArea(child: _buildWinnersView()),
        ),
      );
    }

    final question = _questions[_currentQuestionIndex];
    final total = 10;

    final quizBody = Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                    key: ValueKey(_currentQuestionIndex),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.purpleLight,
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
                      if (!_revealing) ...[
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: _secondsLeft / total,
                                strokeWidth: 2.6,
                                strokeCap: StrokeCap.round,
                                backgroundColor: colors.stroke,
                                color: _secondsLeft <= 3
                                    ? AppColors.danger
                                    : AppColors.purpleLight,
                              ),
                              Text(
                                '$_secondsLeft',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: _secondsLeft <= 3
                                      ? AppColors.danger
                                      : colors.ink,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                if (!_revealing) ...[
                  SkipChanceChip(
                    overrideSkipCount: _testSkipUsed ? 0 : 1,
                    disabled: _testSkipUsed || _selectedOption != null,
                    onTap: () => _showSkipConfirmDialog(context),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  Icons.people_alt_rounded,
                  size: 16,
                  color: colors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  '16',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.textMuted,
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
                key: ValueKey('${_currentQuestionIndex}_$_revealing'),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: QuestionPhaseBody(
                    question: question,
                    revealing: _revealing,
                    spectating: false,
                    totalSeconds: total,
                    selectedOption: _selectedOption,
                    buildOptionTile: _buildOptionTile,
                    enterAnimation: _enterAnimation,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: GlowBackdrop(
        intensity: 0.7,
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              quizBody,
              if (_lastAwardedPoints > 0)
                Align(
                  alignment: const Alignment(0, -0.12),
                  child: PointsGainToast(
                    points: _lastAwardedPoints,
                    animation: _pointsPop,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
