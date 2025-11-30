import 'package:stacked/stacked.dart';

class ChatChannel {
  final String name;
  final bool hasUnread;

  ChatChannel({required this.name, this.hasUnread = false});
}

class ChatUser {
  final String name;
  final String avatar;
  final bool isOnline;
  final String lastMessage;
  final String time;
  final int unreadCount;

  ChatUser({
    required this.name,
    required this.avatar,
    required this.isOnline,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
  });
}

class ChatViewModel extends BaseViewModel {
  final channels = [
    ChatChannel(name: 'general', hasUnread: true),
    ChatChannel(name: 'random'),
    ChatChannel(name: 'announcements'),
    ChatChannel(name: 'engineering'),
    ChatChannel(name: 'design', hasUnread: true),
  ];

  final directMessages = [
    ChatUser(
      name: 'Olivia Martin',
      avatar: 'OM',
      isOnline: true,
      lastMessage: 'Can you review the PR?',
      time: '2m',
      unreadCount: 2,
    ),
    ChatUser(
      name: 'Alex Johnson',
      avatar: 'AJ',
      isOnline: false,
      lastMessage: 'Thanks for the update!',
      time: '1h',
    ),
    ChatUser(
      name: 'Sarah Williams',
      avatar: 'SW',
      isOnline: true,
      lastMessage: 'Meeting in 10 mins',
      time: '3h',
    ),
    ChatUser(
      name: 'Michael Brown',
      avatar: 'MB',
      isOnline: false,
      lastMessage: 'Have a great weekend!',
      time: '1d',
    ),
  ];
}
