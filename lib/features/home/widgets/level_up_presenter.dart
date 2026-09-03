import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/session/session_controller.dart';
import '../../live_quiz/live_quiz_audio.dart';
import 'level_up_dialog.dart';

/// نیشاندانی ئاماژەی بەرزبوونەوەی لیڤڵ — یەکجار، دوای گەڕانەوە بۆ سەرەکی.
abstract final class LevelUpPresenter {
  static bool _busy = false;

  static Future<void> presentIfPending(BuildContext context) async {
    if (_busy || !context.mounted) return;

    final pending = SessionController.instance.consumePendingLevelUp();
    if (pending == null) return;

    _busy = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 280));
      if (!context.mounted) return;
      unawaited(LiveQuizAudio.instance.playLevelUp());
      await showLevelUpDialog(
        context,
        fromLevel: pending.from,
        toLevel: pending.to,
      );
    } finally {
      _busy = false;
    }
  }

  /// تاقیکردنەوە — بەبێ گۆڕینی خاڵەکان ئاماژەکە نیشان بدە.
  static Future<void> preview(
    BuildContext context, {
    int? fromLevel,
    int? toLevel,
  }) async {
    if (_busy || !context.mounted) return;
    _busy = true;
    try {
      final current = SessionController.instance.level;
      final to = toLevel ?? (current + 1).clamp(1, 13);
      final from = fromLevel ?? current;
      unawaited(LiveQuizAudio.instance.playLevelUp());
      await showLevelUpDialog(
        context,
        fromLevel: from,
        toLevel: to,
      );
    } finally {
      _busy = false;
    }
  }
}
