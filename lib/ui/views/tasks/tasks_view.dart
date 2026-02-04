import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:schoolable/ui/views/tasks/task_detail_view.dart';
import 'package:schoolable/ui/views/tasks/task_model.dart';
import 'package:schoolable/ui/views/tasks/tasks_viewmodel.dart';
import 'package:schoolable/ui/common/widgets/app_avatar.dart'; // Added import

class TasksView extends StackedView<TasksViewModel> {
  const TasksView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, TasksViewModel viewModel, Widget? child) {
    return Scaffold(
      backgroundColor: kcBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, viewModel),
              const SizedBox(height: 20),
              _buildMetrics(viewModel),
              const SizedBox(height: 10),

              Expanded(
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    CupertinoSliverRefreshControl(
                        onRefresh: viewModel.fetchTasks),
                    if (viewModel.isBusy && viewModel.tasks.isEmpty)
                      const SliverFillRemaining(
                        child: Center(child: CupertinoActivityIndicator()),
                      )
                    else if (viewModel.tasks.isEmpty)
                      const SliverFillRemaining(
                        child: Center(child: Text('No tasks found')),
                      )
                    else
                      Builder(
                        builder: (context) {
                          final tasks = viewModel.tasks;
                          final completedIndex =
                              tasks.indexWhere(viewModel.isTaskCompleted);
                          final showCompletedHeader = completedIndex != -1;
                          final itemCount =
                              tasks.length + (showCompletedHeader ? 1 : 0);

                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (showCompletedHeader &&
                                    index == completedIndex) {
                                  return _CompletedTasksHeader(
                                      withTopPadding: completedIndex > 0);
                                }

                                final taskIndex = showCompletedHeader &&
                                        index > completedIndex
                                    ? index - 1
                                    : index;
                                final task = tasks[taskIndex];
                                final statusLabel =
                                    viewModel.getStatusLabel(task);
                                final isOverdue = viewModel.isTaskOverdue(task);
                                final isInProgress =
                                    viewModel.isTaskInProgress(task);
                                final isCompleted =
                                    viewModel.isTaskCompleted(task);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _TaskCard(
                                    task: task,
                                    statusLabel: statusLabel,
                                    isOverdue: isOverdue,
                                    isInProgress: isInProgress,
                                    isCompleted: isCompleted,
                                    isCompleting:
                                        viewModel.isCompleting(task.id),
                                    onQuickComplete: () =>
                                        viewModel.quickCompleteTask(task),
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TaskDetailView(
                                            task: task,
                                            onTaskUpdated:
                                                viewModel.updateTask,
                                          ),
                                        ),
                                      );
                                      // Refresh on return
                                      viewModel.fetchTasks();
                                    },
                                  ),
                                );
                              },
                              childCount: itemCount,
                            ),
                          );
                        },
                      ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  TasksViewModel viewModelBuilder(BuildContext context) => TasksViewModel();

  @override
  void onViewModelReady(TasksViewModel viewModel) => viewModel.initialize();

  Widget _buildHeader(BuildContext context, TasksViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tasks',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: kcTextColor,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Your workstream at a glance',
              style: TextStyle(
                fontSize: 13,
                color: kcTextMutedColor,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _HeaderIconButton(
              icon: Icons.search_rounded,
              onTap: () => _openSearchPage(context, viewModel),
            ),
            const SizedBox(width: 10),
            _HeaderIconButton(
              icon: Icons.tune_rounded,
              onTap: () => _showStatusFilterSheet(context, viewModel),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetrics(TasksViewModel viewModel) {
    return Wrap(
      spacing: 10,
      runSpacing: 5,
      children: [
        _MetricCard(
          label: 'All',
          value: viewModel.totalCount.toString(),
          icon: Icons.circle,
          color: kcPrimaryColor,
        ),
        _MetricCard(
          label: 'In progress',
          value: viewModel.inProgressCount.toString(),
          icon: Icons.circle,
          color: Colors.blue,
        ),
       
        _MetricCard(
          label: 'Overdue',
          value: viewModel.overdueCount.toString(),
          icon: Icons.circle,
          color: kcRoseColor,
        ),
         _MetricCard(
          label: 'Done',
          value: viewModel.completedCount.toString(),
          icon: Icons.circle,
          color: Colors.green,
        ),
      ],
    );
  }

  Future<void> _openSearchPage(
      BuildContext context, TasksViewModel viewModel) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _TaskSearchView(viewModel: viewModel),
      ),
    );
  }

  Future<void> _showStatusFilterSheet(
      BuildContext context, TasksViewModel viewModel) async {
    final segments = viewModel.primaryStatusSegments;
    if (segments.isEmpty) return;
    var selectedValue = segments.any(
            (segment) => segment['value'] == viewModel.filterStatus)
        ? viewModel.filterStatus
        : segments.first['value'] ?? viewModel.filterStatus;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: kcSurfaceColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kcTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                ...segments.map((segment) {
                  final value = segment['value'] ?? '';
                  final label = segment['label'] ?? value;
                  return RadioListTile<String>(
                    value: value,
                    groupValue: selectedValue,
                    dense: true,
                    activeColor: kcPrimaryColor,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: kcTextColor,
                      ),
                    ),
                    onChanged: (next) {
                      if (next == null) return;
                      setState(() => selectedValue = next);
                    },
                  );
                }),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      viewModel.setFilterStatus(selectedValue);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kcPrimaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kcSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kcBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kcTextMutedColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kcTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: kcSurfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kcBorderColor),
        ),
        child: Icon(icon, size: 20, color: kcTextMutedColor),
      ),
    );
  }
}

