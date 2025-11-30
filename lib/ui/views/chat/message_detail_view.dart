import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';

class MessageDetailViewModel extends BaseViewModel {
  final String name;
  final bool isChannel;

  MessageDetailViewModel({required this.name, this.isChannel = false});

  final messages = [
    _Message(
      text: 'Hey, how are you doing?',
      isMe: false,
      time: '09:41 AM',
    ),
    _Message(
      text: 'I\'m doing great! Just working on the new dashboard.',
      isMe: true,
      time: '09:42 AM',
    ),
    _Message(
      text: 'That sounds awesome. Can I see a preview?',
      isMe: false,
      time: '09:45 AM',
    ),
    _Message(
      text: 'Sure! Sending it over now.',
      isMe: true,
      time: '09:46 AM',
    ),
  ];
}

class _Message {
  final String text;
  final bool isMe;
  final String time;

  _Message({required this.text, required this.isMe, required this.time});
}

class MessageDetailView extends StackedView<MessageDetailViewModel> {
  final String name;
  final bool isChannel;

  const MessageDetailView({
    Key? key,
    required this.name,
    this.isChannel = false,
  }) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    MessageDetailViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: kcTextColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            if (!isChannel)
              const CircleAvatar(
                radius: 16,
                backgroundColor: kcPrimaryColor,
                child: Text('MO',
                    style: TextStyle(fontSize: 12, color: Colors.white)),
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
                if (!isChannel)
                  const Text(
                    'Online',
                    style: TextStyle(
                      color: kcTealColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: kcBorderColor, height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: viewModel.messages.length,
              itemBuilder: (context, index) {
                final message = viewModel.messages[index];
                return Align(
                  alignment: message.isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: message.isMe ? kcPrimaryColor : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(message.isMe ? 16 : 4),
                        bottomRight: Radius.circular(message.isMe ? 4 : 16),
                      ),
                      boxShadow: [
                        if (!message.isMe)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: TextStyle(
                            color: message.isMe ? Colors.white : kcTextColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message.time,
                          style: TextStyle(
                            color: message.isMe
                                ? Colors.white.withOpacity(0.7)
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: kcBorderColor)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: kcTextMutedColor),
                  onPressed: () {},
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: kcBackgroundColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: kcTextMutedColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: kcPrimaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  MessageDetailViewModel viewModelBuilder(BuildContext context) =>
      MessageDetailViewModel(name: name, isChannel: isChannel);
}
