import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:schoolable/ui/views/tasks/task_model.dart';
import 'package:schoolable/ui/views/tasks/task_detail_viewmodel.dart';
import 'package:url_launcher/url_launcher.dart';

class TaskDetailView extends StackedView<TaskDetailViewModel> {
  const TaskDetailView({
    super.key,
    required this.task,
    this.onTaskUpdated,
  });

  final Task task;
  final ValueChanged<Task>? onTaskUpdated;

  @override
  Widget builder(
      BuildContext context, TaskDetailViewModel viewModel, Widget? child) {
    final currentTask = viewModel.task;
    final commentController = TextEditingController();

    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kcTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Task Details',
          style: TextStyle(
            color: kcTextColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: viewModel.refreshTask,
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        Text(
                          currentTask.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: kcTextColor,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatusBadge(
                              status: viewModel.displayStatus,
                              color: viewModel.getStatusColor(),
                            ),
                            _PriorityBadge(priority: currentTask.priority),
                            if (!_isNoDueDate(currentTask.due))
                              _MetaPill(
                                icon: Icons.calendar_today_rounded,
                                label: currentTask.due,
                                color: kcTextMutedColor,
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildAvatar(currentTask.assigneeAvatar, 32),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                currentTask.assignee,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kcTextColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        if (currentTask.subtasks.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kcSurfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: kcBorderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Progress',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: kcTextColor,
                                      ),
                                    ),
                                    Text(
                                      '${currentTask.progress}%',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: kcPrimaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: currentTask.progress / 100,
                                    backgroundColor: kcBorderColor,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            kcPrimaryColor),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kcSurfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kcBorderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kcTextMutedColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currentTask.description.isNotEmpty
                                    ? currentTask.description
                                    : 'No description provided.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: kcTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (currentTask.attachments.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Attachments',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kcTextMutedColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...currentTask.attachments.map((attachment) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _AttachmentTile(
                                  attachment: attachment,
                                  onTap: () =>
                                      _openAttachment(context, attachment.url),
                                ),
                              )),
                        ],

                        const SizedBox(height: 20),

                        // Subtasks
                        if (currentTask.subtasks.isNotEmpty) ...[
                          const Text(
                            'Checklist',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kcTextMutedColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...currentTask.subtasks.map((subtask) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () => viewModel.toggleSubtask(subtask),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: kcSurfaceColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: subtask.completed
                                            ? kcPrimaryColor.withOpacity(0.3)
                                            : kcBorderColor,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: subtask.completed
                                                ? kcPrimaryColor
                                                : kcSurfaceColor,
                                            border: Border.all(
                                              color: subtask.completed
                                                  ? kcPrimaryColor
                                                  : kcBorderColor,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: subtask.completed
                                              ? const Icon(Icons.check,
                                                  size: 12, color: Colors.white)
                                              : null,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            subtask.title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: subtask.completed
                                                  ? kcTextMutedColor
                                                  : kcTextColor,
                                              decoration: subtask.completed
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )),

                          const SizedBox(height: 24),
                        ],

                        // Actions
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: viewModel.isCompleted
                                ? null
                                : () async {
                                    final success =
                                        await viewModel.markAsComplete();
                                    if (success) {
                                      onTaskUpdated?.call(viewModel.task);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: viewModel.isCompleted
                                  ? Colors.grey[300]
                                  : kcPrimaryColor,
                              disabledBackgroundColor: Colors.grey[300],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              viewModel.isCompleted
                                  ? 'Completed'
                                  : 'Mark as Complete',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: viewModel.isCompleted
                                    ? Colors.grey[600]
                                    : Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Activity / Comments
                        const Text(
                          'Activity',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kcTextMutedColor,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (currentTask.comments.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  Icon(Icons.chat_bubble_outline,
                                      size: 40, color: Colors.grey[300]),
                                  const SizedBox(height: 8),
                                  Text('No comments yet',
                                      style:
                                          TextStyle(color: Colors.grey[400])),
                                ],
                              ),
                            ),
                          ),

                        ...currentTask.comments.map((comment) => Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildAvatar(comment.avatar, 36),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              comment.author,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: kcTextColor,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatTimestamp(
                                                  comment.timestamp),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: kcTextMutedColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          comment.text,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color:
                                                Color(0xFF374151), // Gray 700
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        const SizedBox(height: 100), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        decoration: BoxDecoration(
          color: kcSurfaceColor,
          border: const Border(top: BorderSide(color: kcBorderColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: kcSurfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kcBorderColor),
                ),
                child: TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    hintText: 'Write a comment...',
                    hintStyle: TextStyle(fontSize: 14, color: kcTextMutedColor),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      viewModel.addComment(val);
                      commentController.clear();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            ValueListenableBuilder<TextEditingValue>(
                valueListenable: commentController,
                builder: (context, value, child) {
                  final isEnabled = value.text.trim().isNotEmpty;
                  return Container(
                    decoration: BoxDecoration(
                      color: isEnabled ? kcPrimaryColor : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      enableFeedback: true,
                      onPressed: isEnabled
                          ? () {
                              final text = commentController.text;
                              if (text.trim().isNotEmpty) {
                                viewModel.addComment(text);
                                commentController.clear();
                                FocusScope.of(context).unfocus();
                              }
                            }
                          : null,
                      icon: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                      constraints:
                          const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),
                  );
                }),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String url, double size) {
    if (url.endsWith('.svg') || url.contains('api.dicebear.com')) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: ClipOval(
          child: SvgPicture.network(
            url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholderBuilder: (_) =>
                Icon(Icons.person, size: size * 0.6, color: kcTextMutedColor),
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      return '${date.day}/${date.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  TaskDetailViewModel viewModelBuilder(BuildContext context) =>
      TaskDetailViewModel(task);

  @override
  void onViewModelReady(TaskDetailViewModel viewModel) =>
      viewModel.initialize();

  bool _isNoDueDate(String due) {
    final normalized = due.toLowerCase().trim();
    return normalized.isEmpty ||
        normalized == 'no due date' ||
        normalized == 'overdue';
  }

  Future<void> _openAttachment(BuildContext context, String url) async {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attachment is not available')),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid attachment link')),
      );
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open attachment')),
      );
    }
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment, required this.onTap});

  final Attachment attachment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = attachment.name.trim().isEmpty ? 'Attachment' : attachment.name;
    final type = attachment.type.trim();
    final typeLabel = type.isEmpty
        ? 'File'
        : (type.contains('/') ? type.split('/').last : type).toUpperCase();
    final meta = [
      if (typeLabel.isNotEmpty) typeLabel,
      if (attachment.size.trim().isNotEmpty) attachment.size.trim(),
    ].join(' • ');
    final isEnabled = attachment.url.trim().isNotEmpty;

    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kcSurfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kcBorderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kcPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.insert_drive_file_rounded,
                  size: 18, color: kcPrimaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kcTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta.isNotEmpty ? meta : 'File',
                    style: const TextStyle(
                      fontSize: 12,
                      color: kcTextMutedColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: isEnabled ? kcPrimaryColor : kcTextMutedColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kcSurfaceColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kcBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: kcTextMutedColor,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;

  const _PriorityBadge({required this.priority});

  Color _getColor() {
    switch (priority.toLowerCase()) {
      case 'high':
        return kcRoseColor;
      case 'medium':
        return kcAmberColor;
      case 'low':
        return kcTealColor;
      default:
        return kcTextMutedColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            priority,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
