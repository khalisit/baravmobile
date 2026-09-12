import 'dart:async';

import 'package:flutter/foundation.dart';

import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/extra_life/extra_life_controller.dart';
import '../../core/session/session_controller.dart';
import '../../core/utils/kurdish_format.dart';
import '../../data/live_quiz_models.dart';
import '../../data/models.dart';
import '../../data/mock_data.dart';
import '../../data/api_service.dart';
import 'live_quiz_audio.dart';
import 'live_quiz_haptics.dart';

/// کۆنترۆڵەری کویزی زیندوو — سیمولەیشن لەسەر ئامێر (بێ باک‌ئێند).
class LiveQuizController extends ChangeNotifier {
  LiveQuizController._() {
    unawaited(fetchLastWinners());
    unawaited(fetchQuizSponsors());
  }

  static final LiveQuizController instance = LiveQuizController._();

  /// لۆبی ٦٠ چرکە پێش کاتی دەستپێک دەکرێتەوە (١ خولەک).
  static const Duration preStartLead = Duration(seconds: 60);

  final _audio = LiveQuizAudio.instance;

  ScheduledQuiz? _quiz;
  LiveQuizPhase _phase = LiveQuizPhase.idle;
  int _questionIndex = 0;
  int _secondsLeft = 15;
  int? _selectedOption;
  bool _answered = false;
  bool? _isLastAnswerCorrect;
  QuizSessionStatus _localStatus = QuizSessionStatus.joined;
  int _aliveCount = 0;
  int _totalJoined = 0;
  List<int> _optionVotes = const [0, 0, 0, 0];
  List<QuizWinner> _winners = [];
  List<QuizWinner> _lastWinners = [];
  String? _lastWinnersQuizTitle;
  DateTime? _lastWinnersEndedAt;
  Timer? _tick;
  Timer? _scheduleWatch;
  Timer? _phaseDelay;
  Timer? _lobbyTick;
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  bool _hostOpenRequested = false;
  bool _isReady = false;
  bool _isFinalCountdown = false;
  int _finalCountdownSeconds = 30;
  bool _isLoadingResults = false;
  String? _sessionId;

  String? get sessionId => _sessionId;

  /// تەنها کاتێک شاشەی لایڤ کراوەتەوە دەنگ لێدەدرێت.
  bool _hostAttached = false;
  int _lastAwardedPoints = 0;
  bool _extraLifeUsedThisQuiz = false;
  bool _skipUsedThisQuiz = false;
  bool _pointsSavedForThisSession = false;

  /// تێپەڕاندن هەڵبژێردراوە — لە کۆتایی کاتی پرسیار جێبەجێ دەبێت.
  bool _passArmed = false;

  bool _revealStatsLoaded = false;

  ScheduledQuiz? get quiz => _quiz;
  LiveQuizPhase get phase => _phase;
  int get questionIndex => _questionIndex;
  int get secondsLeft => _secondsLeft;
  int? get selectedOption => _selectedOption;
  bool get answered => _answered;
  QuizSessionStatus get localStatus => _localStatus;
  bool get isEliminated =>
      _localStatus == QuizSessionStatus.finished ||
      _localStatus == QuizSessionStatus.disconnected;
  bool get isWinner =>
      _phase == LiveQuizPhase.finished &&
      _localStatus == QuizSessionStatus.playing;
  int get aliveCount => _aliveCount;
  int get totalJoined => _totalJoined;
  List<int> get optionVotes => List.unmodifiable(_optionVotes);
  int optionVoteCount(int index) {
    if (index < 0 || index >= _optionVotes.length) return 0;
    return _optionVotes[index];
  }

  List<QuizWinner> get winners => List.unmodifiable(_winners);
  List<QuizWinner> get lastWinners => List.unmodifiable(_lastWinners);
  bool get isLoadingResults => _isLoadingResults;
  String? get lastWinnersQuizTitle => _lastWinnersQuizTitle;
  DateTime? get lastWinnersEndedAt => _lastWinnersEndedAt;
  bool get revealStatsLoaded => _revealStatsLoaded;

  Timer? _lastWinnersTimer;

  void _scheduleLastWinnersExpiry() {
    _lastWinnersTimer?.cancel();
    if (_lastWinnersEndedAt == null) return;

    final nowUtc = DateTime.now().toUtc();
    final cutoffUtc = _lastWinnersEndedAt!.toUtc().add(
      const Duration(minutes: 2),
    );
    final remainingMs = cutoffUtc.difference(nowUtc).inMilliseconds;

    if (remainingMs <= 0) {
      notifyListeners();
      return;
    }

    _lastWinnersTimer = Timer(Duration(milliseconds: remainingMs + 100), () {
      notifyListeners();
    });
  }

  /// کویزی خشتەکراو / زیندوو هەیە بۆ پیشاندان لە سەرەکی.
  bool get hasUpcomingQuiz =>
      _quiz != null &&
      (_phase == LiveQuizPhase.scheduled ||
          _phase == LiveQuizPhase.lobby ||
          _phase == LiveQuizPhase.question ||
          _phase == LiveQuizPhase.reveal);

  /// ئەدمین دەتوانێت کویزی خشتەکراو/لۆبی بشارێتەوە.
  bool get canCancelQuiz =>
      _quiz != null &&
      (_phase == LiveQuizPhase.scheduled ||
          _phase == LiveQuizPhase.lobby ||
          _phase == LiveQuizPhase.idle);

  bool get hostOpenRequested => _hostOpenRequested;
  bool get isReady => _isReady;
  bool get isFinalCountdown => _isFinalCountdown;
  bool get isHostAttached => _hostAttached;
  int get lastAwardedPoints => _lastAwardedPoints;
  bool get extraLifeUsedThisQuiz => _extraLifeUsedThisQuiz;
  bool get skipUsedThisQuiz => _skipUsedThisQuiz;
  bool get canUseSkipChance =>
      !_skipUsedThisQuiz &&
      _localStatus == QuizSessionStatus.playing &&
      _phase == LiveQuizPhase.question &&
      (SessionController.instance.user?.skip ?? 0) > 0;
  bool get passArmed => _passArmed;
  bool get canSkipWithExtraLife =>
      !_extraLifeUsedThisQuiz &&
      _localStatus == QuizSessionStatus.playing &&
      _phase == LiveQuizPhase.question &&
      ExtraLifeController.instance.hasLives;

