/// مۆدێلەکانی کویزی زیندوو (UI + سیمولەیشن).
library;
enum QuizSessionStatus { joined, ready, playing, finished, disconnected }

enum LiveQuizPhase {
  /// هیچ کویزێک نییە
  idle,

  /// کویز دانراوە، چاوەڕوانی startedAt
  scheduled,

  /// پێش دەستپێکی پرسیارەکان
  lobby,

  /// وەڵامدانەوە
  question,

  /// نیشاندانی وەڵامی ڕاست پێش پرسیاری داهاتوو
  reveal,

  /// کۆتایی — براوەکان
  finished,
}

class QuizOption {
  const QuizOption({
    this.id = '',
    required this.text,
    required this.isCorrect,
  });

  final String id;
  final String text;
  final bool isCorrect;
}

class LiveQuestion {
  const LiveQuestion({
    this.id = '',
    this.text = '',
    required this.options,
    this.imageUrl,
    this.durationSeconds = 15,
    this.explanation,
    this.category,
    this.points = 10,
  });

  final String id;

  /// دەقی پرسیار — دەتوانێت بەتاڵ بێت ئەگەر وێنە هەبێت.
  final String text;

  /// وێنەی پرسیار (URL یان ڕێڕەوی ناوخۆیی PNG/JPG).
  final String? imageUrl;

  final List<QuizOption> options;
  final int durationSeconds;
  final String? explanation;
  final String? category;
  final int points;

  bool get hasText => text.trim().isNotEmpty;
  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;
  bool get isValid => hasText || hasImage;

  int get correctIndex => options.indexWhere((o) => o.isCorrect);
}

/// جۆری میدیای سپۆنسەر لە کاتی پرسیارەکان.
enum SponsorMediaKind { image, video }

/// ڕیکلامی سپۆنسەر — ئەدمین وێنە یان ڤیدیۆ دادەنێت؛ یاری بەردەوام دەبێت.
class QuizSponsor {
  const QuizSponsor({
    required this.brandName,
    required this.mediaUrl,
    this.kind = SponsorMediaKind.image,
    this.tagline,
  });

  final String brandName;
  final String mediaUrl;
  final SponsorMediaKind kind;
  final String? tagline;

  bool get hasMedia => mediaUrl.trim().isNotEmpty;
}

class ScheduledQuiz {
  const ScheduledQuiz({
    required this.id,
    required this.title,
    this.description,
    required this.startedAt,
    required this.questions,
    this.avatarUrl,
    this.sponsors = const [],
    this.rewards = const [],
  });

  final String id;
  final String title;
  final String? description;
  final String? avatarUrl;
  final DateTime startedAt;
  final List<LiveQuestion> questions;
  final List<QuizSponsor> sponsors;
  final List<Map<String, dynamic>> rewards;

  /// ڕیکلامە چالاکەکان (میدیایان هەیە).
  List<QuizSponsor> get activeSponsors =>
      sponsors.where((s) => s.hasMedia).toList(growable: false);

  bool get hasSponsors => activeSponsors.isNotEmpty;

  /// یەکەم سپۆنسەر — بۆ گونجاندنی کۆدی کۆن.
  QuizSponsor? get sponsor {
    final active = activeSponsors;
    return active.isEmpty ? null : active.first;
  }

  ScheduledQuiz copyWith({
    String? description,
    DateTime? startedAt,
    String? avatarUrl,
    List<QuizSponsor>? sponsors,
    List<Map<String, dynamic>>? rewards,
  }) {
    return ScheduledQuiz(
      id: id,
      title: title,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      startedAt: startedAt ?? this.startedAt,
      questions: questions,
      sponsors: sponsors ?? this.sponsors,
      rewards: rewards ?? this.rewards,
    );
  }
}

class QuizWinner {
  const QuizWinner({
    required this.name,
    this.username,
    required this.prize,
    required this.rank,
    this.avatarPath,
    this.userId,
    this.isWinner = true,
    this.score,
    this.totalAnswerTimeMs,
  });

  final String name;
  final String? username;
  final String prize;
  final int rank;
  final String? avatarPath;
  final String? userId;
  final bool isWinner;
  final int? score;
  final int? totalAnswerTimeMs;

  bool get hasAvatar =>
      avatarPath != null && avatarPath!.trim().isNotEmpty;

  /// پێشاندانی username لەجیاتی ناوی تەواو
  String get displayName {
    if (username != null && username!.trim().isNotEmpty) {
      return username!.trim();
    }
    return name;
  }
}