class _CompletedTasksHeader extends StatelessWidget {
  const _CompletedTasksHeader({this.withTopPadding = true});

  final bool withTopPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: withTopPadding ? 12 : 0, bottom: 4),
      child: const Text(
        'Completed tasks',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: kcTextMutedColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _TaskSearchView extends StatefulWidget {
  const _TaskSearchView({required this.viewModel});

  final TasksViewModel viewModel;

  @override
  State<_TaskSearchView> createState() => _TaskSearchViewState();
}

class _TaskSearchViewState extends State<_TaskSearchView> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.viewModel.searchQuery);
    _controller.addListener(() {
      widget.viewModel.setSearchQuery(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Search tasks',
          style: TextStyle(
            color: kcTextColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: kcTextColor),
      ),
      body: AnimatedBuilder(
        animation: widget.viewModel,
        builder: (context, _) {
          final results = widget.viewModel.tasks;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  autofocus: true,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    hintStyle:
                        const TextStyle(color: kcTextMutedColor, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: kcTextMutedColor),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: kcTextMutedColor),
                            onPressed: () {
                              _controller.clear();
                              widget.viewModel.setSearchQuery('');
                            },
                          ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: kcBorderColor),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: kcBorderColor),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: kcPrimaryColor),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${results.length} match${results.length == 1 ? '' : 'es'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: kcTextMutedColor,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: results.isEmpty
                      ? const Center(
                          child: Text(
                            'No matching tasks',
                            style: TextStyle(
                              fontSize: 14,
                              color: kcTextMutedColor,
                            ),
                          ),
                        )
                      : Builder(
                          builder: (context) {
                            final completedIndex = results.indexWhere(
                                widget.viewModel.isTaskCompleted);
                            final showCompletedHeader = completedIndex != -1;
                            final itemCount = results.length +
                                (showCompletedHeader ? 1 : 0);

                            return ListView.separated(
                              itemCount: itemCount,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                if (showCompletedHeader &&
                                    index == completedIndex) {
                                  return _CompletedTasksHeader(
                                      withTopPadding: completedIndex > 0);
                                }

                                final taskIndex = showCompletedHeader &&
                                        index > completedIndex
                                    ? index - 1
                                    : index;
                                final task = results[taskIndex];
                                final statusLabel =
                                    widget.viewModel.getStatusLabel(task);
                                final isOverdue =
                                    widget.viewModel.isTaskOverdue(task);
                                final isInProgress =
                                    widget.viewModel.isTaskInProgress(task);
                                final isCompleted =
                                    widget.viewModel.isTaskCompleted(task);
                                return _TaskCard(
                                  task: task,
                                  statusLabel: statusLabel,
                                  isOverdue: isOverdue,
                                  isInProgress: isInProgress,
                                  isCompleted: isCompleted,
                                  isCompleting:
                                      widget.viewModel.isCompleting(task.id),
                                  onQuickComplete: () =>
                                      widget.viewModel.quickCompleteTask(task),
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => TaskDetailView(
                                          task: task,
                                          onTaskUpdated:
                                              widget.viewModel.updateTask,
                                        ),
                                      ),
                                    );
                                    widget.viewModel
                                        .fetchTasks(showLoader: false);
                                  },
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.statusLabel,
    required this.isOverdue,
    required this.isInProgress,
    required this.isCompleted,
    required this.isCompleting,
    required this.onQuickComplete,
    required this.onTap,
  });

  final Task task;
  final String statusLabel;
  final bool isOverdue;
  final bool isInProgress;
  final bool isCompleted;
  final bool isCompleting;
  final VoidCallback onQuickComplete;
  final VoidCallback onTap;

  Color _priorityColor(String priority) {
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

  Color _statusColor(String status, {required bool isOverdue}) {
    if (isOverdue) return Colors.red;
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'done':
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'review':
        return Colors.purple;
      case 'todo':
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.grey;
      default:
        return kcTextMutedColor;
    }
  }

  String _normalizeStatus(String status) {
    return status.trim().replaceAll(' ', '_').toUpperCase();
  }

  String _dueLabel(String due, bool isOverdue) {
    if (isOverdue) return 'Overdue';
    final lower = due.toLowerCase();
    if (lower.contains('today')) return 'Due today';
    if (lower.contains('tomorrow')) return 'Due tomorrow';
    if (lower.contains('no due')) return 'No due date';
    return 'Due';
  }

  Color _dueColor(String due, bool isOverdue) {
    if (isOverdue) return kcRoseColor;
    final lower = due.toLowerCase();
    if (lower.contains('today') || lower.contains('tomorrow')) {
      return kcAmberColor;
    }
    return kcTextMutedColor;
  }

  @override
  Widget build(BuildContext context) {
    final dueText = _dueLabel(task.due, isOverdue);
    final dueColor = _dueColor(task.due, isOverdue);
    final hasDue = task.due.toLowerCase() != 'no due date';
    final hasDescription = task.description.trim().isNotEmpty;
    final statusColor = isCompleted
        ? kcTextMutedColor
        : _statusColor(task.status, isOverdue: isOverdue);
    final priorityColor = isCompleted
        ? kcTextMutedColor
        : _priorityColor(task.priority);
    final attachmentCount = task.attachments.length;
    final commentCount = task.comments.length;
    final showProgress = isInProgress && task.progress > 0;
    final showPriority = task.priority.trim().toLowerCase() != 'medium';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCompleted ? kcBackgroundColor : kcSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? kcBorderColor.withOpacity(0.6)
                : kcBorderColor,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: kcTextColor,
                            ).copyWith(
                              color: isCompleted
                                  ? kcTextMutedColor
                                  : kcTextColor,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hasDescription) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isCompleted
                              ? kcTextMutedColor.withOpacity(0.7)
                              : kcTextMutedColor,
                          height: 1.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _InlineMeta(
                          label: statusLabel,
                          color: statusColor,
                          icon: Icons.circle,
                        ),
                        if (!isCompleted && hasDue && !isOverdue)
                          _InlineMeta(
                            label: dueText,
                            color: dueColor,
                            icon: Icons.schedule,
                          ),
                        if (showPriority)
                          _InlineMeta(
                            label: task.priority,
                            color: priorityColor,
                            icon: Icons.flag_rounded,
                          ),
                        // if (task.tag.trim().isNotEmpty)
                        //   _InlineMeta(
                        //     label: task.tag,
                        //     color: isCompleted
                        //         ? kcTextMutedColor
                        //         : kcPrimaryColor,
                        //     icon: Icons.label_rounded,
                        //   ),
                        if (showProgress)
                          _InlineMeta(
                            label: '${task.progress}%',
                            color: kcPrimaryColorDark,
                            icon: Icons.trending_up,
                          ),
                        if (attachmentCount > 0)
                          _InlineMeta(
                            label: '$attachmentCount',
                            color: kcTextMutedColor,
                            icon: Icons.attach_file,
                          ),
                        if (commentCount > 0)
                          _InlineMeta(
                            label: '$commentCount',
                            color: kcTextMutedColor,
                            icon: Icons.mode_comment_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