  /// چرکە ماوە بۆ دەستپێکی پرسیارەکان (یان کاتی لۆبی یان ٣٠ چرکەی کۆتایی).
  int get lobbySecondsLeft {
    int totalLeft = 0;
    if (_isFinalCountdown) {
      totalLeft = _finalCountdownSeconds;
    } else {
      final q = _quiz;
      if (q == null) return 0;
      final diff = q.startedAt
          .add(const Duration(seconds: 32))
          .difference(DateTime.now());
      if (diff.isNegative) return 0;
      totalLeft = diff.inSeconds;
    }
    final displayLeft = totalLeft - 2;
    return displayLeft < 0 ? 0 : displayLeft;
  }

  bool get canMarkReady =>
      _quiz != null &&
      (_phase == LiveQuizPhase.scheduled || _phase == LiveQuizPhase.lobby);

  LiveQuestion? get currentQuestion {
    final q = _quiz;
    if (q == null ||
        _questionIndex < 0 ||
        _questionIndex >= q.questions.length) {
      return null;
    }
    return q.questions[_questionIndex];
  }

  int get questionCount => _quiz?.questions.length ?? 0;

  DateTime? get startedAt => _quiz?.startedAt;

  bool get isLivePhase =>
      _phase == LiveQuizPhase.lobby ||
      _phase == LiveQuizPhase.question ||
      _phase == LiveQuizPhase.reveal ||
      _phase == LiveQuizPhase.finished;

  void acknowledgeHostOpened() {
    _hostOpenRequested = false;
  }

  /// یوزەر ئامادەیی خۆی بۆ بەشداری تۆمار دەکات.
  void markReady() {
    if (!canMarkReady || _isReady) return;
    _isReady = true;
    _localStatus = QuizSessionStatus.ready;
    if (_phase == LiveQuizPhase.lobby) {
      _hostOpenRequested = true;
      // دەنگ تەنها دوای کردنەوەی شاشەی لایڤ — نەک لە سەرەکیدا.
    }

    final quizId = _quiz?.id;
    final token = SessionController.instance.token;
    if (quizId != null && token != null) {
      ApiService.setQuizReady(
        quizId,
        token,
      ).catchError((_) => <String, dynamic>{});
    }

    notifyListeners();
  }

  /// کاتێک شاشەی لایڤ دەکرێتەوە.
  void onHostOpened() {
    _hostAttached = true;
    LiveQuizHaptics.prepare();
    unawaited(() async {
      await _audio.warmUp();
      if (!_hostAttached) return;

      if (_phase == LiveQuizPhase.lobby && _isReady) {
        if (_isFinalCountdown) {
          final secs = _finalCountdownSeconds.clamp(0, 30);
          await _audio.ensureLobbyCountdown(
            remaining: Duration(seconds: secs),
            forceRestart: true,
          );
        }
        return;
      }

      if (_phase == LiveQuizPhase.question) {
        final q = currentQuestion;
        if (q != null) {
          await _audio.startQuestionTimer(
            remaining: Duration(seconds: _secondsLeft),
            total: Duration(seconds: q.durationSeconds),
            forceRestart: true,
          );
        }
      }
    }());
  }

  /// کاتێک شاشەی لایڤ دادەخرێت — دەنگ دەوەستێت.
  void onHostClosed() {
    if (!_hostAttached) return;
    _hostAttached = false;
    unawaited(_audio.stopAll());
  }

  /// دوای گەڕانەوە بۆ ئەپ — دەنگ دووبارە دەست پێدەکات ئەگەر لە لایڤ بیت.
  void onAppResumed() {
    if (!_hostAttached) return;
    unawaited(() async {
      await _audio.recover();
      if (!_hostAttached) return;
      if (_phase == LiveQuizPhase.lobby && _isReady) {
        _playLobbyAudio();
      } else if (_phase == LiveQuizPhase.question) {
        final q = currentQuestion;
        if (q != null) {
          await _audio.startQuestionTimer(
            remaining: Duration(seconds: _secondsLeft),
            total: Duration(seconds: q.durationSeconds),
            forceRestart: true,
          );
        }
      }
    }());
  }

  void _playLobbyAudio() {
    if (!_hostAttached || !_isReady) return;
    unawaited(() async {
      await _audio.warmUp();
      if (!_hostAttached || _phase != LiveQuizPhase.lobby || !_isReady) {
        return;
      }
      if (_isFinalCountdown) {
        final secs = _finalCountdownSeconds.clamp(0, 32);
        await _audio.ensureLobbyCountdown(
          remaining: Duration(seconds: secs),
          forceRestart: true,
        );
      }
    }());
  }

  Future<void> initializeWithQuiz(QuizData quizData, {String? token}) async {
    List<LiveQuestion> questionsList = [];
    if (token != null) {
      try {
        questionsList = await ApiService.getQuizQuestions(quizData.id, token);
      } catch (e) {
        debugPrint("Failed to fetch real questions: $e");
      }
    }

    if (questionsList.isEmpty) {
      questionsList = MockData.sampleScheduledQuiz().questions;
    }

    final scheduled = ScheduledQuiz(
      id: quizData.id,
      title: quizData.title,
      description: quizData.description,
      avatarUrl: quizData.avatarUrl,
      startedAt:
          quizData.scheduledAt ??
          DateTime.now().add(const Duration(minutes: 5)),
      questions: questionsList,
      sponsors: _quizSponsors,
      rewards: quizData.rewards,
    );

    if (_quiz != null && _quiz!.id == quizData.id) {
      // Preserve active state, just update the quiz data
      _quiz = scheduled;
    } else {
      scheduleQuiz(scheduled);
    }

    if ((quizData.sessionStatus == 'LIVE' || quizData.status == 'live')) {
      _isReady = true;

      // گرنگە یەکسەر بچینە لۆبی بۆ ئەوەی کۆنێکتی وێبسۆکێت بین
      if (_phase != LiveQuizPhase.lobby &&
          _phase != LiveQuizPhase.question &&
          _phase != LiveQuizPhase.reveal) {
        _enterLobby();
      }
    }
  }

