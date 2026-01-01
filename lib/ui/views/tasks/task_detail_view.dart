import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:schoolable/ui/views/tasks/task_model.dart';
import 'package:schoolable/ui/views/tasks/task_detail_viewmodel.dart';

class TaskDetailView extends StackedView<TaskDetailViewModel> {
  const TaskDetailView({super.key, required this.task});

  final Task task;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: kcTextColor),
            onPressed: () {},
          ),
        ],
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
                        // Title
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                currentTask.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: kcTextColor,
                                  height: 1.2,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Meta Row
                        Row(
                          children: [
                            _StatusBadge(
                                status: viewModel.status,
                                color: viewModel.getStatusColor()),
                            const SizedBox(width: 8),
                            _PriorityBadge(priority: currentTask.priority),
                            const SizedBox(width: 8),
                            if (currentTask.due != 'No due date')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded,
                                        size: 12, color: kcTextMutedColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      currentTask.due,
                                      style: const TextStyle(
                                        color: kcTextColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Progress Section
                        if (currentTask.subtasks.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Progress',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: kcTextColor,
                                ),
                              ),
                              Text(
                                '${currentTask.progress}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: kcPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: currentTask.progress / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  kcPrimaryColor),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        // Description Section
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kcTextColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentTask.description.isNotEmpty
                              ? currentTask.description
                              : 'No description provided.',
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: Color(0xFF4B5563),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Assignee Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              _buildAvatar(currentTask.assigneeAvatar, 48),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Assigned to',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: kcTextMutedColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentTask.assignee,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: kcTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Subtasks
                        if (currentTask.subtasks.isNotEmpty) ...[
                          const Text(
                            'Checklist',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kcTextColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...currentTask.subtasks.map((subtask) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () => viewModel.toggleSubtask(subtask),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: subtask.completed
                                            ? kcPrimaryColor.withOpacity(0.3)
                                            : Colors.grey[200]!,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: subtask.completed
                                                ? kcPrimaryColor
                                                : Colors.white,
                                            border: Border.all(
                                              color: subtask.completed
                                                  ? kcPrimaryColor
                                                  : Colors.grey[300]!,
                                              width: 2,
                                            ),
                                          ),
                                          child: subtask.completed
                                              ? const Icon(Icons.check,
                                                  size: 16, color: Colors.white)
                                              : null,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            subtask.title,
                                            style: TextStyle(
                                              fontSize: 15,
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

                          // Add New Subtask Field
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.add_rounded,
                                    color: kcTextMutedColor),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      hintText: 'Add checklist item...',
                                      hintStyle: TextStyle(
                                          color: kcTextMutedColor,
                                          fontSize: 14),
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: (value) {
                                      if (value.isNotEmpty) {
                                        viewModel.addSubtask(value);
                                      }
                                    },
                                    textInputAction: TextInputAction.done,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        // Actions
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: viewModel.isCompleted
                                ? null
                                : viewModel.markAsComplete,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kcTextColor,
                          ),
                        ),
                        const SizedBox(height: 20),

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
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6), // Gray 100
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.transparent),
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
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 12, color: color),
          const SizedBox(width: 4),
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
