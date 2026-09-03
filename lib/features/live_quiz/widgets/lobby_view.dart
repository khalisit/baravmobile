import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/api_service.dart';
import '../live_quiz_controller.dart';
import 'live_quiz_sponsor_banner.dart';

class LobbyView extends StatefulWidget {
  const LobbyView({super.key});

  @override
  State<LobbyView> createState() => _LobbyViewState();
}

class _LobbyViewState extends State<LobbyView>
    with SingleTickerProviderStateMixin {
  final _quiz = LiveQuizController.instance;

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String _resolveImageUrl(String path) {
    if (path.startsWith('http')) return path;
    final cleanPath = path.replaceFirst(RegExp(r'^/'), '');
    return '${ApiService.baseUrl.replaceAll('/api', '')}/media/$cleanPath';
  }

  Widget _buildFallbackIcon() {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.96,
        end: 1.04,
      ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
      child: Container(
        width: 88,
        height: 88,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.purpleGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.42),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Icon(Icons.emoji_events, color: Colors.white, size: 38),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds < 60) return totalSeconds.toString();
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return ListenableBuilder(
      listenable: _quiz,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              if (_quiz.quiz case final quiz? when quiz.hasSponsors) ...[
                LiveQuizSponsorBanner(sponsors: quiz.sponsors),
                const SizedBox(height: 24),
              ],

              if (_quiz.quiz?.avatarUrl != null &&
                  _quiz.quiz!.avatarUrl!.isNotEmpty)
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _resolveImageUrl(_quiz.quiz!.avatarUrl!),
                      fit: BoxFit.cover,
                      errorWidget: (context, error, stackTrace) =>
                          _buildFallbackIcon(),
                      placeholder: (context, url) => _buildFallbackIcon(),
                    ),
                  ),
                )
              else
                _buildFallbackIcon(),
              const SizedBox(height: 24),

              Text(
                _quiz.quiz?.title ?? AppStrings.nextQuiz,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
              if (_quiz.quiz?.description != null &&
                  _quiz.quiz!.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _quiz.quiz!.description!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textMuted,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              AnimatedBuilder(
                animation: _quiz,
                builder: (context, _) {
                  final seconds = _quiz.lobbySecondsLeft;
                  final isFinal = _quiz.isFinalCountdown;
                  final progress = isFinal
                      ? (seconds / 30.0).clamp(0.0, 1.0)
                      : 1.0;
                  final urgent = isFinal && seconds <= 5;
                  final timeStr = _formatTime(seconds);

                  return SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 8,
                            strokeCap: StrokeCap.round,
                            backgroundColor: colors.stroke,
                            color: urgent
                                ? AppColors.danger
                                : AppColors.purpleLight,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppStrings.lobbyStartsIn,
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: Tween<double>(begin: 0.72, end: 1)
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
                              child: Text(
                                timeStr,
                                key: ValueKey(timeStr),
                                style: theme.textTheme.displaySmall?.copyWith(
                                  color: urgent
                                      ? AppColors.danger
                                      : AppColors.purpleLight,
                                  fontWeight: FontWeight.w700,
                                  height: 1.05,
                                ),
                              ),
                            ),
                            if (seconds < 60)
                              Text(
                                AppStrings.seconds,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_alt_rounded,
                      size: 18,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${AppStrings.playersJoined}: ${_quiz.totalJoined}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                AppStrings.quizLobbyHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textMuted,
                ),
              ),
              const Spacer(),
            ],
          ),
        );
      },
    );
  }
}
