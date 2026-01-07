import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/services/cache_service.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:schoolable/ui/common/widgets/app_avatar.dart';

class MessageDetailViewModel extends BaseViewModel {
  final BackendApiService _backendService = locator<BackendApiService>();
  final CacheService _cacheService = locator<CacheService>();

  final String channelId;
  final String name;
  final bool isChannel;
  final String? otherUserId; // For DMs - to track online status

  MessageDetailViewModel({
    required this.channelId,
    required this.name,
    this.isChannel = false,
    this.otherUserId,
  });

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;

  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> get members => _members;

  bool _isOtherUserOnline = false;
  bool get isOtherUserOnline => _isOtherUserOnline;

  Timer? _timer;
  Timer? _onlineTimer;

  final TextEditingController messageController = TextEditingController();
  bool get canSendMessage => messageController.text.trim().isNotEmpty;

  void initialize() async {
    setBusy(true);

    // 1. Load cached messages immediately for instant display
    await _loadCachedMessages();

    // 2. Mark as read immediately when opening
    await _sendReadReceipt();

    // 3. Fetch fresh messages in background
    await fetchMessages();

    if (isChannel) {
      fetchMembers();
    } else if (otherUserId != null) {
      // For DMs, check if other user is online
      _checkOnlineStatus();
      _onlineTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _checkOnlineStatus(),
      );
    }

    // 4. Polling every 3 seconds for new messages (faster for chat)
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => fetchMessages());

    messageController.addListener(notifyListeners);
    setBusy(false);
  }

  /// Load cached messages for instant display
  Future<void> _loadCachedMessages() async {
    final cached = await _cacheService.getCachedMessages(channelId);
    if (cached != null && cached.isNotEmpty) {
      _messages = cached.cast<Map<String, dynamic>>();
      notifyListeners();
    }
  }

  /// Send read receipt to server
  Future<void> _sendReadReceipt() async {
    try {
      await _backendService.markChannelAsRead(channelId);
      print('✅ Read receipt sent for channel: $channelId');
    } catch (e) {
      print('⚠️ Failed to send read receipt: $e');
    }
  }

  Future<void> _checkOnlineStatus() async {
    if (otherUserId == null) return;
    final onlineIds = await _backendService.getOnlineUserIds();
    _isOtherUserOnline = onlineIds.contains(otherUserId);
    notifyListeners();
  }

  Future<void> fetchMembers() async {
    _members = await _backendService.getChannelMembers(channelId);
    notifyListeners();
  }

  Future<void> fetchMessages() async {
    final previousCount = _messages.length;
    final msgs = await _backendService.getMessages(channelId);
    _messages = msgs;

    // Cache messages for offline access
    await _cacheService.cacheMessages(channelId, msgs);

    // If we have new messages, send read receipt
    if (msgs.length > previousCount) {
      await _sendReadReceipt();
    }

    notifyListeners();
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();

    // Optimistic update: Add message to local state immediately
    final optimisticMessage = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'content': text,
      'user_id': _backendService.currentUserId,
      'created_at': DateTime.now().toIso8601String(),
      'sending': true, // Mark as pending
    };
    _messages = [optimisticMessage, ..._messages];
    notifyListeners();

    // Also add to cache for persistence
    await _cacheService.addMessageToCache(channelId, optimisticMessage);

    // Send to server
    final result = await _backendService.sendMessage(channelId, text);

    if (result != null) {
      // Replace optimistic message with real one
      _messages.removeWhere((m) => m['id'] == optimisticMessage['id']);
      _messages = [result, ..._messages];

      // Update cache with real message
      await _cacheService.cacheMessages(channelId, _messages);
    }

    // Refresh messages to ensure sync
    await fetchMessages();
  }

  bool isMe(String userId) {
    return _backendService.currentUserId == userId;
  }

  String get currentUserId => _backendService.currentUserId ?? '';

  @override
  void dispose() {
    _timer?.cancel();
    _onlineTimer?.cancel();
    messageController.removeListener(notifyListeners);
    messageController.dispose();
    super.dispose();
  }

  String getAvatarUrl(String? gender, String seed) {
    return _backendService.getAvatarUrl(gender, seed);
  }
}

class MessageDetailView extends StackedView<MessageDetailViewModel> {
  final String channelId;
  final String name;
  final String? avatar;
  final bool isChannel;
  final String? otherUserId; // For DMs - to track online status

