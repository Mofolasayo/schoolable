import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/supabase_service.dart';

class ChatChannel {
  final String id;
  final String name;
  final bool hasUnread;

  ChatChannel({required this.id, required this.name, this.hasUnread = false});
}

class ChatUser {
  final String id; // Channel ID for the DM
  final String name;
  final String avatar;
  final bool isOnline;
  final String lastMessage;
  final String time;
  final int unreadCount;

  ChatUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.isOnline,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
  });
}

class ChatViewModel extends BaseViewModel {
  final _supabaseService = locator<SupabaseService>();

  List<ChatChannel> _channels = [];
  List<ChatChannel> get channels => _channels;

  List<ChatUser> _directMessages = [];
  List<ChatUser> get directMessages => _directMessages;

  void initialize() async {
    setBusy(true);
    await fetchChannels();
    setBusy(false);
  }

  Future<void> fetchChannels() async {
    final rawChannels = await _supabaseService.getMyChannels();
    final myId = _supabaseService.currentUser?.id;

    _channels = [];
    _directMessages = [];

    // Separate channels and DMs
    // Note: This logic is imperfect for DMs because we don't have the "other user" info easily
    // without fetching members. For now, we might see generic names for DMs unless we fetch members.
    // To fix this proper, we'd need to fetch members for each DM channel.

    final futures = rawChannels.map((c) async {
      final id = c['id'];
      final type = c['type'];
      final name = c['name'];

      // Fetch last message content (could be optimized further by DB join)
      final lastMsg = await _supabaseService.getLastMessageContent(id);
      final lastMessageText = lastMsg ?? "Start chatting...";

      if (type == 'dm') {
        String displayName = "Direct Message";
        String avatar = "DM";

        if (myId != null) {
          // Find the other member from eagerly fetched data
          final members = c['members'] as List<dynamic>?;
          final otherMember = members?.firstWhere(
            (m) => m['user_id'] != myId,
            orElse: () => null,
          );

          if (otherMember != null && otherMember['profiles'] != null) {
            final profile = otherMember['profiles'];
            displayName = profile['full_name'] ?? 'Unknown';

            // 1. Try uploaded avatar
            String? candidateAvatar = profile['avatar_url'];

            // 2. If none, generate DiceBear avatar
            if (candidateAvatar == null || candidateAvatar.isEmpty) {
              final seed =
                  profile['employee_id'] ?? profile['email'] ?? displayName;
              candidateAvatar =
                  _supabaseService.getAvatarUrl(profile['gender'], seed);
            }

            avatar = candidateAvatar;
          }
        }

        return ChatUser(
          id: id,
          name: displayName,
          avatar: avatar,
          isOnline: false,
          lastMessage: lastMessageText,
          time: "",
        );
      } else {
        return ChatChannel(
          id: id,
          name: name ?? 'Unknown',
          hasUnread: false,
        );
      }
    });

    final results = await Future.wait(futures);

    for (var item in results) {
      if (item is ChatUser) {
        _directMessages.add(item);
      } else if (item is ChatChannel) {
        _channels.add(item);
      }
    }
    notifyListeners();
  }

  Future<void> createNewChannel(String name, bool isPrivate,
      {List<String>? initialMembers}) async {
    setBusy(true);
    await _supabaseService.createChannel(name, isPrivate ? 'private' : 'public',
        initialMembers: initialMembers);
    await fetchChannels();
    setBusy(false);
  }

  Future<String> startDirectMessage(String userId) async {
    setBusy(true);
    final channelId =
        await _supabaseService.getOrCreateDirectMessageChannel(userId);
    await fetchChannels();
    setBusy(false);
    return channelId;
  }

  Future<List<Map<String, dynamic>>> getStaffList() async {
    return await _supabaseService.getAllStaff();
  }

  String getAvatarUrl(String? gender, String seed) {
    return _supabaseService.getAvatarUrl(gender, seed);
  }
}
