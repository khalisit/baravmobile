import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/animation/fade_slide_in.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock_data.dart';
import '../../core/widgets/glow_backdrop.dart';
import '../../core/routing/transitions.dart';
import '../auth/login_screen.dart';
import '../live_quiz/live_quiz_controller.dart';
import '../live_quiz/live_quiz_host_screen.dart';
import '../../core/services/live_quiz_access_guard.dart';
import 'notifications_screen.dart';
import 'widgets/ad_carousel.dart';
import 'widgets/extra_life_header_button.dart';
import 'widgets/last_winners_card.dart';
// import 'widgets/level_up_presenter.dart';
import 'widgets/quiz_data_card.dart';
import '../../data/api_service.dart';
import '../../data/models.dart';
import '../../data/live_quiz_models.dart';
import '../../core/services/presence_service.dart';
import '../../core/services/push_notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static List<QuizData>? _cachedQuizzes;
  static List<AdItem>? _cachedAds;

  List<QuizData>? _quizzes = _cachedQuizzes;
  List<AdItem> _homeAds = _cachedAds ?? MockData.ads;
  bool _isLoading = _cachedQuizzes == null;
  String? _error;
  Timer? _pollingTimer;
  StreamSubscription<String?>? _tapSub;

  @override
  void initState() {
    super.initState();
    _fetchInitial();
    unawaited(_fetchHomeSponsors());
    unawaited(LiveQuizController.instance.fetchLastWinners());

    // Auto-refresh every 22 seconds for real-time status updates
    _pollingTimer = Timer.periodic(const Duration(seconds: 22), (_) {
      _silentRefresh();
    });

    _tapSub = PushNotificationService.instance.onNotificationTapped.listen((payload) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialPayload = PushNotificationService.instance.consumeInitialPayload();
      if (initialPayload != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tapSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchInitial() async {
    final token = SessionController.instance.token;
    if (token == null) return;
    try {
      final quizzes = await ApiService.getQuizzes(token);
      _cachedQuizzes = quizzes;
      if (mounted) {
        setState(() {
          _quizzes = quizzes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          if (_quizzes == null) _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchHomeSponsors() async {
    try {
      final sponsorsList = await ApiService.getSponsors(type: 'home');
      if (mounted) {
        final mapped = sponsorsList.map((s) {
          final name = (s['name'] ?? '').toString();
          final link = (s['link'] ?? '').toString();
          final imageUrl = (s['imageUrl'] ?? s['image_url']) as String?;
          final videoUrl = (s['videoUrl'] ?? s['video_url']) as String?;
          final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
          final media = hasVideo ? videoUrl : (imageUrl ?? '');
          final fullMediaUrl = media.startsWith('http')
              ? media
              : '${ApiService.baseUrl.replaceAll('/api', '')}/media/${media.replaceFirst(RegExp(r'^/'), '')}';

          return AdItem(
            title: name.isNotEmpty ? name : 'BARAV QUIZ',
            subtitle: link.isNotEmpty ? link : '',
            kind: hasVideo ? AdKind.video : AdKind.image,
            tint: [AppColors.purple, AppColors.purpleLight],
            mediaUrl: fullMediaUrl,
          );
        }).toList();

        final oldUrls = _homeAds.map((ad) => ad.mediaUrl).join(',');
        final newUrls = mapped.map((ad) => ad.mediaUrl).join(',');
        if (oldUrls != newUrls || _homeAds.length != mapped.length) {
          _cachedAds = mapped;
          setState(() {
            _homeAds = mapped;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _silentRefresh() async {
    try {
      await _fetchHomeSponsors();
    } catch (_) {}

    final token = SessionController.instance.token;
    if (token == null) return;
    try {
      final newQuizzes = await ApiService.getQuizzes(token);
      _cachedQuizzes = newQuizzes;
      await LiveQuizController.instance.fetchLastWinners();
      if (mounted) {
        setState(() {
          _quizzes = newQuizzes;
          _error = null;
        });
      }
    } catch (_) {}
  }

  Future<void> _refreshData(BuildContext context) async {
    final token = SessionController.instance.token;
    final refreshFuture = SessionController.instance.refreshSession();
    final quizzesFuture = ApiService.getQuizzes(token);
    final lastWinnersFuture = LiveQuizController.instance.fetchLastWinners();
    final homeSponsorsFuture = _fetchHomeSponsors();

    final results = await Future.wait([
      refreshFuture,
      quizzesFuture,
      lastWinnersFuture,
      homeSponsorsFuture,
    ]);
    final success = results[0] as bool;
    if (!success && context.mounted) {
      Navigator.of(
        context,
      ).pushAndRemoveUntil(fadeRoute(const LoginScreen()), (route) => false);
    } else if (mounted) {
      final newQuizzes = results[1] as List<QuizData>;
      _cachedQuizzes = newQuizzes;
      setState(() {
        _quizzes = newQuizzes;
        _error = null;
      });
    }
  }

  Future<void> _joinQuiz(QuizData quiz) async {
    final allowed = await guardLiveQuizAccess(context);
    if (!allowed || !mounted) return;

    final token = SessionController.instance.token;
    if (token == null) return;

    try {
      await ApiService.joinQuizSession(quiz.id, token);

      if (!mounted) return;
      setState(() {
        if (_quizzes != null) {
          _quizzes = _quizzes!.map((q) {
            if (q.id == quiz.id) {
              return q.copyWith(
                isJoined: true,
                participantStatus: 'JOINED',
                participantCount: q.participantCount + 1,
              );
            }
            return q;
          }).toList();
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _setQuizReady(QuizData quiz) async {
    final token = SessionController.instance.token;
    if (token == null) return;

    try {
      await ApiService.setQuizReady(quiz.id, token);

      if (!mounted) return;
      setState(() {
        if (_quizzes != null) {
          _quizzes = _quizzes!.map((q) {
            if (q.id == quiz.id) {
              return q.copyWith(participantStatus: 'READY');
            }
            return q;
          }).toList();
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _enterQuiz(QuizData quiz) async {
    final token = SessionController.instance.token;
    if (token == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final c = LiveQuizController.instance;
      await c.initializeWithQuiz(quiz, token: token);

      if (!mounted) return;
      Navigator.of(context).pop(); // close loading dialog

      if (!c.isReady) c.markReady();
      if (c.phase == LiveQuizPhase.scheduled) c.checkSchedule();

      Navigator.of(context).push(fadeRoute(const LiveQuizHostScreen())).then((
        _,
      ) {
        if (mounted) _refreshData(context);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        c.onHostOpened();
      });
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
    LocaleScope.of(context);
    final session = SessionController.instance;
    final quizController = LiveQuizController.instance;

    return GlowBackdrop(
      intensity: 0.55,
      child: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([quizController, session]),
          builder: (context, _) {
            final theme = Theme.of(context);
            final endedAt = quizController.lastWinnersEndedAt;
            final nowUtc = DateTime.now().toUtc();
            bool isWithin2Minutes = false;
            if (endedAt != null) {
              final elapsedSeconds = nowUtc
                  .difference(endedAt.toUtc())
                  .inSeconds;
              isWithin2Minutes = elapsedSeconds >= -30 && elapsedSeconds < 120;
            }
            final hasWinners =
                quizController.lastWinners.isNotEmpty && isWithin2Minutes;
            return RefreshIndicator(
              onRefresh: () => _refreshData(context),
              child: Builder(
                builder: (context) {
                  return ListView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 110),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: FadeSlideIn(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Text(
                                        (session.user?.username ?? '...').toLowerCase(),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              height: 1.1,
                                              fontSize: 16,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    const _PresenceCounter(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const ExtraLifeHeaderButton(),
                              const SizedBox(width: 6),
                              const _NotificationsButton(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 80),
                        child: AdCarousel(ads: _homeAds),
                      ),
                      if (hasWinners) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: FadeSlideIn(
                            delay: const Duration(milliseconds: 200),
                            child: const LastWinnersCard(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_error != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'هەڵەیەک ڕوویدا لە هێنانی کویزەکان',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        )
                      else if (_quizzes == null || _quizzes!.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'هیچ کویزێک نییە',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.brightness == Brightness.dark
                                    ? const Color(0xFFA0A0AB)
                                    : const Color(0xFF71717A),
                              ),
                            ),
                          ),
                        )
                      else ...[
                        ...() {
                          final allQuizzes = _quizzes!;
                          final activeQuizzes = allQuizzes
                              .where(
                                (q) =>
                                    q.status != 'ARCHIVED' &&
                                    q.status != 'archived' &&
                                    q.status != 'DRAFT' &&
                                    q.status != 'draft' &&
                                    (q.sessionStatus == null ||
                                        q.sessionStatus?.toUpperCase() ==
                                            'WAITING' ||
                                        q.sessionStatus?.toUpperCase() ==
                                            'LIVE'),
                              )
                              .toList();

                          final finishedQuizzes = allQuizzes
                              .where(
                                (q) =>
                                    q.status != 'ARCHIVED' &&
                                    q.status != 'archived' &&
                                    q.status != 'DRAFT' &&
                                    q.status != 'draft' &&
                                    q.sessionStatus?.toUpperCase() ==
                                        'FINISHED',
                              )
                              .toList();

                          if (activeQuizzes.isEmpty &&
                              finishedQuizzes.isEmpty) {
                            return [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'هیچ کویزێک ئامادە نییە',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.brightness == Brightness.dark
                                          ? const Color(0xFFA0A0AB)
                                          : const Color(0xFF71717A),
                                    ),
                                  ),
                                ),
                              ),
                            ];
                          }

                          final now = DateTime.now().toUtc();
                          final soonQuizzes = <QuizData>[];
                          final otherQuizzes = <QuizData>[];

                          for (final q in activeQuizzes) {
                            final isLive =
                                q.sessionStatus?.toUpperCase() == 'LIVE';
                            if (isLive ||
                                (q.scheduledAt != null &&
                                    q.scheduledAt!
                                            .toUtc()
                                            .difference(now)
                                            .inSeconds <=
                                        1800)) {
                              soonQuizzes.add(q);
                            } else {
                              otherQuizzes.add(q);
                            }
                          }

                          final widgets = <Widget>[];

                          // بەشی کویزێک کە لە ۳۰ خولەک کەمترە یان ڕاستەوخۆ دەستی پێکردووە
                          if (soonQuizzes.isNotEmpty) {
                            widgets.add(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: FadeSlideIn(
                                  delay: const Duration(milliseconds: 150),
                                  child: Text(
                                    'ئەم کویزە بەم نزیکانە دەست پێدەکات',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            );
                            widgets.add(const SizedBox(height: 12));
                            for (var i = 0; i < soonQuizzes.length; i++) {
                              final quiz = soonQuizzes[i];
                              widgets.add(
                                FadeSlideIn(
                                  delay: Duration(milliseconds: 200 + (i * 50)),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 12,
                                      left: 20,
                                      right: 20,
                                    ),
                                    child: QuizDataCard(
                                      quiz: quiz,
                                      onJoin: () => _joinQuiz(quiz),
                                      onEnter: () => _enterQuiz(quiz),
                                      onReady: () => _setQuizReady(quiz),
                                    ),
                                  ),
                                ),
                              );
                            }
                            if (otherQuizzes.isNotEmpty ||
                                finishedQuizzes.isNotEmpty) {
                              widgets.add(const SizedBox(height: 12));
                            }
                          }

                          // بەشی لیستی کویزەکان (ئەوانەی زیاتر لە ۳۰ خولەکیان ماوە)
                          if (otherQuizzes.isNotEmpty) {
                            widgets.add(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: FadeSlideIn(
                                  delay: const Duration(milliseconds: 250),
                                  child: Text(
                                    'لیستی کویزەکان',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            );
                            widgets.add(const SizedBox(height: 12));
                            for (var i = 0; i < otherQuizzes.length; i++) {
                              final quiz = otherQuizzes[i];
                              widgets.add(
                                FadeSlideIn(
                                  delay: Duration(milliseconds: 300 + (i * 50)),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 12,
                                      left: 20,
                                      right: 20,
                                    ),
                                    child: QuizDataCard(
                                      quiz: quiz,
                                      onJoin: () => _joinQuiz(quiz),
                                      onEnter: () => _enterQuiz(quiz),
                                      onReady: () => _setQuizReady(quiz),
                                    ),
                                  ),
                                ),
                              );
                            }
                            if (finishedQuizzes.isNotEmpty) {
                              widgets.add(const SizedBox(height: 12));
                            }
                          }

                          // بەشی کویزە تەواوبووەکان (Finished Quizzes)
                          if (finishedQuizzes.isNotEmpty) {
                            widgets.add(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: FadeSlideIn(
                                  delay: const Duration(milliseconds: 350),
                                  child: Text(
                                    'کویزە تەواوبووەکان',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            );
                            widgets.add(const SizedBox(height: 12));
                            for (var i = 0; i < finishedQuizzes.length; i++) {
                              final quiz = finishedQuizzes[i];
                              widgets.add(
                                FadeSlideIn(
                                  delay: Duration(milliseconds: 400 + (i * 50)),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 12,
                                      left: 20,
                                      right: 20,
                                    ),
                                    child: QuizDataCard(quiz: quiz),
                                  ),
                                ),
                              );
                            }
                          }

                          return widgets;
                        }(),
                      ],
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationsButton extends StatefulWidget {
  const _NotificationsButton();

  @override
  State<_NotificationsButton> createState() => _NotificationsButtonState();
}

class _NotificationsButtonState extends State<_NotificationsButton> {
  int _unreadCount = 0;
  bool _isLoading = true;
  StreamSubscription<void>? _notificationSub;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    _notificationSub = PushNotificationService.instance.onMessageReceived.listen((_) {
      _fetchUnreadCount();
    });
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    final session = SessionController.instance;
    if (session.user == null || session.token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final notifs = await ApiService.getNotifications(
        session.user!.id,
        session.token,
      );
      final unread = notifs.where((n) => !n.read).length;
      if (mounted) {
        setState(() {
          _unreadCount = unread;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await Navigator.of(
              context,
            ).push(softRoute(const NotificationsScreen()));
            // Refresh on return in case they read some
            _fetchUnreadCount();
          },
          borderRadius: BorderRadius.circular(14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.stroke),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 22,
                  color: colors.ink,
                ),
                if (!_isLoading && _unreadCount > 0)
                  PositionedDirectional(
                    top: 9,
                    end: 10,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 1.2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PresenceCounter extends StatelessWidget {
  const _PresenceCounter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<int>(
      valueListenable: PresenceService.instance.onlineCount,
      builder: (context, count, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success,
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count لەخەتە',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFFA0A0AB)
                    : const Color(0xFF71717A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}
