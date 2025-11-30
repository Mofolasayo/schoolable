import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'chat_viewmodel.dart';

import 'package:schoolable/ui/views/chat/message_detail_view.dart';

class ChatView extends StackedView<ChatViewModel> {
  const ChatView({Key? key}) : super(key: key);

  @override
  Widget builder(BuildContext context, ChatViewModel viewModel, Widget? child) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: kcTextColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kcBorderColor),
                  ),
                  child: const Icon(
                    Icons.edit_square,
                    color: kcTextColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kcBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search channels or messages',
                  hintStyle:
                      const TextStyle(color: kcTextMutedColor, fontSize: 14),
                  prefixIcon:
                      const Icon(Icons.search, color: kcTextMutedColor),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Channels Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Channels',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kcTextColor,
                        ),
                      ),
                      Icon(Icons.add, color: kcTextMutedColor, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...viewModel.channels
                      .map((channel) => _ChannelItem(channel: channel)),

                  const SizedBox(height: 32),

                  // Direct Messages Section
                  const Text(
                    'Direct Messages',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kcTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...viewModel.directMessages
                      .map((user) => _DirectMessageItem(user: user)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  ChatViewModel viewModelBuilder(BuildContext context) => ChatViewModel();
}

class _ChannelItem extends StatelessWidget {
  final ChatChannel channel;

  const _ChannelItem({required this.channel});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MessageDetailView(
              name: channel.name,
              isChannel: true,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: channel.hasUnread
                    ? kcPrimaryColor.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: channel.hasUnread ? kcPrimaryColor : kcTextMutedColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              channel.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    channel.hasUnread ? FontWeight.w600 : FontWeight.w500,
                color: channel.hasUnread ? kcTextColor : kcTextMutedColor,
              ),
            ),
            const Spacer(),
            if (channel.hasUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: kcPrimaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DirectMessageItem extends StatelessWidget {
  final ChatUser user;

  const _DirectMessageItem({required this.user});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MessageDetailView(
              name: user.name,
              isChannel: false,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: kcPrimaryColor.withOpacity(0.1),
                  child: Text(
                    user.avatar,
                    style: const TextStyle(
                      color: kcPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (user.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: kcTealColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: user.unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: kcTextColor,
                        ),
                      ),
                      Text(
                        user.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: user.unreadCount > 0
                              ? kcPrimaryColor
                              : kcTextMutedColor,
                          fontWeight: user.unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.lastMessage,
                          style: TextStyle(
                            fontSize: 13,
                            color: user.unreadCount > 0
                                ? kcTextColor
                                : kcTextMutedColor,
                            fontWeight: user.unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: kcPrimaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            user.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
