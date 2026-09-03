import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

enum _BedKind { none, lobby, timer }

/// بزوێنەری دەنگی کویزی زیندوو — bed (تایمەر) + SFX جیاواز، تێکەڵ دەبن.
class LiveQuizAudio with WidgetsBindingObserver {
  LiveQuizAudio._();

  static final LiveQuizAudio instance = LiveQuizAudio._();

  static const _lobbyAsset = 'sounds/30second_tick.mp3';
  static const _timerAsset = 'sounds/timer_tick.mp3';
  static const _quizStartAsset = 'sounds/quiz_start.mp3';
  static const _correctAsset = 'sounds/answer_correct.mp3';
  static const _wrongAsset = 'sounds/answer_wrong.mp3';
  static const _nextAsset = 'sounds/next_question.mp3';
  static const _winnersAsset = 'sounds/winners.mp3';
  static const _levelUpAsset = 'sounds/level_up.mp3';

  final AudioCache _cache = AudioCache(prefix: 'assets/');

  AudioPlayer? _bed;
  AudioPlayer? _sfx;

  Completer<void>? _initCompleter;
  Future<void> _queue = Future<void>.value();
  bool _observingLifecycle = false;

  _BedKind _bedKind = _BedKind.none;
  int _bedGeneration = 0;

  bool get isLobbyPlaying =>
      _bedKind == _BedKind.lobby && _bed?.state == PlayerState.playing;

  bool get isTimerPlaying =>
      _bedKind == _BedKind.timer && _bed?.state == PlayerState.playing;