  const MessageDetailView({
    Key? key,
    required this.channelId,
    required this.name,
    this.avatar,
    this.isChannel = false,
    this.otherUserId,
  }) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    MessageDetailViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: kcTextColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: InkWell(
          onTap: () => _showChannelDetails(context, viewModel),
          child: Row(
            children: [
              if (!isChannel)
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kcPrimaryColor, width: 1.5),
                      ),
                      child: AppAvatar(
                        imageUrl: avatar,
                        radius: 16,
                        fallbackInitials: name,
                      ),
                    ),
                    // Online status indicator
                    if (viewModel.isOtherUserOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              if (!isChannel) const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isChannel ? '#$name' : name,
                    style: const TextStyle(
                      color: kcTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Show online/offline status for DMs
                  if (!isChannel)
                    Text(
                      viewModel.isOtherUserOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: viewModel.isOtherUserOnline
                            ? Colors.green
                            : kcTextMutedColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: kcBorderColor, height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: viewModel.isBusy
                ? const Center(child: CupertinoActivityIndicator())
                : viewModel.messages.isEmpty
                    ? const Center(
                        child: Text("No messages yet",
                            style: TextStyle(color: kcTextMutedColor)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        reverse: true,
                        itemCount: viewModel.messages.length,
                        itemBuilder: (context, index) {
                          final message = viewModel.messages[index];
                          final isMe = viewModel.isMe(message['user_id'] ?? '');
                          final content = message['content'] ?? '';
                          final timestamp = message['created_at'];

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe ? kcPrimaryColor : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft:
                                          Radius.circular(isMe ? 16 : 4),
                                      bottomRight:
                                          Radius.circular(isMe ? 4 : 16),
                                    ),
                                    boxShadow: [
                                      if (!isMe)
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.05),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (!isMe && isChannel) ...[
                                        Text(
                                            message['sender']?['full_name'] ??
                                                'Unknown',
                                            style: const TextStyle(
                                              color: kcPrimaryColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            )),
                                        const SizedBox(height: 4),
                                      ],
                                      Text(
                                        content,
                                        style: TextStyle(
                                          color:
                                              isMe ? Colors.white : kcTextColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatTime(timestamp),
                                        style: const TextStyle(
                                          color: kcTextMutedColor,
                                          fontSize: 10,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        _buildReadReceiptIndicator(message),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          _buildMessageInput(viewModel),
        ],
      ),
    );
  }

  Widget _buildMessageInput(MessageDetailViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kcBorderColor)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: kcTextMutedColor),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: kcBackgroundColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: viewModel.messageController,
                onSubmitted: (_) => viewModel.sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: kcTextMutedColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap:
                viewModel.canSendMessage ? () => viewModel.sendMessage() : null,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: viewModel.canSendMessage
                    ? kcPrimaryColor
                    : kcTextMutedColor.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showChannelDetails(
      BuildContext context, MessageDetailViewModel viewModel) {
    if (!isChannel) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    '#$name',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kcTextColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: kcTextMutedColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text('Members',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (viewModel.members.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                          child: Text("Loading members...",
                              style: TextStyle(color: kcTextMutedColor))),
                    )
                  else
                    ...viewModel.members.map((member) {
                      final profile = member['profiles'] ?? member;
                      final fullName = profile['full_name'] ?? 'Unknown';
                      final seed = profile['employee_id'] ??
                          profile['email'] ??
                          fullName;
                      final avatarUrl = profile['avatar_url'] ??
                          viewModel.getAvatarUrl(profile['gender'], seed);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kcBackgroundColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: kcBorderColor.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: kcPrimaryColor, width: 1.5),
                              ),
                              child: AppAvatar(
                                imageUrl: avatarUrl,
                                radius: 18,
                                fallbackInitials: fullName,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(fullName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  const Text('Member',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: kcTextMutedColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build read receipt indicator (checkmarks) for sent messages
  /// - Single gray check: Message sent
  /// - Double gray checks: Message delivered
  /// - Double blue checks: Message read
  Widget _buildReadReceiptIndicator(Map<String, dynamic> message) {
    final isSending = message['sending'] == true;
    final isRead = message['read_at'] != null || message['is_read'] == true;
    final isDelivered =
        message['id'] != null && !message['id'].toString().startsWith('temp_');

    if (isSending) {
      // Still sending - show clock icon
      return Icon(
        Icons.access_time,
        size: 12,
        color: Colors.white.withValues(alpha: 0.6),
      );
    } else if (isRead) {
      // Read - double blue checks
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.done_all,
            size: 14,
            color: Colors.lightBlueAccent.shade100,
          ),
        ],
      );
    } else if (isDelivered) {
      // Delivered - double gray checks
      return Icon(
        Icons.done_all,
        size: 14,
        color: Colors.white.withValues(alpha: 0.7),
      );
    } else {
      // Sent - single check
      return Icon(
        Icons.done,
        size: 14,
        color: Colors.white.withValues(alpha: 0.7),
      );
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  MessageDetailViewModel viewModelBuilder(BuildContext context) =>
      MessageDetailViewModel(
        channelId: channelId,
        name: name,
        isChannel: isChannel,
        otherUserId: otherUserId,
      );

  @override
  void onViewModelReady(MessageDetailViewModel viewModel) =>
      viewModel.initialize();
}
