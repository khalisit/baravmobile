import 'package:flutter/material.dart';
import 'api_service.dart';

DateTime _parseDateTime(dynamic val) {
  if (val == null) return DateTime.now();
  var clean = val.toString().trim().replaceAll(' ', 'T').replaceAll('Z', '');
  return DateTime.tryParse(clean) ?? DateTime.now();
}

DateTime? _parseDateTimeNullable(dynamic val) {
  if (val == null) return null;
  var clean = val.toString().trim().replaceAll(' ', 'T').replaceAll('Z', '');
  if (clean.isEmpty) return null;
  return DateTime.tryParse(clean);
}

enum AdKind { image, video }

/// ڕیکلامێک کە لە سەرەوەی بەشی سەرەکیدا پیشان دەدرێت.
/// [mediaUrl] لە باک ئێندەوە دێت؛ ئەگەر بەتاڵ بێت، دیزاینی ناوخۆیی بەکاردێت.
class AdItem {
  const AdItem({
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.tint,
    this.mediaUrl,
  });

  final String title;
  final String subtitle;
  final AdKind kind;
  final List<Color> tint;
  final String? mediaUrl;
}

/// پرسیارێک لەگەڵ وەڵامەکەی و کاتی بڵاوکردنەوەی.
class QuizEntry {
  const QuizEntry({
    required this.number,
    required this.question,
    required this.answer,
    required this.publishedAt,
  });

  final int number;
  final String question;
  final String answer;
  final DateTime publishedAt;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.username,
    required this.phone,
    required this.email,
    this.provider = 'phone',
    this.status = 'active',
    this.avatarPath,
    this.phoneCode,
    this.lastUsernameChangedAt,
    this.lastNameChangedAt,
    this.skip = 0,
    this.totalPoints = 0,
    this.winnings = 0,
    this.quizzesPlayed = 0,
    this.totalRewards = 0,
    this.verifyPhone = false,
  });

  final String id;
  final String fullName;
  final String username;
  final String phone;
  final String email;
  final String provider;
  final String status;
  final String? phoneCode;
  final DateTime? lastUsernameChangedAt;
  final DateTime? lastNameChangedAt;
  final int skip;
  final int totalPoints;
  final int winnings;
  final int quizzesPlayed;
  final int totalRewards;
  final bool verifyPhone;

  /// ڕێڕەوی ناوخۆیی وێنەی پرۆفایل (ئەگەر هەبێت).
  final String? avatarPath;

  bool get hasAvatar => avatarPath != null && avatarPath!.trim().isNotEmpty;

  /// یەکەم پیتی ناو و ناوی باوک بۆ ئەڤاتار.
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first;
    return '${parts[0].characters.first}${parts[1].characters.first}';
  }

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? username,
    String? phone,
    String? email,
    String? provider,
    String? status,
    String? avatarPath,
    String? phoneCode,
    DateTime? lastUsernameChangedAt,
    DateTime? lastNameChangedAt,
    int? skip,
    int? totalPoints,
    int? winnings,
    int? quizzesPlayed,
    int? totalRewards,
    bool? verifyPhone,
    bool clearAvatar = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      provider: provider ?? this.provider,
      status: status ?? this.status,
      phoneCode: phoneCode ?? this.phoneCode,
      lastUsernameChangedAt: lastUsernameChangedAt ?? this.lastUsernameChangedAt,
      lastNameChangedAt: lastNameChangedAt ?? this.lastNameChangedAt,
      skip: skip ?? this.skip,
      totalPoints: totalPoints ?? this.totalPoints,
      winnings: winnings ?? this.winnings,
      quizzesPlayed: quizzesPlayed ?? this.quizzesPlayed,
      totalRewards: totalRewards ?? this.totalRewards,
      verifyPhone: verifyPhone ?? this.verifyPhone,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'username': username,
      'phone': phone,
      'email': email,
      'provider': provider,
      'status': status,
      'phoneCode': phoneCode,
      'avatarPath': avatarPath,
      'lastUsernameChangedAt': lastUsernameChangedAt?.toIso8601String(),
      'lastNameChangedAt': lastNameChangedAt?.toIso8601String(),
      'skip': skip,
      'totalPoints': totalPoints,
      'winnings': winnings,
      'quizzesPlayed': quizzesPlayed,
      'totalRewards': totalRewards,
      'verifyPhone': verifyPhone,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      username: map['username'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      provider: map['provider'] ?? 'phone',
      status: map['status'] ?? 'active',
      phoneCode: map['phoneCode'],
      avatarPath: map['avatarPath'],
      lastUsernameChangedAt: map['lastUsernameChangedAt'] != null
          ? DateTime.tryParse(map['lastUsernameChangedAt'])
          : null,
      lastNameChangedAt: map['lastNameChangedAt'] != null
          ? DateTime.tryParse(map['lastNameChangedAt'])
          : null,
      skip: map['skip'] ?? 0,
      totalPoints: map['totalPoints'] ?? 0,
      winnings: map['winnings'] ?? 0,
      quizzesPlayed: map['quizzesPlayed'] ?? 0,
      totalRewards: map['totalRewards'] ?? 0,
      verifyPhone: map['verifyPhone'] ?? false,
    );
  }
}

/// جۆری ئاگاداری.
enum NotificationType { quizScheduled, quizStarting, general, promo, info, success, warning, error }

