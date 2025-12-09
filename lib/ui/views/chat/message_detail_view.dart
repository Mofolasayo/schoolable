import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:stacked/stacked.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/supabase_service.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:schoolable/ui/common/widgets/app_avatar.dart'; // Added import

class MessageDetailViewModel extends BaseViewModel {
  final SupabaseService _supabaseService = locator<SupabaseService>();

  final String channelId;
  final String name;
  final bool isChannel;

  MessageDetailViewModel({
    required this.channelId,
    required this.name,
    this.isChannel = false,
  });

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;

  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> get members => _members;

  RealtimeChannel? _subscription;
  Timer? _timer;

  final TextEditingController messageController = TextEditingController();
  bool get canSendMessage => messageController.text.trim().isNotEmpty;

  void initialize() {
    setBusy(true);
    fetchMessages();
    subscribeToMessages();

    if (isChannel) {
      fetchMembers();
    }

    // Polling fallback
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => fetchMessages());

    messageController.addListener(notifyListeners);
  }

  Future<void> fetchMembers() async {
    _members = await _supabaseService.getChannelMembers(channelId);
    notifyListeners();
  }

  Future<void> fetchMessages() async {
    final msgs = await _supabaseService.getMessages(channelId);
    _messages = msgs;
    setBusy(false);
    notifyListeners();
  }

  void subscribeToMessages() {
    final channelName = 'public:messages:$channelId';
    _subscription = _supabaseService.client.channel(channelName);
    _subscription!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'channel_id',
            value: channelId,
          ),
          callback: (payload) {
            fetchMessages(); // Refresh on new message
          },
        )
        .subscribe();
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();
    await _supabaseService.sendMessage(channelId, text);
  }

  bool isMe(String userId) {
    return _supabaseService.currentUser?.id == userId;
  }

  String get currentUserId => _supabaseService.currentUser?.id ?? '';

  @override
  void dispose() {
    _subscription?.unsubscribe();
    _timer?.cancel();
    messageController.removeListener(notifyListeners);
    messageController.dispose();
    super.dispose();
  }

  String getAvatarUrl(String? gender, String seed) {
    return _supabaseService.getAvatarUrl(gender, seed);
  }
}

class MessageDetailView extends StackedView<MessageDetailViewModel> {
  final String channelId;
  final String name;
  final String? avatar;
  final bool isChannel;

  const MessageDetailView({
    Key? key,
    required this.channelId,
    required this.name,
    this.avatar,
    this.isChannel = false,
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
                          final isMe = viewModel.isMe(message['user_id']);
                          final content = message['content'] ?? '';
                          final timestamp = message['created_at'];

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? kcPrimaryColor : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                                boxShadow: [
                                  if (!isMe)
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      color: isMe ? Colors.white : kcTextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(timestamp),
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white.withValues(alpha: 0.7)
                                          : kcTextMutedColor,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
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
    // Controller is now in viewModel
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
    if (!isChannel) return; // TODO: Implement for DMs if needed

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
                      final profile = member['profiles'] ?? {};
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
                                radius:
                                    18, // 36/2 = 18? Original 40 -> 20. But border takes space.
                                // Wrapper container was 40x40.
                                // Child ClipOval was full size?
                                // Actually original code had Container width 40, height 40.
                                // AppAvatar(radius: 20) -> width 40.
                                // If I wrap in container with padding 1.5, I need slightly smaller avatar?
                                // radius 18.5? 20 - 1.5 = 18.5.

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
          channelId: channelId, name: name, isChannel: isChannel);

  @override
  void onViewModelReady(MessageDetailViewModel viewModel) =>
      viewModel.initialize();
}
