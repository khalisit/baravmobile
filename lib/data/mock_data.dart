import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'live_quiz_models.dart';
import 'models.dart';

/// داتای نموونەیی بۆ قۆناغی دیزاین. دواتر لە باک ئێندەوە دێت.
abstract final class MockData {
  /// هەژماری تێست بۆ چوونەژوورەوە لە قۆناغی دیزاین.
  static const String demoEmail = 'karox';
  static const String demoPassword = 'karox';

  static const String adminEmail = 'admin';
  static const String adminPassword = 'admin';

  static const UserProfile user = UserProfile(
    id: 'user_1',
    fullName: 'کارۆخ خالید محەمەد',
    username: 'karox',
    phone: '٠٧٥٠ ١٢٣ ٤٥٦٧',
    email: 'karox@barav.app',
  );

  static const UserProfile adminUser = UserProfile(
    id: 'admin_1',
    fullName: 'بەڕێوەبەری باراو',
    username: 'admin',
    phone: '٠٧٥٠ ٠٠٠ ٠٠٠٠',
    email: 'admin@barav.app',
    status: 'active',
  );

  static const List<String> mockPlayerNames = [
    'Alex Carter',
    'Sarah Jenkins',
    'David Miller',
    'Emma Wilson',
    'Michael Brown',
    'Olivia Taylor',
    'James Anderson',
    'Sophia Davis',
    'William Evans',
    'Isabella Thomas',
    'Liam Wright',
    'Charlotte Green',
  ];

  static const List<AdItem> ads = [
    AdItem(
      title: 'خەڵاتی هەفتانە',
      subtitle: 'بەشداربە و مۆبایلێکی نوێ بباتەوە',
      kind: AdKind.video,
      tint: [AppColors.purpleLight, AppColors.purpleDark],
    ),
    AdItem(
      title: 'کویزی تایبەت',
      subtitle: 'شەوی هەینی، کاتژمێر ٩ی شەو',
      kind: AdKind.image,
      tint: [AppColors.purple, Color(0xFF2B1B6B)],
    ),
    AdItem(
      title: 'بانگهێشتی هاوڕێکانت',
      subtitle: 'بۆ هەر هاوڕێیەک ١٠٠ خاڵ وەربگرە',
      kind: AdKind.image,
      tint: [Color(0xFF6D28D9), Color(0xFF1E1B4B)],
    ),
  ];

  /// کویزی نموونەیی — ٤ پرسیار، هەر یەکە ٤ وەڵام.
  static List<LiveQuestion> get sampleLiveQuestions => const [
        LiveQuestion(
          text: 'What is the capital of France?',
          options: [
            QuizOption(text: 'Paris', isCorrect: true),
            QuizOption(text: 'London', isCorrect: false),
            QuizOption(text: 'Berlin', isCorrect: false),
            QuizOption(text: 'Rome', isCorrect: false),
          ],
        ),
        LiveQuestion(
          text: 'Which planet is known as the Red Planet?',
          options: [
            QuizOption(text: 'Earth', isCorrect: false),
            QuizOption(text: 'Mars', isCorrect: true),
            QuizOption(text: 'Jupiter', isCorrect: false),
            QuizOption(text: 'Venus', isCorrect: false),
          ],
        ),
        LiveQuestion(
          text: 'What is the largest ocean on Earth?',
          options: [
            QuizOption(text: 'Atlantic', isCorrect: false),
            QuizOption(text: 'Indian', isCorrect: false),
            QuizOption(text: 'Pacific', isCorrect: true),
            QuizOption(text: 'Arctic', isCorrect: false),
          ],
        ),
        LiveQuestion(
          text: 'Who wrote the play "Romeo and Juliet"?',
          options: [
            QuizOption(text: 'Charles Dickens', isCorrect: false),
            QuizOption(text: 'William Shakespeare', isCorrect: true),
            QuizOption(text: 'Mark Twain', isCorrect: false),
            QuizOption(text: 'Jane Austen', isCorrect: false),
          ],
        ),
        LiveQuestion(
          text: 'How many legs does a spider have?',
          options: [
            QuizOption(text: '6', isCorrect: false),
            QuizOption(text: '8', isCorrect: true),
            QuizOption(text: '10', isCorrect: false),
            QuizOption(text: '12', isCorrect: false),
          ],
        ),
      ];