/// ئاگاداریی ناوخۆیی — دواتر لە باک ئێندەوە دێت.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.userId,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final String? userId;
  final bool read;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      createdAt: createdAt,
      userId: userId,
      read: read ?? this.read,
    );
  }

  factory AppNotification.fromJson(
    Map<String, dynamic> json,
    String? currentUserId,
  ) {
    final typeStr = (json['type'] as String? ?? 'general').toLowerCase();
    NotificationType parsedType = NotificationType.general;
    if (typeStr == 'quiz_scheduled') {
      parsedType = NotificationType.quizScheduled;
    } else if (typeStr == 'quiz_starting') {
      parsedType = NotificationType.quizStarting;
    } else if (typeStr == 'promo') {
      parsedType = NotificationType.promo;
    } else if (typeStr == 'info') {
      parsedType = NotificationType.info;
    } else if (typeStr == 'success') {
      parsedType = NotificationType.success;
    } else if (typeStr == 'warning') {
      parsedType = NotificationType.warning;
    } else if (typeStr == 'error') {
      parsedType = NotificationType.error;
    }

    final readBy = json['readBy'] as List<dynamic>? ?? [];
    final isRead = currentUserId != null && readBy.contains(currentUserId);

    return AppNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['message'] ?? json['body'] as String? ?? '',
      type: parsedType,
      createdAt: _parseDateTime(json['createdAt']),
      userId: json['userId'] as String?,
      read: isRead,
    );
  }
}

/// مۆدێلی کویز کە لە باک ئێندەوە دێت
class QuizData {
  const QuizData({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryName,
    required this.status,
    required this.difficulty,
    required this.questionCount,
    required this.createdAt,
    this.updatedAt,
    this.scheduledAt,
    this.avatarUrl,
    this.duration = 15,
    this.winnersCount = 0,
    this.participantCount = 0,
    this.rewards = const [],
    this.winners = const [],
    this.isJoined = false,
    this.sessionStatus,
    this.participantStatus,
  });

  final String id;
  final String title;
  final String description;
  final String categoryName;
  final String status;
  final String difficulty;
  final int questionCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? scheduledAt;
  final String? avatarUrl;
  final int duration;
  final int winnersCount;
  final int participantCount;
  final List<Map<String, dynamic>> rewards;
  final List<Map<String, dynamic>> winners;
  final bool isJoined;
  final String? sessionStatus;
  final String? participantStatus;

  QuizData copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryName,
    String? status,
    String? difficulty,
    int? questionCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? scheduledAt,
    String? avatarUrl,
    int? duration,
    int? winnersCount,
    int? participantCount,
    List<Map<String, dynamic>>? rewards,
    List<Map<String, dynamic>>? winners,
    bool? isJoined,
    String? sessionStatus,
    String? participantStatus,
  }) {
    return QuizData(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryName: categoryName ?? this.categoryName,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      questionCount: questionCount ?? this.questionCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      duration: duration ?? this.duration,
      winnersCount: winnersCount ?? this.winnersCount,
      participantCount: participantCount ?? this.participantCount,
      rewards: rewards ?? this.rewards,
      winners: winners ?? this.winners,
      isJoined: isJoined ?? this.isJoined,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      participantStatus: participantStatus ?? this.participantStatus,
    );
  }

  factory QuizData.fromJson(Map<String, dynamic> json) {
    return QuizData(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? 'گشتی',
      status: json['status'] as String? ?? 'unknown',
      difficulty: json['difficulty'] as String? ?? 'medium',
      questionCount: json['questionCount'] as int? ?? 0,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updatedAt']),
      scheduledAt: _parseDateTimeNullable(json['startedAt'] ?? json['started_at'] ?? json['scheduledAt']),
      avatarUrl: ApiService.resolveMediaUrl(json['avatarUrl'] as String? ?? json['avatar_url'] as String?),
      duration: json['duration'] as int? ?? 15,
      winnersCount: json['winnersCount'] as int? ?? 0,
      participantCount: json['participantCount'] as int? ?? 0,
      rewards:
          (json['rewards'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      winners:
          (json['winners'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      isJoined:
          json['isJoined'] == true ||
          json['isJoined'] == 'true' ||
          json['isJoined'] == 1,
      sessionStatus: json['sessionStatus'] as String?,
      participantStatus: json['participantStatus'] as String?,
    );
  }
}

class ClaimReceipt {
  const ClaimReceipt({
    required this.id,
    required this.userId,
    this.quizId,
    this.quizTitle,
    required this.amount,
    required this.currency,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? quizId;
  final String? quizTitle;
  final double amount;
  final String currency;
  final String status;
  final String? notes;
  final DateTime createdAt;

  factory ClaimReceipt.fromJson(Map<String, dynamic> json) {
    return ClaimReceipt(
      id: json['id'] as String,
      userId: json['userId'] as String,
      quizId: json['quizId'] as String?,
      quizTitle: json['quizTitle'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'IQD',
      status: json['status'] as String? ?? 'PAID',
      notes: json['notes'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }
}

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.message,
    this.imageUrl,
    required this.isFromAdmin,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String message;
  final String? imageUrl;
  final bool isFromAdmin;
  final bool isRead;
  final DateTime createdAt;

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'] as String? ?? '',
      message: json['message'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      isFromAdmin: json['isFromAdmin'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }
}
