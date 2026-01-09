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
              _buildHeader(),
              const SizedBox(height: 20),
              _buildMetrics(viewModel),
              const SizedBox(height: 20),
              _buildSearchAndFilters(viewModel),
              const SizedBox(height: 20),
              Expanded(
                child: viewModel.isBusy
                    ? const Center(child: CupertinoActivityIndicator())
                    : viewModel.tasks.isEmpty
                        ? CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              CupertinoSliverRefreshControl(
                                  onRefresh: viewModel.fetchTasks),
                              const SliverFillRemaining(
                                child: Center(child: Text('No tasks found')),
                              ),
                            ],
                          )
                        : CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              CupertinoSliverRefreshControl(
                                  onRefresh: viewModel.fetchTasks),
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final task = viewModel.tasks[index];
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _TaskCard(
                                        task: task,
                                        onTap: () async {
                                          await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  TaskDetailView(task: task),
                                            ),
                                          );
                                          // Refresh on return
                                          viewModel.fetchTasks();
                                        },
                                      ),
                                    );
                                  },
                                  childCount: viewModel.tasks.length,
                                ),
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

  @override
  TasksViewModel viewModelBuilder(BuildContext context) => TasksViewModel();

  @override
  void onViewModelReady(TasksViewModel viewModel) => viewModel.initialize();

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Management',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: kcTextColor,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Track your assigned tasks',
              style: TextStyle(
                fontSize: 13,
                color: kcTextMutedColor,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kcBorderColor),
          ),
          child:
              const Icon(Icons.more_horiz, color: kcTextMutedColor, size: 20),
        ),
      ],
    );
  }

  Widget _buildMetrics(TasksViewModel viewModel) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _MetricCard(
            label: 'Total Tasks',
            value: viewModel.totalCount.toString(),
            icon: Icons.access_time,
            color: kcPrimaryColor,
          ),
          const SizedBox(width: 12),
          _MetricCard(
            label: 'In Progress',
            value: viewModel.inProgressCount.toString(),
            icon: Icons.access_time,
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          _MetricCard(
            label: 'Completed',
            value: viewModel.completedCount.toString(),
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
          const SizedBox(width: 12),
          _MetricCard(
            label: 'Overdue',
            value: viewModel.overdueCount.toString(),
            icon: Icons.error_outline,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(TasksViewModel viewModel) {
    return Column(
      children: [
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kcBorderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            onChanged: viewModel.setSearchQuery,
            textAlignVertical: TextAlignVertical.center,
            decoration: const InputDecoration(
              hintText: 'Search tasks...',
              hintStyle: TextStyle(color: kcTextMutedColor, fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: kcTextMutedColor),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Text('Status:',
                  style: TextStyle(fontSize: 12, color: kcTextMutedColor)),
              const SizedBox(width: 8),
              ...['All', 'Pending', 'In Progress', 'Completed', 'Overdue'].map(
                (status) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: status,
                    isSelected: viewModel.filterStatus == status,
                    onTap: () => viewModel.setFilterStatus(status),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: kcTextMutedColor,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: kcTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? kcPrimaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kcPrimaryColor : kcBorderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : kcTextMutedColor,
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.onTap});

  final Task task;
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.blue;
      case 'overdue':
        return Colors.red;
      default:
        return kcTextMutedColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kcBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (task.tag.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kcPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.tag,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: kcPrimaryColor,
                      ),
                    ),
                  )
                else
                  const SizedBox(),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(task.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(task.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: kcTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              task.description,
              style: const TextStyle(
                fontSize: 13,
                color: kcTextMutedColor,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (task.status == 'In Progress' && task.progress > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Progress',
                      style: TextStyle(fontSize: 10, color: kcTextMutedColor)),
                  Text('${task.progress}%',
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: task.progress / 100,
                backgroundColor: kcBackgroundColor,
                color: kcPrimaryColor,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: kcTextMutedColor),
                const SizedBox(width: 4),
                Text(
                  task.due,
                  style: TextStyle(
                    fontSize: 12,
                    color: task.status == 'Overdue'
                        ? Colors.red
                        : kcTextMutedColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _priorityColor(task.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.priority,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _priorityColor(task.priority),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AppAvatar(
                  imageUrl: task.assigneeAvatar,
                  radius: 14,
                  fallbackInitials: 'U',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
