import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../session/session_controller.dart';
import '../../data/api_service.dart';

class PresenceService with WidgetsBindingObserver {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  WebSocketChannel? _wsChannel;
  Timer? _reconnectTimer;
  bool _isAppActive = true;

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    _connect();
  }

  final ValueNotifier<int> onlineCount = ValueNotifier<int>(0);

  void _connect() {
    if (!_isAppActive) return;
    _disconnect();
    
    final token = SessionController.instance.token;
    if (token == null || token.isEmpty) {
      // Don't connect if the user isn't logged in
      _scheduleReconnect();
      return;
    }

    try {
      _wsChannel = IOWebSocketChannel.connect(
        Uri.parse('${ApiService.wsBaseUrl}/presence/ws?token=$token'),
      );
      _wsChannel?.ready.catchError((_) {});
      
      _wsChannel?.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            if (data['type'] == 'presence_update') {
              onlineCount.value = data['count'] as int;
            }
          } catch (_) {}
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
      );
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void _disconnect() {
    _reconnectTimer?.cancel();
    _wsChannel?.sink.close();
    _wsChannel = null;
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_isAppActive) {
      _reconnectTimer = Timer(const Duration(seconds: 5), _connect);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppActive = true;
      _connect();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _isAppActive = false;
      _disconnect();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disconnect();
  }
}
