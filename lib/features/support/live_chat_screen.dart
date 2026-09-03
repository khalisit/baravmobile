import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/session/session_controller.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/widgets/glow_backdrop.dart';
import '../../data/api_service.dart';
import '../../data/models.dart';

class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<SupportMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    PushNotificationService.instance.suppressSupportNotifications = true;
    _fetchMessages();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      _fetchMessages(silent: true);
    });
  }

  @override
  void dispose() {
    PushNotificationService.instance.suppressSupportNotifications = false;
    _pollingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    final token = SessionController.instance.token;
    if (token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final messages = await ApiService.getSupportMessages(token);

      if (messages.any((m) => m.isFromAdmin && !m.isRead)) {
        ApiService.markSupportMessagesRead(token).catchError((_) {});
        for (int i = 0; i < messages.length; i++) {
          if (messages[i].isFromAdmin && !messages[i].isRead) {
            messages[i] = SupportMessage(
              id: messages[i].id,
              message: messages[i].message,
              imageUrl: messages[i].imageUrl,
              isFromAdmin: true,
              isRead: true,
              createdAt: messages[i].createdAt,
            );
          }
        }
      }

      if (mounted) {
        final wasAtBottom = _isAtBottom();
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        if (!silent || wasAtBottom) _scrollToBottom();
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatMessageTime(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final isToday =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;

    int h = local.hour;
    final ampm = h >= 12 ? 'PM' : 'AM';
    if (h == 0) h = 12;
    if (h > 12) h -= 12;

    final m = local.minute.toString().padLeft(2, '0');
    final timeStr = '$h:$m $ampm';

    if (isToday) {
      return timeStr;
    } else {
      return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')} - $timeStr';
    }
  }

  bool _isAtBottom() {
    if (!_scrollController.hasClients) return true;
    final pos = _scrollController.position;
    return pos.pixels >= pos.maxScrollExtent - 100;
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final token = SessionController.instance.token;
    if (token == null) return;

    setState(() => _isSending = true);

    try {
      final newMsg = await ApiService.sendSupportMessage(token, text);
      _controller.clear();
      if (mounted) {
        setState(() {
          _messages.add(newMsg);
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    }
  }

  Future<void> _sendImage() async {
    final token = SessionController.instance.token;
    if (token == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked == null) return;

    setState(() => _isSending = true);

    try {
      final bytes = await picked.readAsBytes();
      final mimeType = picked.name.toLowerCase().endsWith('.png')
          ? 'image/png'
          : picked.name.toLowerCase().endsWith('.webp')
          ? 'image/webp'
          : 'image/jpeg';
      final newMsg = await ApiService.sendSupportImage(token, bytes, mimeType);
      if (mounted) {
        setState(() {
          _messages.add(newMsg);
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
    }
  }

  Future<void> _closeChat() async {
    final isSorani = LocaleController.instance.isSorani;

    final result = await showDialog<bool?>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    ctx,
                  ).colorScheme.errorContainer.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 36,
                  color: Theme.of(ctx).colorScheme.error,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isSorani ? 'سڕینەوەی چات' : 'Jêbirina Çêtê',
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                isSorani
                    ? 'ئایا دڵنیایت کە دەتەوێت ئەم چاتە بسڕیتەوە؟\nئەم کارە هەڵناوەشێتەوە.'
                    : 'Ma tu piştrast î ku dixwazî vê çêtê jê bibî?\nEv kiryar nayê vegerandin.',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(true), // keep chat
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(isSorani ? 'پاشگەزبوونەوە' : 'Betal Bike'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(ctx).pop(false), // delete chat
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(ctx).colorScheme.error,
                        foregroundColor: Theme.of(ctx).colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(isSorani ? 'سڕینەوە' : 'Jê Bibe'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result == null || result == true) {
      // Cancelled or dialog dismissed
      return;
    } else {
      // Delete chat
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 40,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isSorani ? 'سوپاس 🙏' : 'Spas 🙏',
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  isSorani
                      ? 'سوپاس بۆ پەیوەندیکردنتان.\nخۆشحاڵین بە خزمەتکردنتان!'
                      : 'Spas ji bo têkiliya we.\nEm kêfxweş in bi xizmeta we!',
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(borderRadius: BorderRadius.circular(8)),
              ],
            ),
          ),
        ),
      );

      // Delete and go back
      try {
        final token = SessionController.instance.token;
        if (token != null) await ApiService.deleteMyChat(token);
      } catch (_) {}

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop(); // close thank you dialog
        Navigator.of(context).pop(); // close chat screen
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSorani = LocaleController.instance.isSorani;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isSorani ? 'چاتی ڕاستەوخۆ' : 'Danûstandina Zindî'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8, left: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _closeChat,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: theme.colorScheme.error,
              ),
              tooltip: isSorani ? 'سڕینەوەی چات' : 'Çêtê jê bibe',
            ),
          ),
        ],
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ColorFilter.mode(
              theme.scaffoldBackgroundColor.withOpacity(0.5),
              BlendMode.srcOver,
            ),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: GlowBackdrop(
        intensity: 0.2,
        child: SafeArea(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 56,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isSorani
                                    ? 'پرسیارەکانت لێرە بنووسە...'
                                    : 'Pirsên xwe li vir binivîse...',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isMe = !msg.isFromAdmin;
                            final hasImage =
                                msg.imageUrl != null &&
                                msg.imageUrl!.isNotEmpty;
                            final hasText = msg.message.isNotEmpty;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                mainAxisAlignment: isMe
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!isMe) ...[
                                    Container(
                                      width: 32,
                                      height: 32,
                                      margin: const EdgeInsetsDirectional.only(
                                        end: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            theme.colorScheme.primary,
                                            theme.colorScheme.tertiary,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.support_agent_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                  Flexible(
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            (isMe ? 0.75 : 0.65),
                                      ),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? theme.colorScheme.primary
                                            : theme
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(18)
                                            .copyWith(
                                              bottomRight: isMe
                                                  ? const Radius.circular(4)
                                                  : const Radius.circular(18),
                                              bottomLeft: !isMe
                                                  ? const Radius.circular(4)
                                                  : const Radius.circular(18),
                                            ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.06,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (hasImage)
                                            GestureDetector(
                                              onTap: () => _viewImage(
                                                context,
                                                msg.imageUrl!,
                                              ),
                                              child: CachedNetworkImage(
                                                imageUrl:
                                                    ApiService.resolveMediaUrl(
                                                      msg.imageUrl,
                                                    ),
                                                fit: BoxFit.cover,
                                                placeholder: (a, b) => Container(
                                                  height: 180,
                                                  color: theme
                                                      .colorScheme
                                                      .surfaceContainerHighest,
                                                  child: const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                ),
                                                errorWidget: (a, b, c) => Container(
                                                  height: 120,
                                                  color: theme
                                                      .colorScheme
                                                      .surfaceContainerHighest,
                                                  child: const Icon(
                                                    Icons.broken_image_rounded,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          Padding(
                                            padding: EdgeInsets.fromLTRB(
                                              12,
                                              hasImage && !hasText ? 6 : 10,
                                              12,
                                              8,
                                            ),
                                            child: Column(
                                              crossAxisAlignment: isMe
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment.start,
                                              children: [
                                                if (!isMe)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 4,
                                                        ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          isSorani
                                                              ? 'پشتیوانی'
                                                              : 'Piştgirî',
                                                          style: theme
                                                              .textTheme
                                                              .labelMedium
                                                              ?.copyWith(
                                                                color: theme
                                                                    .colorScheme
                                                                    .primary,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Icon(
                                                          Icons
                                                              .verified_rounded,
                                                          size: 14,
                                                          color: theme
                                                              .colorScheme
                                                              .primary,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                if (hasText)
                                                  Text(
                                                    textAlign: TextAlign.end,
                                                    msg.message,
                                                    style: theme
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          color: isMe
                                                              ? theme
                                                                    .colorScheme
                                                                    .onPrimary
                                                              : theme
                                                                    .colorScheme
                                                                    .onSurface,
                                                        ),
                                                  ),
                                                if (hasText)
                                                  const SizedBox(height: 4),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,

                                                  children: [
                                                    Text(
                                                      _formatMessageTime(
                                                        msg.createdAt,
                                                      ),
                                                      style: theme
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            color:
                                                                (isMe
                                                                        ? theme
                                                                              .colorScheme
                                                                              .onPrimary
                                                                        : theme
                                                                              .colorScheme
                                                                              .onSurface)
                                                                    .withOpacity(
                                                                      0.55,
                                                                    ),
                                                            fontSize: 10,
                                                          ),
                                                    ),
                                                    if (isMe) ...[
                                                      const SizedBox(width: 4),
                                                      Icon(
                                                        msg.isRead
                                                            ? Icons.done_all
                                                            : Icons.done,
                                                        size: 13,
                                                        color: msg.isRead
                                                            ? Colors
                                                                  .blue
                                                                  .shade200
                                                            : theme
                                                                  .colorScheme
                                                                  .onPrimary
                                                                  .withOpacity(
                                                                    0.6,
                                                                  ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // Input area
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: theme.dividerColor.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Text input area (WhatsApp style)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: theme.dividerColor.withOpacity(0.05),
                            ),
                          ),
                          padding: const EdgeInsets.only(left: 4, right: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Left-side emoji/plus could go here, or we use it for image
                              IconButton(
                                onPressed: _isSending ? null : _sendImage,
                                icon: Icon(
                                  Icons.add_photo_alternate_rounded,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                  size: 24,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  maxLines: 5,
                                  minLines: 1,
                                  textInputAction: TextInputAction.newline,
                                  decoration: InputDecoration(
                                    hintText: isSorani
                                        ? 'نامەیەک بنووسە...'
                                        : 'Peyamek binivîse...',
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 8,
                                    ),
                                    hintStyle: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.4),
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Send button
                      GestureDetector(
                        onTap: _isSending ? null : _sendMessage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: _isSending
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                )
                              : Icon(
                                  Icons.send_rounded,
                                  color: theme.colorScheme.onPrimary,
                                  size: 20,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _viewImage(BuildContext context, String imageKey) {
    final url = ApiService.resolveMediaUrl(imageKey);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (a, b) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (a, b, c) => const Icon(
                Icons.broken_image_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
