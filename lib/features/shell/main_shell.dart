import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/routing/transitions.dart';
import '../../core/services/live_quiz_access_guard.dart';
import '../../core/session/session_controller.dart';
import '../account/account_screen.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';
import '../home/widgets/level_up_presenter.dart';
import '../live_quiz/live_quiz_controller.dart';
import '../live_quiz/live_quiz_host_screen.dart';
import 'widgets/barav_nav_bar.dart';

/// چوارچێوەی سەرەکی — یوزەر: سەرەکی+هەژمار | ئەدمین: داشبۆرد+هەژمار.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final PageController _pageController = PageController();
  int _index = 0;
  bool _openingQuiz = false;

  List<BaravNavItem> get _items {
    return [
      BaravNavItem(
        label: AppStrings.tabHome,
        icon: Icons.grid_view_rounded,
        activeIcon: Icons.dashboard_rounded,
      ),
      BaravNavItem(
        label: AppStrings.tabAccount,
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
      ),
    ];
  }

  List<Widget> get _pages {
    return const [HomeScreen(), AccountScreen()];
  }

  @override
  void initState() {
    super.initState();
    SessionController.instance.addListener(_onSessionChanged);
    LiveQuizController.instance.addListener(_onQuizChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onQuizChanged());
  }

  @override
  void dispose() {
    SessionController.instance.removeListener(_onSessionChanged);
    LiveQuizController.instance.removeListener(_onQuizChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (!SessionController.instance.isLoggedIn && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        fadeRoute(const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _onQuizChanged() {
    final c = LiveQuizController.instance;
    if (!mounted) return;
    if (!c.hostOpenRequested || _openingQuiz) return;
    if (!c.isLivePhase) return;

    _openingQuiz = true;
    c.acknowledgeHostOpened();
    unawaited(() async {
      final allowed = await guardLiveQuizAccess(context);
      if (!mounted) return;
      if (!allowed) {
        _openingQuiz = false;
        return;
      }
      await Navigator.of(context).push(fadeRoute(const LiveQuizHostScreen()));
      if (!mounted) return;
      _openingQuiz = false;
      unawaited(LevelUpPresenter.presentIfPending(context));
    }());
  }

  void _select(int index) {
    if (_index == index) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _index = index),
        physics: const BouncingScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: BaravNavBar(
        items: _items,
        currentIndex: _index,
        onChanged: _select,
      ),
    );
  }
}