  void scheduleQuiz(ScheduledQuiz quiz) {
    _cancelTimers();
    _hostAttached = false;
    unawaited(_audio.stopAll());
    // FIX E: preserve _isReady and localStatus if same quiz is being re-scheduled
    final isSameQuiz = _quiz != null && _quiz!.id == quiz.id;
    _quiz = quiz;
    _phase = LiveQuizPhase.scheduled;
    _questionIndex = 0;
    _selectedOption = null;
    _answered = false;
    _resetOptionVotes();
    if (!isSameQuiz) {
      // Only reset readiness state when switching to a completely different quiz
      _localStatus = QuizSessionStatus.joined;
      _isReady = false;
    }
    _winners = [];
    _hostOpenRequested = false;
    _isFinalCountdown = false;
    _startScheduleWatch();
    notifyListeners();
  }

  /// بۆ تاقیکردنەوە — لۆبی ئێستا، پرسیارەکان دوای ٣٠ چرکە.
  void startNow() {
    final q = _quiz;
    if (q == null || q.questions.isEmpty) return;
    if (_phase == LiveQuizPhase.question ||
        _phase == LiveQuizPhase.reveal ||
        _phase == LiveQuizPhase.lobby) {
      return;
    }
    scheduleQuiz(q.copyWith(startedAt: DateTime.now().add(preStartLead)));
    _isReady = true;
    _enterLobby();
  }

  void checkSchedule() {
    final q = _quiz;
    if (q == null || _phase != LiveQuizPhase.scheduled) return;
    final openAt = q.startedAt.subtract(preStartLead);
    if (!DateTime.now().isBefore(openAt)) {
      _enterLobby();
    }
  }

  void submitAnswer(int index) {
    if (_phase != LiveQuizPhase.question) return;
    if (_localStatus != QuizSessionStatus.playing) return;
    if (index < 0 || index > 3) return;
    // کاتێک وەڵام دەداتەوە دۆخ دەبێتە ANSWERED و ناتوانێت وەڵامەکە بگۆڕێت
    if (_answered) return;
    _answered = true;
    _selectedOption = index;
    _passArmed = false;
    notifyListeners();

    // ناردنی وەڵام بە کاتی ڕاستەقینە بۆ باکئێند
    final q = currentQuestion;
    final quizId = _quiz?.id;
    final token = SessionController.instance.token;
    if (q != null && quizId != null && q.id.isNotEmpty && token != null) {
      final elapsedSeconds = (q.durationSeconds - _secondsLeft).clamp(
        0,
        q.durationSeconds,
      );
      final elapsedMs = elapsedSeconds * 1000;
      final selectedOptId = (index >= 0 && index < q.options.length)
          ? q.options[index].id
          : '';
      ApiService.submitAnswer(quizId, q.id, selectedOptId, elapsedMs, token)
          .then((res) {
            if (res['correct'] != null) {
              _isLastAnswerCorrect = res['correct'] as bool;
              if (_isLastAnswerCorrect == false) {
                _localStatus =
                    QuizSessionStatus.finished; // Eliminated on wrong answer
              }
              notifyListeners();
            }
          })
          .catchError((e) {
            debugPrint('submitAnswer Error: $e');
          });
    }
  }

