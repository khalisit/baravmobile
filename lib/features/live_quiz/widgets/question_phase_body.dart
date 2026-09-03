import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/live_quiz_models.dart';
import 'question_prompt.dart';

class QuestionPhaseBody extends StatelessWidget {
  const QuestionPhaseBody({
    super.key,
    required this.question,
    required this.revealing,
    required this.spectating,
    required this.totalSeconds,
    required this.selectedOption,
    required this.buildOptionTile,
    required this.enterAnimation,
  });

  final LiveQuestion question;
  final bool revealing;
  final bool spectating;
  final int totalSeconds;
  final int? selectedOption;
  final Widget Function({
    required BuildContext context,
    required ThemeData theme,
    required AppColors colors,
    required int index,
    required QuizOption opt,
    required bool selected,
    required bool revealing,
    required bool spectating,
  })
  buildOptionTile;
  final Animation<double> enterAnimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    final promptFade = CurvedAnimation(
      parent: enterAnimation,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    final promptSlide =
        Tween<Offset>(begin: const Offset(0.0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: enterAnimation,
            curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Fixed Question Prompt at the top
        FadeTransition(
          opacity: promptFade,
          child: SlideTransition(
            position: promptSlide,
            child: question.hasImage
                ? QuestionPrompt(question: question, compact: false)
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      question.text,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                        height: 1.3,
                        fontSize: 20,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 14),

        // 2. Scrollable Options and Explanation
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 6),
            physics: const BouncingScrollPhysics(),
            children: [
              for (var i = 0; i < question.options.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                () {
                  final double start = (0.2 + (i * 0.08)).clamp(0.0, 0.9);
                  final double end = (start + 0.35).clamp(0.0, 1.0);
                  final optFade = CurvedAnimation(
                    parent: enterAnimation,
                    curve: Interval(start, end, curve: Curves.easeOut),
                  );
                  final optSlide =
                      Tween<Offset>(
                        begin: const Offset(0.0, 0.25),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: enterAnimation,
                          curve: Interval(
                            start,
                            end,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                      );

                  return FadeTransition(
                    opacity: optFade,
                    child: SlideTransition(
                      position: optSlide,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          height: 64, // Same height for all options
                          width: double.infinity,
                          child: buildOptionTile(
                            context: context,
                            theme: theme,
                            colors: colors,
                            index: i,
                            opt: question.options[i],
                            selected: selectedOption == i,
                            revealing: revealing,
                            spectating: spectating,
                          ),
                        ),
                      ),
                    ),
                  );
                }(),
              ],

              // 3. Explanation in the scrollable list
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 320),
                firstCurve: Curves.easeIn,
                secondCurve: Curves.easeOutCubic,
                crossFadeState:
                    revealing &&
                        question.explanation != null &&
                        question.explanation!.trim().isNotEmpty
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(width: double.infinity, height: 0),
                secondChild: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: _buildExplanation(context),
                ),
              ),

              // 4. Next Question Status
              AnimatedOpacity(
                opacity: revealing ? 1 : 0,
                duration: const Duration(milliseconds: 280),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(
                    AppStrings.nextQuestionSoon,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExplanation(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    final explanationText = question.explanation?.trim() ?? '';
    if (explanationText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.stroke, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.purpleLight,
                ),
                const SizedBox(width: 6),
                Text(
                  'ڕوونکردنەوەی وەڵام',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.purpleLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              explanationText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.ink,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
