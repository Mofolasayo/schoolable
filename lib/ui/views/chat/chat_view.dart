import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'chat_viewmodel.dart';

import 'package:schoolable/ui/views/chat/message_detail_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:schoolable/ui/common/widgets/app_avatar.dart'; // Added import

class ChatView extends StackedView<ChatViewModel> {
  const ChatView({Key? key}) : super(key: key);

  @override
  Widget builder(BuildContext context, ChatViewModel viewModel, Widget? child) {
    if (viewModel.isBusy) {
      return const Center(child: CupertinoActivityIndicator());
    }
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
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: kcTextColor,
                    letterSpacing: -0.5,
                  ),
                ),
                InkWell(
                  onTap: () => _showNewMessageModal(context, viewModel),
                  child: Container(
                    padding: const EdgeInsets.all(10),
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kcBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search channels or messages',
                  hintStyle: TextStyle(color: kcTextMutedColor, fontSize: 14),
                  prefixIcon:
                      Icon(Icons.search, color: kcTextMutedColor, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

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
                      Text(
                        'CHANNELS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kcTextMutedColor.withOpacity(0.8),
                          letterSpacing: 1.0,
                        ),
                      ),
                      InkWell(
                        onTap: () => _showNewChannelModal(context, viewModel),
                        child: const Icon(Icons.add,
                            color: kcTextMutedColor, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kcBorderColor),
                    ),
                    child: Column(
                      children: viewModel.channels
                          .asMap()
                          .entries
                          .map((entry) => Column(
                                children: [
                                  _ChannelItem(channel: entry.value),
                                  if (entry.key !=
                                      viewModel.channels.length - 1)
                                    const Divider(
                                        height: 1,
                                        color: kcBorderColor,
                                        indent: 50),
                                ],
                              ))
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Direct Messages Section
                  Text(
                    'DIRECT MESSAGES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kcTextMutedColor.withOpacity(0.8),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kcBorderColor),
                    ),
                    child: Column(
                      children: viewModel.directMessages
                          .asMap()
                          .entries
                          .map((entry) => Column(
                                children: [
                                  _DirectMessageItem(user: entry.value),
                                  if (entry.key !=
                                      viewModel.directMessages.length - 1)
                                    const Divider(
                                        height: 1,
                                        color: kcBorderColor,
                                        indent: 68),
                                ],
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
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

  @override
  void onViewModelReady(ChatViewModel viewModel) => viewModel.initialize();

  void _showNewMessageModal(
      BuildContext parentContext, ChatViewModel viewModel) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const Text('New Message',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kcTextColor,
                          letterSpacing: -0.5,
                        )),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: kcTextMutedColor),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: kcBorderColor),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: viewModel.getStaffList(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 48,
                                color: kcTextMutedColor.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            const Text("No users found",
                                style: TextStyle(color: kcTextMutedColor)),
                          ],
                        ),
                      );
                    }
                    final users = snapshot.data!;
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: users.length,
                      separatorBuilder: (ctx, i) =>
                          const Divider(height: 24, color: Colors.transparent),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final fullName = user['full_name'] ?? 'Unknown';
                        final department = user['department'] ?? 'Staff';

                        // Generate Avatar URL if missing
                        final seed =
                            user['employee_id'] ?? user['email'] ?? fullName;
                        final displayAvatarUrl = user['avatar_url'] ??
                            viewModel.getAvatarUrl(user['gender'], seed);

                        return InkWell(
                          onTap: () async {
                            Navigator.pop(sheetContext); // Close modal

                            // Show loading overlay using parent context?
                            // Or just wait. simpler to just wait.

                            final channelId =
                                await viewModel.startDirectMessage(user['id']);

                            if (parentContext.mounted && channelId != null) {
                              Navigator.of(parentContext).push(
                                MaterialPageRoute(
                                  builder: (context) => MessageDetailView(
                                    channelId: channelId,
                                    name: fullName,
                                    avatar: displayAvatarUrl,
                                    isChannel: false,
                                    otherUserId: user['id'],
                                  ),
                                ),
                              );
                            }
                          },
                          child: Row(
                            children: [
                              // Robust Avatar Display
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: kcPrimaryColor, width: 2),
                                ),
                                child: ClipOval(
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: _buildAvatar(
                                        displayAvatarUrl, fullName),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: kcTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      department,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: kcTextMutedColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: kcTextMutedColor),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url, String name) {
    if (url != null && url.isNotEmpty) {
      if (url.endsWith('.svg') || url.contains('/svg')) {
        return SvgPicture.network(
          url,
          fit: BoxFit.cover,
          placeholderBuilder: (BuildContext context) => Container(
              padding: const EdgeInsets.all(10),
              child: const CircularProgressIndicator(strokeWidth: 2)),
        );
      } else {
        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Center(
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: kcPrimaryColor, fontWeight: FontWeight.bold))),
        );
      }
    }
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: kcPrimaryColor, fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  void _showNewChannelModal(BuildContext context, ChatViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) =>
            _CreateChannelSheet(viewModel: viewModel),
      ),
    );
  }
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
              channelId: channel.id,
              name: channel.name,
              isChannel: true,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: channel.hasUnread
                    ? kcPrimaryColor.withOpacity(0.1)
                    : kcBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: channel.hasUnread ? kcPrimaryColor : kcTextMutedColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                channel.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      channel.hasUnread ? FontWeight.w600 : FontWeight.w500,
                  color: channel.hasUnread ? kcTextColor : kcTextMutedColor,
                ),
              ),
            ),
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
              channelId: user.id, // ID is channelId for DMs
              name: user.name,
              avatar: user.avatar,
              isChannel: false,
              otherUserId: user.otherUserId,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: user.unreadCount > 0
                          ? kcPrimaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: AppAvatar(
                    imageUrl:
                        user.avatar.startsWith('http') ? user.avatar : null,
                    radius: 24,
                    fallbackInitials: user.name,
                  ),
                ),
                if (user.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
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
                          fontSize: 14,
                          fontWeight: user.unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: kcTextColor,
                        ),
                      ),
                      Text(
                        user.time,
                        style: TextStyle(
                          fontSize: 11,
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
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.lastMessage,
                          style: TextStyle(
                            fontSize: 12,
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

class _CreateChannelSheet extends StatefulWidget {
  final ChatViewModel viewModel;

  const _CreateChannelSheet({required this.viewModel});

  @override
  State<_CreateChannelSheet> createState() => _CreateChannelSheetState();
}

class _CreateChannelSheetState extends State<_CreateChannelSheet> {
  final _nameController = TextEditingController();
  bool _isPrivate = false;
  List<Map<String, dynamic>> _allUsers = [];
  final Set<String> _selectedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await widget.viewModel.getStaffList();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                const Text('Create Channel',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kcTextColor,
                      letterSpacing: -0.5,
                    )),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: kcTextMutedColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kcBorderColor),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Name Input
                const Text('Channel Name',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. marketing-updates',
                    hintStyle: const TextStyle(color: kcTextMutedColor),
                    prefixText: '# ',
                    filled: true,
                    fillColor: kcBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),

                const SizedBox(height: 24),

                // Privacy Toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: kcBorderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kcPrimaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_rounded,
                            size: 20, color: kcPrimaryColor),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Private Channel',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            SizedBox(height: 4),
                            Text('Only invited members can access this channel',
                                style: TextStyle(
                                    fontSize: 12, color: kcTextMutedColor)),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _isPrivate,
                        onChanged: (val) => setState(() => _isPrivate = val),
                        activeColor: kcPrimaryColor,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Members Selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add Members (${_selectedIds.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (_selectedIds.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => _selectedIds.clear()),
                        child: const Text('Clear all',
                            style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: kcBorderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    height: 200, // Fixed height scrollable area for members
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _allUsers.length,
                      itemBuilder: (context, index) {
                        final user = _allUsers[index];
                        final id = user['id'];
                        final isSelected = _selectedIds.contains(id);
                        final fullName = user['full_name'] ?? 'Unknown';
                        final seed =
                            user['employee_id'] ?? user['email'] ?? fullName;
                        final avatarUrl = user['avatar_url'] ??
                            widget.viewModel.getAvatarUrl(user['gender'], seed);

                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedIds.remove(id);
                              } else {
                                _selectedIds.add(id);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  padding: const EdgeInsets.all(1.5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: kcPrimaryColor, width: 1.5),
                                  ),
                                  child: ClipOval(
                                    child: (avatarUrl.endsWith('.svg') ||
                                            avatarUrl.contains('/svg'))
                                        ? SvgPicture.network(
                                            avatarUrl,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.network(
                                            avatarUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error,
                                                    stackTrace) =>
                                                const Icon(Icons.person,
                                                    size: 20,
                                                    color: kcTextMutedColor),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(fullName,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500)),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? kcPrimaryColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: isSelected
                                            ? kcPrimaryColor
                                            : kcBorderColor,
                                        width: 1.5),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check,
                                          size: 16, color: Colors.white)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Footer Actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameController.text.isNotEmpty) {
                    widget.viewModel.createNewChannel(
                      _nameController.text,
                      _isPrivate,
                      initialMembers: _selectedIds.toList(),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kcPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Create Channel',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