  Future<void> useSkipOpportunity() async {
    if (_phase != LiveQuizPhase.question) return;
    if (_localStatus != QuizSessionStatus.playing) return;
    if (_answered) return;
    if (_skipUsedThisQuiz) return;

    final session = SessionController.instance;
    final currentSkip = session.user?.skip ?? 0;
    if (currentSkip <= 0) return;

    try {
      final newSkip = await ApiService.useSkipOpportunity(
        session.user!.id,
        session.token!,
      );
      session.updateSkipLocal(newSkip);
      _skipUsedThisQuiz = true;

      final q = currentQuestion;
      if (q != null) {
        final correctIdx = q.correctIndex;
        if (correctIdx != -1) {
          submitAnswer(correctIdx);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error using skip: $e");
    }
  }

  /// هەڵبژاردن / لابردنی تێپەڕاندن — ڕاستەوخۆ جێبەجێ ناکرێت.
  void togglePassArmed() {
    if (!canSkipWithExtraLife && !_passArmed) return;
    if (_phase != LiveQuizPhase.question) return;
    if (_localStatus != QuizSessionStatus.playing) return;
    if (_extraLifeUsedThisQuiz) return;

    _passArmed = !_passArmed;
    if (_passArmed) {
      _answered = false;
      _selectedOption = null;
    }
    notifyListeners();
  }

  Future<void> fetchLastWinners() async {
    try {
      final res = await ApiService.getLastWinners();
      if (res['data'] != null) {
        final data = res['data'];
        final title = data['quizTitle'] as String?;
        final list = data['winners'] as List<dynamic>?;
        if (list != null && list.isNotEmpty) {
          _lastWinners = list
              .map(
                (w) => QuizWinner(
                  name:
                      w['userName'] as String? ??
                      w['username'] as String? ??
                      'یاریزان',
                  username: w['username'] as String?,
                  prize:
                      w['prize'] as String? ??
                      _prizeForRank(w['rank'] as int? ?? 1),
                  rank: w['rank'] as int? ?? 1,
                  avatarPath:
                      w['avatarUrl'] as String? ?? w['avatarKey'] as String?,
                ),
              )
              .toList();
          _lastWinnersQuizTitle = title;
          final endedAtRaw = data['endedAt'];
          if (endedAtRaw != null && endedAtRaw.toString().trim().isNotEmpty) {
            final rawStr = endedAtRaw.toString().trim().replaceAll(' ', 'T');
            // Dart parses naive strings as UTC; toLocal() aligns with DateTime.now()
            _lastWinnersEndedAt = DateTime.tryParse(rawStr)?.toLocal();
          } else {
            _lastWinnersEndedAt = null;
          }
          _scheduleLastWinnersExpiry();
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  List<QuizSponsor> _quizSponsors = MockData.sampleScheduledQuiz().sponsors;
  List<QuizSponsor> get quizSponsors => _quizSponsors;

  Future<void> fetchQuizSponsors() async {
    try {
      final list = await ApiService.getSponsors(type: 'quiz');
      if (list.isNotEmpty) {
        _quizSponsors = list.map((s) {
          final name = (s['name'] ?? '').toString();
          final link = (s['link'] ?? '').toString();
          final imageUrl = (s['imageUrl'] ?? s['image_url']) as String? ?? '';
          final fullUrl = imageUrl.startsWith('http')
              ? imageUrl
              : '${ApiService.baseUrl.replaceAll('/api', '')}/media/${imageUrl.replaceFirst(RegExp(r'^/'), '')}';

          return QuizSponsor(
            brandName: name.isNotEmpty ? name : 'BARAV QUIZ',
            mediaUrl: fullUrl,
            kind: SponsorMediaKind.image,
            tagline: link.isNotEmpty ? link : null,
          );
        }).toList();
        if (_quiz != null) {
          _quiz = _quiz!.copyWith(sponsors: _quizSponsors);
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  void resetToScheduledSample() {
    scheduleQuiz(MockData.sampleScheduledQuiz());
  }

  /// شاردنەوەی کویزی خشتەکراو لەلایەن ئەدمین — براوەکانی پێشوو دەمێننەوە.
  void cancelScheduledQuiz() {
    if (_phase == LiveQuizPhase.question || _phase == LiveQuizPhase.reveal) {
      return;
    }
    if (_quiz == null && _phase == LiveQuizPhase.idle) return;
    _clearActiveQuizKeepWinners();
  }

  /// کاتێک یوزەر شاشەی لایڤ جێدەهێڵێت.
  void leaveSession() {
    onHostClosed();
    final quizId = _quiz?.id;
    final token = SessionController.instance.token;
    // FIX C: Do NOT call the backend /leave endpoint if the participant is
    // currently PLAYING. A PLAYING user leaving due to navigation/lifecycle
    // must NOT be marked DISCONNECTED — that kills their answer flow.
    // Only send /leave for JOINED or READY participants (waiting room exit).
    final isActivelyPlaying = _localStatus == QuizSessionStatus.playing;
    if (quizId != null && token != null && !isActivelyPlaying) {
      ApiService.leaveLiveQuiz(
        quizId,
        token,
      ).catchError((_) => <String, dynamic>{});
    }
    // دوای تەواوبوون: کویز لادەچێت، ناوی براوەکان دەمێنێتەوە.
    if (_phase == LiveQuizPhase.finished) {
      _clearActiveQuizKeepWinners();
    }
  }

  void _clearActiveQuizKeepWinners() {
    _cancelTimers();
    _scheduleWatch?.cancel();
    _disconnectWebSocket();
    unawaited(_audio.stopAll());
    _quiz = null;
    _phase = LiveQuizPhase.idle;
    _questionIndex = 0;
    _selectedOption = null;
    _answered = false;
    _resetOptionVotes();
    _localStatus = QuizSessionStatus.joined;
    _winners = [];
    _pointsSavedForThisSession = false;
    _aliveCount = 0;
    _totalJoined = 0;
    _hostOpenRequested = false;
    _isReady = false;
    _isFinalCountdown = false;
    _hostAttached = false;
    _skipUsedThisQuiz = false;
    _passArmed = false;
    // _lastWinners + _lastWinnersQuizTitle دەمێننەوە.
    _safeNotify();
  }

  bool _pendingNotify = false;

  void _safeNotify() {
    if (_pendingNotify) return;
    _pendingNotify = true;
    Future.microtask(() {
      _pendingNotify = false;
      notifyListeners();
    });
  }

  void _startScheduleWatch() {
    _scheduleWatch?.cancel();
    _scheduleWatch = Timer.periodic(const Duration(seconds: 1), (_) {
      checkSchedule();
      if (_phase == LiveQuizPhase.scheduled) notifyListeners();
    });
  }

  void _enterLobby() {
    _scheduleWatch?.cancel();
    _phase = LiveQuizPhase.lobby;
    // بەکارهێنانی داتای ڕاستەقینە لە جیاتی 36 + _rng.nextInt(28)
    _totalJoined = 0;
    _aliveCount = 0;
    _localStatus = _isReady
        ? QuizSessionStatus.ready
        : QuizSessionStatus.joined;
    _questionIndex = 0;
    _extraLifeUsedThisQuiz = false;
    _skipUsedThisQuiz = false;
    _passArmed = false;
    _isFinalCountdown = false;
    _hostOpenRequested = _isReady;

    final token = SessionController.instance.token;
    final quizId = _quiz?.id;
    if (quizId != null && token != null) {
      ApiService.joinQuizSession(quizId, token)
          .then((res) {
            if (res['participantCount'] != null) {
              _totalJoined = res['participantCount'] as int;
              _aliveCount = _totalJoined;
            }

            final dataMap = res['data'] as Map<String, dynamic>?;
            final partMap = res['participant'] as Map<String, dynamic>?;
            _sessionId =
                res['sessionId'] as String? ??
                dataMap?['sessionId'] as String? ??
                partMap?['sessionId'] as String? ??
                res['sessionId'] as String?;
            if (_sessionId == null && dataMap?['id'] != null) {
              _sessionId = dataMap?['id'] as String?;
            }

            final dbStatus = (dataMap?['status'] ?? partMap?['status'])
                ?.toString()
                .toUpperCase();

            if (dbStatus == 'FINISHED' || dbStatus == 'DISCONNECTED') {
              _localStatus = QuizSessionStatus.finished;
            } else if (dbStatus == 'PLAYING') {
              _localStatus = QuizSessionStatus.playing;
            }

            notifyListeners();
          })
          .catchError((_) {});
    }

    _connectWebSocket();

    notifyListeners();
    _startLobbyCountdown();
    // دەنگ دوای onHostOpened — نەک لە سەرەکیدا.
  }

  void _disconnectWebSocket() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _wsChannel?.sink.close();
    _wsChannel = null;
  }

  void _connectWebSocket() {
    _disconnectWebSocket();
    final quizId = _quiz?.id;
    final token = SessionController.instance.token;
    if (quizId == null || token == null) return;

    try {
      _wsChannel = ApiService.createQuizWebSocket(quizId, token);
      _wsSubscription = _wsChannel?.stream.listen(
        (message) {
          if (message is String) {
            try {
              final data = jsonDecode(message);
              final type = data['type'] as String?;
              final payload = data['data'] as Map<String, dynamic>?;

              if (payload != null && payload['sessionId'] != null) {
                _sessionId = payload['sessionId'] as String?;
              }

              if (type == 'waiting_room_state' ||
                  type == 'participant_joined' ||
                  type == 'participant_left' ||
                  type == 'PARTICIPANT_STATUS_CHANGED' ||
                  type == 'participant_status_changed') {
                if (payload != null && payload['participantCount'] != null) {
                  _totalJoined = payload['participantCount'] as int;
                  _aliveCount = _totalJoined;
                  _safeNotify();
                }

                // چارەسەری چوونەژوورەوەی درەنگ: ئەگەر کویزەکە لایڤ بوو و پرسیارێک ڕۆشتبوو، یەکسەر دەچینە ناوی
                if (type == 'waiting_room_state' && payload != null) {
                  final status = (payload['sessionStatus']?.toString() ?? '')
                      .toUpperCase();
                  if (status == 'LIVE') {
                    final loopState = payload['loopState']?.toString() ?? '';
                    final cqIndex =
                        payload['currentQuestionIndex'] as int? ?? 0;
                    final endsAtMs = payload['endsAtMs'] as int? ?? 0;
                    final serverNowMs =
                        payload['serverNow'] as int? ??
                        DateTime.now().millisecondsSinceEpoch;

                    final isFirstEntry =
                        _phase == LiveQuizPhase.idle ||
                        _phase == LiveQuizPhase.scheduled;
                    if (isFirstEntry) {
                      final isLate =
                          cqIndex > 0 ||
                          (cqIndex == 0 &&
                              loopState == 'QUESTION' &&
                              serverNowMs >= endsAtMs) ||
                          (cqIndex == 0 && loopState == 'REVEAL');
                      if (isLate) {
                        _localStatus = QuizSessionStatus.finished;
                      } else {
                        _localStatus = QuizSessionStatus.playing;
                      }
                    }

                    final cq =
                        payload['currentQuestion'] as Map<String, dynamic>?;
                    if (cq != null) {
                      final rawIdx = cq['questionIndex'];
                      final int idx = rawIdx is num
                          ? rawIdx.toInt()
                          : (int.tryParse(rawIdx?.toString() ?? '1') ?? 1);
                      final serverIndex = idx - 1;
                      if (_phase != LiveQuizPhase.question ||
                          _questionIndex != serverIndex) {
                        _questionIndex = serverIndex;
                        _startQuestion(
                          fromLobby:
                              _phase == LiveQuizPhase.lobby ||
                              _phase == LiveQuizPhase.idle,
                        );
                      }
                    } else {
                      // ئێمە لە INTRO داین.
                      final rawIntro = payload['introEndAt'];
                      final rawServer = payload['serverNow'];
                      final int? introEndAtMs = rawIntro is num
                          ? rawIntro.toInt()
                          : int.tryParse(rawIntro?.toString() ?? '');
                      final int? serverNowMs = rawServer is num
                          ? rawServer.toInt()
                          : int.tryParse(rawServer?.toString() ?? '');

                      if (introEndAtMs != null && serverNowMs != null) {
                        final remainingSeconds =
                            ((introEndAtMs - serverNowMs) / 1000).ceil();
                        if (remainingSeconds > 0) {
                          if (!_isFinalCountdown) {
                            _isFinalCountdown = true;
                            _finalCountdownSeconds = remainingSeconds.clamp(
                              0,
                              32,
                            );
                            _phase = LiveQuizPhase.lobby;
                            if (_hostAttached && _isReady) _playLobbyAudio();
                            notifyListeners();
                          } else {
                            // گەر پێشتر دەستی پێکردبێت تەنها کاتەکە ڕێک دەخەینەوە
                            _finalCountdownSeconds = remainingSeconds.clamp(
                              0,
                              32,
                            );
                            notifyListeners();
                          }
                        } else {
                          // ئەگەر کاتەکە تەواو بووبوو، یەکسەر دەچینە پرسیار
                          if (!_isFinalCountdown) {
                            _isFinalCountdown = true;
                            _finalCountdownSeconds = 0;
                            _startQuestion(fromLobby: true);
                          }
                        }
                      }
                    }
                  }
                }
              } else if (type == 'session_started' ||
                  type == 'SESSION_STARTED') {
                if (_phase == LiveQuizPhase.idle ||
                    _phase == LiveQuizPhase.scheduled ||
                    _phase == LiveQuizPhase.lobby) {
                  _isFinalCountdown = true;
                  _finalCountdownSeconds = 30;
                  _phase = LiveQuizPhase.lobby;
                  if (_hostAttached && _isReady) {
                    _playLobbyAudio();
                  }
                  notifyListeners();
                }
              } else if (type == 'QUESTION_STARTED' ||
                  type == 'question_started') {
                final idx = payload?['questionIndex'] as int? ?? 1;
                final serverIndex = idx - 1;

                if (_phase != LiveQuizPhase.question ||
                    _questionIndex != serverIndex) {
                  _questionIndex = serverIndex;
                  _startQuestion(
                    fromLobby:
                        _phase == LiveQuizPhase.lobby ||
                        _phase == LiveQuizPhase.idle,
                  );
                }
              } else if (type == 'REVEAL_ANSWER' || type == 'reveal_answer') {
                if (_phase == LiveQuizPhase.question) {
                  _onTimeUp();
                }
              } else if (type == 'quiz_finished' ||
                  type == 'QUIZ_FINISHED' ||
                  type == 'RESULTS_READY' ||
                  type == 'SESSION_FINISHED' ||
                  type == 'session_finished') {
                _finish(realWinners: payload?['winners']);
              }
            } catch (e) {
              debugPrint("Error parsing WS message: $e");
            }
          }
        },
        onError: (e) {
          debugPrint("WS Error: $e");
        },
        onDone: () {
          debugPrint("WS Closed");
        },
      );
    } catch (e) {
      debugPrint("Failed to connect WS: $e");
    }
  }

  void _startLobbyCountdown() {
    _lobbyTick?.cancel();
    _phaseDelay?.cancel();

    void tryStart() {
      if (_phase != LiveQuizPhase.lobby) return;
      final q = _quiz;
      if (q == null) return;

      if (_isFinalCountdown) {
        _finalCountdownSeconds--;
        if (_finalCountdownSeconds <= 2) {
          _lobbyTick?.cancel();
          _isFinalCountdown = false;
          _startQuestion(fromLobby: true);
        }
      } else {
        final left = lobbySecondsLeft;
        if (left <= 30 && left > 0) {
          _isFinalCountdown = true;
          _finalCountdownSeconds = left + 2;
          _playLobbyAudio();
        } else if (left <= 0) {
          _lobbyTick?.cancel();
          _startQuestion(fromLobby: true);
        }
      }
    }

    tryStart();
    _lobbyTick = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
      tryStart();
    });
  }

  void _startQuestion({bool fromLobby = false}) {
    _lobbyTick?.cancel();
    unawaited(_audio.stopLobby());

    final question = currentQuestion;
    if (question == null) {
      _finish();
      return;
    }
    // FIX A: Do NOT eliminate the player based on local _isReady flag.
    // The server has already transitioned them to PLAYING — trust the server.
    // _isReady only reflects whether the user pressed the Ready button in the UI;
    // it is NOT authoritative for gameplay state after SESSION_STARTED.
    _phase = LiveQuizPhase.question;
    // Promote to playing if they were in ready or joined state
    if (_localStatus == QuizSessionStatus.ready ||
        _localStatus == QuizSessionStatus.joined) {
      _localStatus = QuizSessionStatus.playing;
    }
    _selectedOption = null;
    _answered = false;
    _isLastAnswerCorrect = null;
    _passArmed = false;
    _resetOptionVotes();
    _lastAwardedPoints = 0;
    _revealStatsLoaded = false;
    _secondsLeft = question.durationSeconds;

    if (_hostAttached && fromLobby) {
      unawaited(_audio.stopLobby());
      unawaited(_audio.playQuizStart());
      LiveQuizHaptics.quizStart();
    }

    _tick?.cancel();
    if (fromLobby) {
      _tick = Timer(const Duration(seconds: 2), () {
        _startQuestionTick(question);
      });
    } else {
      _startQuestionTick(question);
    }
    notifyListeners();
  }

  void _startQuestionTick(LiveQuestion question) {
    if (_phase != LiveQuizPhase.question) return;

    if (_hostAttached) {
      unawaited(
        _audio.startQuestionTimer(
          remaining: Duration(seconds: _secondsLeft),
          total: Duration(seconds: question.durationSeconds),
          forceRestart: true,
        ),
      );
    }

    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft > 0) {
        _secondsLeft -= 1;
        notifyListeners();

        if (_secondsLeft % 3 == 0) {
          if (_hostAttached && _phase == LiveQuizPhase.question) {
            unawaited(
              _audio.startQuestionTimer(
                remaining: Duration(seconds: _secondsLeft),
                total: Duration(seconds: question.durationSeconds),
              ),
            );
          }
        }

        if (_secondsLeft == 0) {
          _tick?.cancel();
          _onTimeUp();
        }
      }
    });
    notifyListeners();
  }

  void _onTimeUp() {
    _tick?.cancel();
    _secondsLeft = 0;
    if (_hostAttached) {
      unawaited(_audio.stopQuestionTimer());
    }

    final wasActive = _localStatus == QuizSessionStatus.playing;

    // تێپەڕاندن هەڵبژێردرابوو — بێ ئاشکراکردنی وەڵام دەچێتە پرسیاری داهاتوو.
    if (wasActive && _passArmed && !_extraLifeUsedThisQuiz) {
      unawaited(_applyArmedPassAndAdvance());
      return;
    }

    _resolveQuestionEnd(wasActive: wasActive);
  }

  Future<void> _applyArmedPassAndAdvance() async {
    final ok = await ExtraLifeController.instance.consumeLife();
    _passArmed = false;
    if (!ok) {
      // نەیتوانی هەلی زیاتر بەکاربهێنێت — وەک دۆڕاو حیساب دەکرێت.
      _answered = false;
      _selectedOption = null;
      _resolveQuestionEnd(wasActive: true);
      return;
    }

    // ناردنی داوای زیندووکردنەوە (revive) بۆ باکئێند تا ستیتۆسی یاریزان لە داتابەیس ببێتەوە بە PLAYING
    final qId = _quiz?.id;
    if (qId != null) {
      try {
        await ApiService.reviveParticipant(qId, SessionController.instance.token);
        debugPrint('Participant revived successfully on the backend!');
      } catch (e) {
        debugPrint('Failed to revive participant on backend: $e');
      }
    }

    _extraLifeUsedThisQuiz = true;
    _localStatus = QuizSessionStatus.playing;
    _lastAwardedPoints = 0;
    _answered = false;
    _selectedOption = null;

    // لە جیاتی ئەوەی یەکسەر بچێتە پرسیاری داهاتوو، دەچێتە باری ئاشکراکردن (Reveal) بۆ ئەوەی لەگەڵ سێرڤەر هاوکات بێت.
    _phase = LiveQuizPhase.reveal;
    notifyListeners();
  }

  /// کۆتایی پرسیار: وەڵامی هەڵە / نەدان = دۆڕان (بێ دیالۆگی Extra Life).
  void _resolveQuestionEnd({required bool wasActive}) {
    final q = currentQuestion;
    var correct = false;
    _passArmed = false;

    if (wasActive) {
      if (_isLastAnswerCorrect != null) {
        correct = _isLastAnswerCorrect!;
      } else {
        // Fallback: if we have the local correct index, use it. Otherwise, assume correct for now until API returns.
        final localCorrectIndex = q?.correctIndex ?? -1;
        if (localCorrectIndex != -1) {
          correct = _answered && _selectedOption == localCorrectIndex;
        } else {
          correct = _answered;
        }
      }

      if (!correct) {
        _localStatus =
            QuizSessionStatus.finished; // Eliminated on wrong answer or timeout
        // ئەگەر وەڵام نەدرابووەوە و کات تەواو بوو — ناردنی TIMEOUT بۆ باکئێند
        if (!_answered && q != null) {
          final quizId = _quiz?.id;
          final token = SessionController.instance.token;
          if (quizId != null && q.id.isNotEmpty && token != null) {
            ApiService.submitTimeout(
              quizId,
              q.id,
              token,
            ).catchError((_) => <String, dynamic>{});
          }
        }
      }
    }

    if (_hostAttached && wasActive) {
      if (correct) {
        unawaited(_audio.playAnswerCorrect());
      } else {
        unawaited(_audio.playAnswerWrong());
      }
    }

    if (correct && q != null) {
      _lastAwardedPoints = q.points;
    } else {
      _lastAwardedPoints = 0;
    }

    _phase = LiveQuizPhase.reveal;
    notifyListeners();

    // لە جیاتی _simulateOptionVotes داتای ڕاستەقینە لە باکئێند دەهێنین
    _fetchRealRevealStats();
  }

  Future<void> _fetchRealRevealStats() async {
    final quizId = _quiz?.id;
    final qId = currentQuestion?.id;
    final token = SessionController.instance.token;

    if (quizId != null && qId != null && token != null) {
      try {
        final res = await ApiService.revealQuestion(quizId, qId, token);

        final survivors = res['survivors'] as int? ?? 0;
        final stats = res['answerStats'] as List<dynamic>? ?? [];

        _aliveCount = survivors;

        // سفرکردنەوەی دەنگەکان
        _optionVotes = List<int>.filled(4, 0);

        final q = currentQuestion;
        if (q != null) {
          final correctOptionId = res['correctOptionId']?.toString();

          final updatedQuestions = _quiz!.questions.map((questionItem) {
            if (questionItem.id == q.id) {
              final updatedOptions = questionItem.options.map((opt) {
                return QuizOption(
                  id: opt.id,
                  text: opt.text,
                  isCorrect: opt.id == correctOptionId,
                );
              }).toList();

              return LiveQuestion(
                id: questionItem.id,
                text: questionItem.text,
                options: updatedOptions,
                imageUrl: questionItem.imageUrl,
                durationSeconds: questionItem.durationSeconds,
                explanation:
                    questionItem.explanation ?? res['explanation']?.toString(),
                category: questionItem.category,
                points: questionItem.points,
              );
            }
            return questionItem;
          }).toList();

          _quiz = ScheduledQuiz(
            id: _quiz!.id,
            title: _quiz!.title,
            description: _quiz!.description,
            startedAt: _quiz!.startedAt,
            questions: updatedQuestions,
            avatarUrl: _quiz!.avatarUrl,
            sponsors: _quiz!.sponsors,
            rewards: _quiz!.rewards,
          );

          for (final stat in stats) {
            final optId = stat['selectedOptionId'] as String?;
            final count = stat['count'] as int? ?? 0;
            if (optId != null) {
              final idx = currentQuestion!.options.indexWhere(
                (o) => o.id == optId,
              );
              if (idx >= 0 && idx < 4) {
                _optionVotes[idx] = count;
              }
            }
          }
        }
        _revealStatsLoaded = true;
        notifyListeners();
      } catch (e) {
        debugPrint("Failed to fetch reveal stats: $e");
        // لە کاتی کێشەدا سفر دەبێت
        _optionVotes = List<int>.filled(4, 0);
        _revealStatsLoaded = true;
        notifyListeners();
      }
    } else {
      _optionVotes = List<int>.filled(4, 0);
      _revealStatsLoaded = true;
      notifyListeners();
    }

    _scheduleAdvanceAfterReveal();
  }

  void _scheduleAdvanceAfterReveal() {
    _phaseDelay?.cancel();
    final q = _quiz;
    final hasNext = q != null && _questionIndex + 1 < q.questions.length;

    if (!hasNext) {
      // ئەگەر کۆتا پرسیار بوو، ڕاستەوخۆ دوای ١.٥ چرکە دەچینە شاشەی کۆتایی (WinnersView)
      _phaseDelay = Timer(const Duration(milliseconds: 1500), () {
        if (_phase != LiveQuizPhase.finished) {
          _finish();
        }
      });
      return;
    }

    final currentQ = currentQuestion;
    final hasExplanation =
        currentQ != null &&
        currentQ.explanation != null &&
        currentQ.explanation!.trim().isNotEmpty;

    final revealDuration = hasExplanation
        ? const Duration(seconds: 8)
        : const Duration(milliseconds: 1920);

    _phaseDelay = Timer(revealDuration, () {
      if (_phase != LiveQuizPhase.reveal) return;
      if (hasNext && _hostAttached) {
        unawaited(_audio.playNextQuestion());
        LiveQuizHaptics.nextQuestion();
      }

      _questionIndex++;
      _startQuestion(fromLobby: false);
    });
  }

  void _finish({List<dynamic>? realWinners}) {
    _cancelTimers();
    if (_hostAttached) {
      unawaited(_audio.stopQuestionTimer());
      unawaited(_audio.stopLobby());
    }
    _phase = LiveQuizPhase.finished;
    _isLoadingResults = true;

    // Fast local placeholder from WS winners if available
    if (realWinners != null && realWinners.isNotEmpty) {
      try {
        final serverWinners = realWinners.asMap().entries.map((entry) {
          final i = entry.key;
          final w = entry.value as Map<String, dynamic>;
          final rankRaw =
              w['rank'] ?? w['winnerPosition'] ?? w['winner_position'];
          final rank = rankRaw is num
              ? rankRaw.toInt()
              : (int.tryParse(rankRaw?.toString() ?? '') ?? (i + 1));
          final scoreRaw = w['score'];
          final score = scoreRaw is num
              ? scoreRaw.toInt()
              : (scoreRaw != null ? int.tryParse(scoreRaw.toString()) : null);

          return QuizWinner(
            name: (w['username']?.toString()) ??
                (w['userName']?.toString()) ??
                (w['fullName']?.toString()) ??
                (w['name']?.toString()) ??
                (w['full_name']?.toString()) ??
                'یاریزان',
            username: w['username']?.toString(),
            prize: _prizeForRank(rank),
            rank: rank,
            avatarPath: (w['avatarUrl']?.toString()) ??
                (w['avatarKey']?.toString()) ??
                (w['avatar_key']?.toString()) ??
                (w['avatar_url']?.toString()),
            userId: (w['userId']?.toString()) ?? (w['user_id']?.toString()),
            isWinner: _parseIsWinner(w),
            score: score,
          );
        }).toList();
        _winners = serverWinners;
        _savePointsAtQuizEnd(serverWinners);
        notifyListeners();
      } catch (e) {
        debugPrint('Error parsing fast winners from WS: $e');
      }
    }

    // Always fetch full leaderboard from API to get all players and their isWinner status
    final sessionId = _sessionId;
    final quizId = _quiz?.id;
    final token = SessionController.instance.token;

    Future<Map<String, dynamic>>? resultsFuture;
    if (sessionId != null) {
      resultsFuture = ApiService.getSessionResults(sessionId, token);
    } else if (quizId != null) {
      resultsFuture = ApiService.getQuizResults(quizId, token);
    }

    if (resultsFuture != null) {
      resultsFuture
          .then((res) {
            final data = res['data'] ?? res;
            if (data != null) {
              final list =
                  (data['leaderboard'] as List<dynamic>? ??
                      data['winners'] as List<dynamic>?) ??
                  [];
              if (list.isNotEmpty) {
                try {
                  final serverWinners = list.asMap().entries.map((entry) {
                    final i = entry.key;
                    final w = entry.value as Map<String, dynamic>;
                    final rankRaw =
                        w['rank'] ?? w['winnerPosition'] ?? w['winner_position'];
                    final rank = rankRaw is num
                        ? rankRaw.toInt()
                        : (int.tryParse(rankRaw?.toString() ?? '') ?? (i + 1));
                    final scoreRaw = w['score'];
                    final score = scoreRaw is num
                        ? scoreRaw.toInt()
                        : (scoreRaw != null
                              ? int.tryParse(scoreRaw.toString())
                              : null);

                    return QuizWinner(
                      name: (w['username']?.toString()) ??
                          (w['userName']?.toString()) ??
                          (w['fullName']?.toString()) ??
                          (w['name']?.toString()) ??
                          (w['full_name']?.toString()) ??
                          'یاریزان',
                      username: w['username']?.toString(),
                      prize: _prizeForRank(rank),
                      rank: rank,
                      avatarPath: (w['avatarUrl']?.toString()) ??
                          (w['avatarKey']?.toString()) ??
                          (w['avatar_key']?.toString()) ??
                          (w['avatar_url']?.toString()),
                      userId: (w['userId']?.toString()) ?? (w['user_id']?.toString()),
                      isWinner: _parseIsWinner(w),
                      score: score,
                    );
                  }).toList();
                  _winners = serverWinners;
                  _lastWinners = List.of(serverWinners.where((w) => w.isWinner));
                  _lastWinnersQuizTitle = _quiz?.title;
                  _lastWinnersEndedAt = DateTime.now().toUtc();
                  _scheduleLastWinnersExpiry();
                  _savePointsAtQuizEnd(serverWinners);
                  if (_hostAttached &&
                      _localStatus == QuizSessionStatus.playing) {
                    unawaited(_audio.playWinners());
                  }
                } catch (e) {
                  debugPrint('Error parsing winners from API: $e');
                }
              }
            }
          })
          .catchError((e) {
            debugPrint("Failed to fetch quiz results: $e");
          })
          .whenComplete(() {
            _isLoadingResults = false;
            notifyListeners();
          });
    } else {
      _isLoadingResults = false;
      notifyListeners();
    }
  }

  /// خەڵاتی هەر پلە — دواتر لە باک ئێند / ئەدمین دێت.
  static String _prizeForRank(int rank) {
    final activeQuiz = instance._quiz;
    if (activeQuiz != null) {
      for (final reward in activeQuiz.rewards) {
        final rRank =
            reward['rank'] as int? ?? reward['winnerPosition'] as int?;
        if (rRank == rank) {
          final amt = reward['amount'] as num?;
          if (amt != null) {
            final currency = reward['currency'] as String? ?? 'IQD';
            if (currency.toUpperCase() == 'USD') {
              return '\$${amt.toStringAsFixed(0)}';
            }
            return KurdishFormat.moneyIqd(amt.toInt());
          }
        }
      }
    }
    switch (rank) {
      case 1:
        return KurdishFormat.moneyIqd(1000000);
      case 2:
        return KurdishFormat.moneyIqd(500000);
      case 3:
        return KurdishFormat.moneyIqd(250000);
      default:
        return KurdishFormat.moneyIqd(50000);
    }
  }

  void _cancelTimers() {
    _tick?.cancel();
    _tick = null;
    _phaseDelay?.cancel();
    _phaseDelay = null;
    _lobbyTick?.cancel();
    _lobbyTick = null;
  }

  void _savePointsAtQuizEnd(List<QuizWinner> serverWinners) {
    if (_pointsSavedForThisSession) return;
    final me = SessionController.instance.user;
    if (me != null) {
      QuizWinner? myWinner;
      for (final w in serverWinners) {
        if ((w.userId != null && w.userId == me.id) ||
            (w.username != null && w.username == me.username)) {
          myWinner = w;
          break;
        }
      }
      if (myWinner != null && myWinner.score != null && myWinner.score! > 0) {
        _pointsSavedForThisSession = true;
        unawaited(SessionController.instance.addPoints(myWinner.score!));
      }
    }
  }

  bool _parseIsWinner(Map<String, dynamic> w) {
    debugPrint('[parseIsWinner] Keys: ${w.keys.toList()} | isWinner: ${w['isWinner']} | is_winner: ${w['is_winner']} | winnerPosition: ${w['winnerPosition']} | winner_position: ${w['winner_position']}');
    final val = w['isWinner'] ?? w['is_winner'];
    if (val == null) {
      return w['winnerPosition'] != null || w['winner_position'] != null;
    }
    if (val is bool) return val;
    if (val is num) return val == 1;
    final s = val.toString().trim().toLowerCase();
    return s == 'true' || s == '1';
  }

  void _resetOptionVotes() {
    _optionVotes = const [0, 0, 0, 0];
  }

  @override
  void dispose() {
    _cancelTimers();
    _scheduleWatch?.cancel();
    _disconnectWebSocket();
    unawaited(_audio.stopAll());
    super.dispose();
  }
}