  /// هەمان کۆنتێکست بۆ bed و SFX — تێکەڵبوون، بێ بێدەنگکردنی یەکتر.
  AudioContext get _sharedCtx => AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
      );

  void _ensureLifecycleObserver() {
    if (_observingLifecycle) return;
    _observingLifecycle = true;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(recover());
    } else if (state == AppLifecycleState.paused) {
      unawaited(stopAll());
    }
  }

  Future<void> _ensureReady() {
    final existing = _initCompleter;
    if (existing != null) return existing.future;

    final c = Completer<void>();
    _initCompleter = c;
    () async {
      try {
        await _configure();
        if (!c.isCompleted) c.complete();
      } catch (e) {
        _initCompleter = null;
        if (!c.isCompleted) c.completeError(e);
      }
    }();
    return c.future;
  }

  Future<void> _configure() async {
    _ensureLifecycleObserver();
    await AudioPlayer.global.setAudioContext(_sharedCtx);
    await _recreatePlayers();
    try {
      await _cache.loadAll(const [
        _lobbyAsset,
        _quizStartAsset,
        _timerAsset,
        _correctAsset,
        _wrongAsset,
        _nextAsset,
        _winnersAsset,
        _levelUpAsset,
      ]);
    } catch (_) {}
  }

  Future<void> _recreatePlayers() async {
    _bedKind = _BedKind.none;
    _bedGeneration++;

    final oldBed = _bed;
    final oldSfx = _sfx;
    _bed = null;
    _sfx = null;

    for (final p in [oldBed, oldSfx]) {
      if (p == null) continue;
      try {
        await p.stop();
      } catch (_) {}
      try {
        await p.dispose();
      } catch (_) {}
    }

    final bed = AudioPlayer()..audioCache = _cache;
    final sfx = AudioPlayer()..audioCache = _cache;

    await bed.setAudioContext(_sharedCtx);
    await bed.setReleaseMode(ReleaseMode.loop);
    await bed.setPlayerMode(PlayerMode.mediaPlayer);
    await bed.setVolume(1);

    await sfx.setAudioContext(_sharedCtx);
    await sfx.setReleaseMode(ReleaseMode.stop);
    await sfx.setPlayerMode(PlayerMode.lowLatency);
    await sfx.setVolume(1);

    _bed = bed;
    _sfx = sfx;
  }

  Future<void> warmUp() async {
    try {
      await _ensureReady();
    } catch (_) {
      await recover();
    }
  }

  Future<void> recover() async {
    _initCompleter = null;
    try {
      await _configure();
    } catch (_) {}
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _queue.then((_) async {
      try {
        await _ensureReady();
        await action();
      } catch (_) {
        try {
          await recover();
          await action();
        } catch (_) {}
      }
    });
    _queue = next.catchError((_) {});
    return next;
  }

  Future<void> _stopBedUnlocked() async {
    _bedKind = _BedKind.none;
    _bedGeneration++;
    final bed = _bed;
    if (bed == null) return;
    try {
      await bed.stop();
    } catch (_) {}
  }

  Future<bool> _playBedAsset(
    AudioPlayer player,
    String asset, {
    Duration position = Duration.zero,
  }) async {
    try {
      await player.stop();
    } catch (_) {}

    try {
      if (position > Duration.zero) {
        await player.setSource(AssetSource(asset));
        await player.seek(position);
        await player.resume();
      } else {
        await player.play(AssetSource(asset), volume: 1);
      }
      await Future<void>.delayed(const Duration(milliseconds: 60));
      if (player.state == PlayerState.playing) return true;

      await player.play(AssetSource(asset), volume: 1);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      return player.state == PlayerState.playing;
    } catch (_) {
      try {
        await player.play(AssetSource(asset), volume: 1);
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  /// SFX: تەنها play — پشکنینی state نا، چونکە دەنگی کورت هەڵە دەدات.
  Future<void> _playSfxAsset(AudioPlayer player, String asset) async {
    try {
      await player.stop();
    } catch (_) {}
    await player.play(AssetSource(asset), volume: 1);
  }

  Future<void> _playBedUnlocked({
    required _BedKind kind,
    required String asset,
    Duration position = Duration.zero,
    bool forceRestart = false,
  }) async {
    if (!forceRestart &&
        _bedKind == kind &&
        _bed?.state == PlayerState.playing) {
      return;
    }
    if (!forceRestart &&
        _bedKind == kind &&
        _bed?.state == PlayerState.paused) {
      try {
        await _bed!.resume();
        if (_bed?.state == PlayerState.playing) return;
      } catch (_) {}
    }

    final gen = ++_bedGeneration;

    var bed = _bed;
    if (bed == null) {
      await _recreatePlayers();
      bed = _bed;
      if (bed == null) return;
    }

    var ok = await _playBedAsset(bed, asset, position: position);
    if (gen != _bedGeneration) return;

    if (!ok) {
      // تەنها bed دووبارە دروست بکە — SFX مەکوژە.
      await _recreateBedOnly();
      if (gen != _bedGeneration) return;
      bed = _bed;
      if (bed == null) return;
      ok = await _playBedAsset(bed, asset);
      if (gen != _bedGeneration) return;
    }

    _bedKind = ok ? kind : _BedKind.none;
  }

  Future<void> _recreateBedOnly() async {
    _bedKind = _BedKind.none;
    final old = _bed;
    _bed = null;
    if (old != null) {
      try {
        await old.stop();
      } catch (_) {}
      try {
        await old.dispose();
      } catch (_) {}
    }
    final bed = AudioPlayer()..audioCache = _cache;
    await bed.setAudioContext(_sharedCtx);
    await bed.setReleaseMode(ReleaseMode.loop);
    await bed.setPlayerMode(PlayerMode.mediaPlayer);
    await bed.setVolume(1);
    _bed = bed;
  }

  Future<void> _recreateSfxOnly() async {
    final old = _sfx;
    _sfx = null;
    if (old != null) {
      try {
        await old.stop();
      } catch (_) {}
      try {
        await old.dispose();
      } catch (_) {}
    }
    final sfx = AudioPlayer()..audioCache = _cache;
    await sfx.setAudioContext(_sharedCtx);
    await sfx.setReleaseMode(ReleaseMode.stop);
    await sfx.setPlayerMode(PlayerMode.lowLatency);
    await sfx.setVolume(1);
    _sfx = sfx;
  }

  Future<void> _playSfxUnlocked(String asset) async {
    var sfx = _sfx;
    if (sfx == null) {
      await _recreateSfxOnly();
      sfx = _sfx;
      if (sfx == null) return;
    }

    try {
      await _playSfxAsset(sfx, asset);
    } catch (_) {
      try {
        await _recreateSfxOnly();
        sfx = _sfx;
        if (sfx == null) return;
        await _playSfxAsset(sfx, asset);
      } catch (_) {}
    }
  }

  Future<void> ensureLobbyCountdown({
    required Duration remaining,
    bool forceRestart = false,
  }) {
    return _enqueue(() async {
      const lead = Duration(seconds: 30);
      var safeRemaining = remaining;
      if (safeRemaining.isNegative) safeRemaining = Duration.zero;
      if (safeRemaining > lead) safeRemaining = lead;

      var position = Duration.zero;
      final elapsed = lead - safeRemaining;
      if (elapsed >= const Duration(seconds: 2) &&
          elapsed <= const Duration(seconds: 28)) {
        position = elapsed;
      }

      if (_bedKind == _BedKind.lobby && _bed?.state == PlayerState.playing) {
        if (!forceRestart) {
          final currentPos = await _bed?.getCurrentPosition() ?? Duration.zero;
          final drift = (currentPos - position).inMilliseconds.abs();
          if (drift < 800) {
            return;
          }
          try {
            await _bed?.seek(position);
            return;
          } catch (_) {}
        }
      }

      await _playBedUnlocked(
        kind: _BedKind.lobby,
        asset: _lobbyAsset,
        position: position,
        forceRestart: forceRestart,
      );
    });
  }

  Future<void> stopLobby() => _enqueue(_stopBedUnlocked);

  Future<void> playQuizStart() => _playSfxNow(_quizStartAsset);

  Future<void> startQuestionTimer({
    required Duration remaining,
    required Duration total,
    bool forceRestart = false,
  }) {
    return _enqueue(() async {
      var safeRemaining = remaining;
      if (safeRemaining.isNegative) safeRemaining = Duration.zero;
      if (safeRemaining > total) safeRemaining = total;

      final elapsed = total - safeRemaining;
      final position = elapsed;

      if (_bedKind == _BedKind.timer && _bed?.state == PlayerState.playing) {
        if (!forceRestart) {
          final currentPos = await _bed?.getCurrentPosition() ?? Duration.zero;
          final drift = (currentPos - position).inMilliseconds.abs();
          if (drift < 800) {
            return;
          }
          try {
            await _bed?.seek(position);
            return;
          } catch (_) {}
        }
      }

      await _playBedUnlocked(
        kind: _BedKind.timer,
        asset: _timerAsset,
        position: position,
        forceRestart: forceRestart,
      );
    });
  }

  Future<void> stopQuestionTimer() => _enqueue(_stopBedUnlocked);

  Future<void> playAnswerCorrect() => _playSfxNow(_correctAsset);

  Future<void> playAnswerWrong() => _playSfxNow(_wrongAsset);

  Future<void> playNextQuestion() => _playSfxNow(_nextAsset);

  Future<void> playWinners() => _playSfxNow(_winnersAsset);

  Future<void> playLevelUp() => _playSfxNow(_levelUpAsset);

  /// SFX دەرەوەی queueی bed — خێرا و بێ وەستان لەسەر تایمەر.
  Future<void> _playSfxNow(String asset) async {
    try {
      await _ensureReady();
      await _playSfxUnlocked(asset);
    } catch (_) {
      try {
        await _recreateSfxOnly();
        await _playSfxUnlocked(asset);
      } catch (_) {}
    }
  }

  Future<void> stopAll() {
    return _enqueue(() async {
      await _stopBedUnlocked();
      final sfx = _sfx;
      if (sfx != null) {
        try {
          await sfx.stop();
        } catch (_) {}
      }
    });
  }
}
