import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

import 'models.dart';
import 'live_quiz_models.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment('API_URL',
      defaultValue:
      'https://barav-backend.arkanstudiokrd.workers.dev/api');
  static const String wsBaseUrl = String.fromEnvironment('WS_URL',
      defaultValue:
      'wss://barav-backend.arkanstudiokrd.workers.dev/api');

  static String resolveMediaUrl(String? key) {
    if (key == null || key.trim().isEmpty) return '';
    if (key.startsWith('http')) return key;
    
    final host = baseUrl.replaceAll('/api', '');
    if (key.startsWith('/media/')) {
      return '$host$key';
    }
    return '$host/media/${key.replaceFirst(RegExp(r'^/+'), '')}';
  }

  static Future<Map<String, dynamic>> providerLogin(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/provider'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Login failed';
      throw Exception(error);
    }
  }

  /// Login with phone/username + password (Neon DB — no Firebase)
  static Future<Map<String, dynamic>> phoneLogin({
    required String identifier,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier, 'password': password}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    final error = jsonDecode(response.body)['error'] ?? 'Login failed';
    throw Exception(error);
  }

  /// Register with phone + password (step 1). Returns token + userId to pass to CompleteProfileScreen.
  static Future<Map<String, dynamic>> registerPhone({
    required String phone,
    required String password,
    required String code,
    String? phoneCode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register-phone'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone, 
        'password': password, 
        'code': code,
        'phoneCode': phoneCode,
      }),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    final error = jsonDecode(response.body)['error'] ?? 'Registration failed';
    throw Exception(error);
  }

  /// Sends an OTP code to the provided phone number via backend (OTPIQ).
  static Future<void> sendOtp(String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      var error = 'Failed to send OTP';
      try {
        error = jsonDecode(response.body)['error'] ?? error;
      } catch (_) {}
      throw Exception(error);
    }
  }

  /// Verifies the OTP code via backend.
  static Future<void> verifyOtp(String phone, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'code': code}),
    );
    if (response.statusCode != 200) {
      var error = 'Invalid OTP code';
      try {
        error = jsonDecode(response.body)['error'] ?? error;
      } catch (_) {}
      throw Exception(error);
    }
  }

  static Future<void> forgotPasswordInit(String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password/init'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    if (response.statusCode != 200) {
      var error = 'Failed to initiate password reset';
      try {
        error = jsonDecode(response.body)['error'] ?? error;
      } catch (_) {}
      throw Exception(error);
    }
  }

  static Future<void> forgotPasswordReset(String phone, String code, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password/reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'code': code, 'newPassword': newPassword}),
    );
    if (response.statusCode != 200) {
      var error = 'Failed to reset password';
      try {
        error = jsonDecode(response.body)['error'] ?? error;
      } catch (_) {}
      throw Exception(error);
    }
  }

  static Future<Map<String, dynamic>> registerProvider({
    required String token,
    required String fullName,
    required String username,
    String? phone,
    String? phoneCode,
    String? avatarPath,
    String? provider,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register-provider'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'fullName': fullName,
        'username': username,
        'phone': phone,
        'phoneCode': phoneCode,
        'avatarPath': avatarPath,
        'provider': provider,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Registration failed';
      throw Exception(error);
    }
  }

  static Future<Map<String, dynamic>> getMe(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw UnauthorizedException('Token is invalid or expired');
    } else {
      throw Exception('Failed to get user profile: ${response.statusCode}');
    }
  }

  static Future<bool> checkAvailability({
    required String field,
    required String value,
    String? excludeId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/check-availability'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'field': field,
          'value': value,
          'excludeId': ?excludeId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['available'] ?? false;
      }
      return false;
    } catch (e) {
      return false; // On network error, assume taken to be safe or maybe true to let backend handle? False is safer for UI.
    }
  }

  static Future<Map<String, dynamic>> updateUser(
    String id,
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Update failed';
      throw Exception(error);
    }
  }

  static Future<String> uploadAvatar(
    String id,
    String filePath,
    String token,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/users/$id/avatar'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('avatar', filePath));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      return data['avatarUrl'] as String;
    } else {
      var error = 'Avatar upload failed';
      try {
        error = jsonDecode(responseBody)['error'] ?? error;
      } catch (_) {}
      throw Exception(error);
    }
  }

  /// Uploads a provider photo URL (Google/Apple) to R2 via the backend.
  /// Returns the new R2-backed avatarUrl.
  static Future<String> uploadAvatarFromUrl(
    String userId,
    String photoUrl,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/avatar-url'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'url': photoUrl}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['avatarUrl'] as String;
    } else {
      var error = 'Avatar URL upload failed';
      try {
        error = jsonDecode(response.body)['error'] ?? error;
      } catch (_) {}
      throw Exception(error);
    }
  }

  static Future<int> useSkipOpportunity(String id, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$id/use-skip'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['skip'] as int;
    } else {
      final error =
          jsonDecode(response.body)['error'] ??
          'Failed to use skip opportunity';
      throw Exception(error);
    }
  }

  /// زیادکردنی هەڵ بڕیوارداو سەیرکردنی ڕیکلام
  static Future<int> addSkip(String id, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$id/add-skip'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['skip'] as int;
    } else {
      final error =
          jsonDecode(response.body)['error'] ??
          'Failed to add skip';
      throw Exception(error);
    }
  }

  static Future<List<QuizData>> getQuizzes([String? token]) async {
    final Map<String, String> headers = {};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.get(
      Uri.parse('$baseUrl/quizzes'),
      headers: headers.isNotEmpty ? headers : null,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] as List;
      return data
          .map((e) => QuizData.fromJson(e))
          .where((q) => q.status != 'archived')
          .toList();
    } else {
      throw Exception('Failed to load quizzes');
    }
  }

  static Future<Map<String, dynamic>> joinQuizSession(
    String quizId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quiz-live/$quizId/join'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      var error = 'Failed to join quiz';
      try {
        error = jsonDecode(response.body)['error'] ?? error;
      } catch (_) {}
      throw Exception(error);
    }
  }

  static Future<Map<String, dynamic>> setQuizReady(
    String quizId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quiz-live/$quizId/ready'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      var error = 'Failed to set ready status';
      try {
        error = jsonDecode(response.body)['error'] ?? error;
      } catch (_) {}
      throw Exception(error);
    }
  }

  static Future<List<LiveQuestion>> getQuizQuestions(
    String quizId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/questions?quizId=$quizId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List<dynamic>;
      return data.map((q) {
        final opts = q['options'] as List<dynamic>;
        return LiveQuestion(
          id: q['id'] as String? ?? '',
          text: q['text'] as String? ?? '',
          imageUrl: ApiService.resolveMediaUrl(q['mediaUrl'] as String?),
          durationSeconds: q['timer'] as int? ?? 15,
          explanation: q['explanation'] as String?,
          category: q['category'] as String? ?? q['categoryName'] as String?,
          points: q['points'] as int? ?? 10,
          options: opts
              .map(
                (o) => QuizOption(
                  id: o['id'] as String? ?? '',
                  text: o['text'] as String? ?? '',
                  isCorrect: o['isCorrect'] as bool? ?? false,
                ),
              )
              .toList(),
        );
      }).toList();
    } else {
      var error = 'Failed to fetch questions';
      try {
        error = jsonDecode(response.body)['error'] ?? error;
      } catch (_) {}
      throw Exception(error);
    }
  }

  static Future<Map<String, dynamic>> submitAnswer(
    String quizId,
    String questionId,
    String selectedOptionId,
    int answerTimeMs,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quiz-live/$quizId/question/$questionId/answer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'selectedOptionId': selectedOptionId,
        'answerTimeMs': answerTimeMs,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      var error = 'Failed to submit answer';
      try {
        error = jsonDecode(response.body)['error'] ?? error;
      } catch (_) {}
      throw Exception(error);
    }
  }

  static Future<Map<String, dynamic>> submitTimeout(
    String quizId,
    String questionId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quiz-live/$quizId/question/$questionId/timeout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      var error = 'Failed to record timeout';
      try {
        error = jsonDecode(response.body)['error'] ?? error;
      } catch (_) {}
      throw Exception(error);
    }
  }

  static Future<Map<String, dynamic>> leaveLiveQuiz(
    String quizId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quiz-live/$quizId/leave'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      var error = 'Failed to leave quiz';
      try {
        error = jsonDecode(response.body)['error'] ?? error;
      } catch (_) {}
      throw Exception(error);
    }
  }

  static Future<Map<String, dynamic>> reviveParticipant(
    String quizId, [
    String? token,
  ]) async {
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.post(
      Uri.parse('$baseUrl/quiz-live/$quizId/revive'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      var error = 'Failed to revive';
      try {
        error = jsonDecode(response.body)['error'] ?? error;
      } catch (_) {}
      throw Exception(error);
    }
  }

  static Future<Map<String, dynamic>> getQuizResults(
    String quizId, [
    String? token,
  ]) async {
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.get(
      Uri.parse('$baseUrl/quiz-live/$quizId/results'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      var error = 'Failed to fetch results';
      try {
        error = jsonDecode(response.body)['error'] ?? error;
      } catch (_) {}
      throw Exception(error);
    }
  }

  static Future<Map<String, dynamic>> getSessionResults(
    String sessionId, [
    String? token,
  ]) async {
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.get(
      Uri.parse('$baseUrl/quiz-sessions/$sessionId/results'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      var error = 'Failed to fetch results';
      try {
        error = jsonDecode(response.body)['error'] ?? error;
      } catch (_) {}
      throw Exception(error);
    }
  }

  static Future<Map<String, dynamic>> getLastWinners() async {
    final response = await http.get(
      Uri.parse('$baseUrl/quizzes/last-winners'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      var error = 'Failed to fetch last winners';
      try {
        error = jsonDecode(response.body)['error'] ?? error;
      } catch (_) {}
      throw Exception(error);
    }
  }

  static Future<List<AppNotification>> getNotifications(
    String currentUserId, [
    String? token,
  ]) async {
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: headers.isNotEmpty ? headers : null,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] as List;
      return data
          .map((e) => AppNotification.fromJson(e, currentUserId))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  static Future<void> markNotificationRead(
    String notificationId,
    String currentUserId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'userId': currentUserId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }

  static Future<void> markAllNotificationsRead(
    String token,
    String currentUserId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'userId': currentUserId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark all notifications as read');
    }
  }

  static Future<Map<String, dynamic>> getQuestionCurrent(
    String quizId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quiz-live/$quizId/question/current'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      var error = 'Failed to fetch current question';
      try {
        error = jsonDecode(response.body)['error'] ?? error;
      } catch (_) {}
      throw Exception(error);
    }
  }

  static Future<Map<String, dynamic>> revealQuestion(
    String quizId,
    String questionId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quiz-live/$quizId/question/$questionId/reveal'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      var error = 'Failed to fetch question reveal stats';
      try {
        error = jsonDecode(response.body)['error'] ?? error;
      } catch (_) {}
      throw Exception(error);
    }
  }

  static Future<int> getPresenceCount() async {
    final response = await http.get(
      Uri.parse('$baseUrl/presence/count'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['onlineCount'] as int? ?? 0;
    } else {
      return 0;
    }
  }

  static WebSocketChannel createQuizWebSocket(String quizId, String token) {
    final channel = IOWebSocketChannel.connect(
      Uri.parse('$wsBaseUrl/quiz-live/$quizId/ws'),
      headers: {'Authorization': 'Bearer $token'},
    );
    channel.ready.catchError((_) {});
    return channel;
  }

  static Future<List<ClaimReceipt>> getReceipts({
    required String userId,
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/receipts?userId=$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((json) => ClaimReceipt.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      var error = 'Failed to fetch claim receipts';
      try {
        error = jsonDecode(response.body)['error'] ?? error;
      } catch (_) {}
      throw Exception(error);
    }
  }

  static Future<List<Map<String, dynamic>>> getSponsors({String? type}) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final separator = type != null ? '&' : '?';
      final uri = Uri.parse(
        '$baseUrl/sponsors${type != null ? '?type=$type' : ''}${separator}_t=$timestamp',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body['data'] as List<dynamic>? ?? [];
        return list.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<SupportMessage>> getSupportMessages(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/support/my-messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['data'];
      return data.map((e) => SupportMessage.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      if (response.statusCode == 401) throw UnauthorizedException();
      throw Exception('Failed to fetch support messages');
    }
  }

  static Future<void> markSupportMessagesRead(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/support/my-messages/read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark support messages as read');
    }
  }

  static Future<SupportMessage> sendSupportMessage(String token, String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/support/message'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      return SupportMessage.fromJson(data);
    } else {
      if (response.statusCode == 401) throw UnauthorizedException();
      throw Exception('Failed to send support message');
    }
  }

  static Future<SupportMessage> sendSupportImage(String token, List<int> imageBytes, String mimeType) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/support/upload-image'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    final ext = mimeType.contains('png') ? 'png' : mimeType.contains('webp') ? 'webp' : 'jpg';
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: 'chat_image.$ext',
      contentType: MediaType.parse(mimeType),
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      return SupportMessage.fromJson(data);
    } else {
      if (response.statusCode == 401) throw UnauthorizedException();
      throw Exception('Failed to upload image');
    }
  }

  static Future<void> deleteMyChat(String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/support/my-chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      if (response.statusCode == 401) throw UnauthorizedException();
      throw Exception('Failed to delete chat');
    }
  }
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Unauthorized']);

  @override
  String toString() => message;
}