  static ScheduledQuiz sampleScheduledQuiz() {
    final now = DateTime.now();
    return ScheduledQuiz(
      id: 'sample-1',
      title: 'کویزی شەوی هەینی',
      startedAt: now.add(const Duration(seconds: 45)),
      questions: sampleLiveQuestions,
      sponsors: const [
        QuizSponsor(
          brandName: 'BARAV Store',
          tagline: 'سپۆنسەری فەرمی کویز',
          mediaUrl:
              'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=1200&q=80',
          kind: SponsorMediaKind.image,
        ),
        QuizSponsor(
          brandName: 'Kurdish Tech',
          tagline: 'تەکنەلۆژیا بۆ هەمووان',
          mediaUrl:
              'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=1200&q=80',
          kind: SponsorMediaKind.image,
        ),
        QuizSponsor(
          brandName: 'Nawroz Cafe',
          tagline: 'چێشتی کوردی · کافێ',
          mediaUrl:
              'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=1200&q=80',
          kind: SponsorMediaKind.image,
        ),
      ],
    );
  }

  static List<QuizEntry> get entries {
    final now = DateTime.now();
    return [
      QuizEntry(
        number: 10,
        question: 'پایتەختی هەرێمی کوردستان کام شارە؟',
        answer: 'هەولێر',
        publishedAt: now.subtract(const Duration(hours: 20)),
      ),
      QuizEntry(
        number: 9,
        question: 'درێژترین ڕووباری عێراق کامەیە؟',
        answer: 'ڕووباری فورات',
        publishedAt: now.subtract(const Duration(hours: 21)),
      ),
      QuizEntry(
        number: 8,
        question: 'نووسەری کتێبی «مەم و زین» کێیە؟',
        answer: 'ئەحمەدی خانی',
        publishedAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      QuizEntry(
        number: 7,
        question: 'بەرزترین چیای کوردستان کامەیە؟',
        answer: 'چیای هەڵگورد',
        publishedAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      QuizEntry(
        number: 6,
        question: 'کام وڵات زۆرترین دانیشتووی هەیە لە جیهاندا؟',
        answer: 'هیندستان',
        publishedAt: now.subtract(const Duration(days: 2, hours: 1)),
      ),
      QuizEntry(
        number: 5,
        question: 'گەورەترین دەریاچەی سروشتی ڕۆژهەڵاتی ناوەڕاست کامەیە؟',
        answer: 'دەریاچەی وان',
        publishedAt: now.subtract(const Duration(days: 2, hours: 2)),
      ),
    ];
  }

  /// ئاگادارییەکانی نموونەیی — دواتر لە باک ئێندەوە دێن.
  static List<AppNotification> sampleNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'n1',
        title: 'کویزی ئەمشەو ئامادەیە',
        body: 'کویزی زیندوو لە کاتژمێر ٩ی شەو دەستپێدەکات. ئامادەبە!',
        type: NotificationType.quizScheduled,
        createdAt: now.subtract(const Duration(minutes: 18)),
      ),
      AppNotification(
        id: 'n2',
        title: 'کویز بەم زووانە دەستپێدەکات',
        body: '٣٠ خولەک ماوە بۆ دەستپێکی کویز. بچۆرە ناو لۆبی.',
        type: NotificationType.quizStarting,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 5)),
      ),
      AppNotification(
        id: 'n3',
        title: 'Extra Life بەخۆڕایی',
        body: '٣ ڕیکلام ببینە و ١ Extra Life وەربگرە بۆ سکیپی پرسیار.',
        type: NotificationType.promo,
        createdAt: now.subtract(const Duration(hours: 5)),
        read: true,
      ),
      AppNotification(
        id: 'n4',
        title: 'بەخێربێیت بۆ BARAV QUIZ',
        body: 'هەموو ڕۆژێک کویزی زیندوو، خاڵ و لیڤڵ. سەرکەوتوو بیت!',
        type: NotificationType.general,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        read: true,
      ),
      AppNotification(
        id: 'n5',
        title: 'کویزی هەینی',
        body: 'کویزی تایبەتی هەینی خشتەکرا. خەڵاتی گەورە چاوەڕێتە.',
        type: NotificationType.quizScheduled,
        createdAt: now.subtract(const Duration(days: 2)),
        read: true,
      ),
    ];
  }
}
