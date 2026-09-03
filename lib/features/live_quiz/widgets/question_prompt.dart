import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/live_quiz_models.dart';

class QuestionPrompt extends StatelessWidget {
  const QuestionPrompt({
    super.key,
    required this.question,
    this.compact = false,
  });

  final LiveQuestion question;
  final bool compact;

  bool get _isNetwork {
    final url = question.imageUrl?.trim() ?? '';
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    if (!question.hasImage) {
      return Text(
        question.text,
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: colors.ink,
          height: 1.35,
          fontSize: 20,
        ),
      );
    }

    final imageHeight = compact ? 80.0 : 120.0;
    final imageWidth = compact ? 120.0 : 180.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: SizedBox(
            width: imageWidth,
            height: imageHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.stroke),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ColoredBox(
                  color: colors.surfaceHigh,
                  child: _isNetwork
                      ? CachedNetworkImage(
                          imageUrl: question.imageUrl!.trim(),
                          fit: BoxFit.cover,
                          height: imageHeight,
                          errorWidget: (context, url, error) =>
                              const QuestionImageFallback(),
                          placeholder: (context, url) =>
                              const QuestionImageFallback(loading: true),
                        )
                      : Image.file(
                          File(question.imageUrl!.trim()),
                          fit: BoxFit.cover,

                          height: imageHeight,
                          errorBuilder: (_, _, _) =>
                              const QuestionImageFallback(),
                        ),
                ),
              ),
            ),
          ),
        ),
        if (question.hasText) ...[
          const SizedBox(height: 10),
          Text(
            question.text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              height: 1.3,
              color: colors.ink,
            ),
          ),
        ],
      ],
    );
  }
}

class QuestionImageFallback extends StatelessWidget {
  const QuestionImageFallback({super.key, this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: loading
          ? const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          : Icon(
              Icons.image_not_supported_outlined,
              size: 36,
              color: AppColors.of(context).textMuted,
            ),
    );
  }
}
