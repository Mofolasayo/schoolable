import 'package:flutter/material.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:schoolable/ui/views/tasks/task_detail_view.dart';

class Task {
  Task({
    required this.title,
    required this.description,
    required this.due,
    required this.status,
    required this.priority,
    required this.tag,
    required this.assignee,
  });

  final String title;
  final String description;
  final String due;
  final String status;
  final String priority;
  final String tag;
  final String assignee;
}

class TasksView extends StatefulWidget {
  const TasksView({Key? key}) : super(key: key);

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  final TextEditingController _searchController = TextEditingController();

  final List<Task> _tasks = [
    Task(
      title: 'Design onboarding flow',
      description: 'Refresh the screens and illustrations to match mobile ARP.',
      due: 'Today · 4:00 PM',
      status: 'In Progress',
      priority: 'High',
      tag: 'Design',
      assignee: 'Olivia',
    ),
    Task(
      title: 'QA attendance flow',
      description: 'Test camera + location capture on iOS and Android.',
      due: 'Today · 6:00 PM',
      status: 'Pending',
      priority: 'Medium',
      tag: 'QA',
      assignee: 'Alex',
    ),
    Task(
      title: 'Draft announcements copy',
      description: 'Prepare October release note for mobile staff.',
      due: 'Tomorrow',
      status: 'Pending',
      priority: 'Low',
      tag: 'Content',
      assignee: 'Sarah',
    ),
    Task(
      title: 'Implement task detail view',
      description: 'Add detail screen with attachments and comments scaffold.',
      due: 'Fri · 11:00 AM',
      status: 'In Progress',
      priority: 'High',
      tag: 'Frontend',
      assignee: 'Michael',
    ),
    Task(
      title: 'Fix chat unread badge',
      description: 'Unread counter mismatch on DM list when messages sync.',
      due: 'Mon',
      status: 'Blocked',
      priority: 'Medium',
      tag: 'Backend',
      assignee: 'Rita',
    ),
  ];

  String _query = '';

  List<Task> get _filteredTasks {
    if (_query.isEmpty) return _tasks;
    return _tasks
        .where((task) =>
            task.title.toLowerCase().contains(_query) ||
            task.description.toLowerCase().contains(_query) ||
            task.tag.toLowerCase().contains(_query))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Tasks',
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child:
                      const Icon(Icons.more_horiz, color: kcTextMutedColor, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
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
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _query = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search tasks by title or tag',
                  hintStyle:
                      const TextStyle(color: kcTextMutedColor, fontSize: 14),
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: kcTextMutedColor),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: kcTextMutedColor),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: _filteredTasks.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final task = _filteredTasks[index];
                  return _TaskCard(
                    task: task,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TaskDetailView(task: task),
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
        return kcTealColor;
      case 'in progress':
        return kcPrimaryColor;
      case 'blocked':
        return kcRoseColor;
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
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(task.status).withOpacity(0.08),
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
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded,
                        color: kcTextMutedColor, size: 18),
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
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: kcTextMutedColor),
                const SizedBox(width: 4),
                Text(
                  task.due,
                  style: const TextStyle(fontSize: 12, color: kcTextMutedColor),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _priorityColor(task.priority).withOpacity(0.08),
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
                CircleAvatar(
                  radius: 14,
                  backgroundColor: kcPrimaryColor.withOpacity(0.1),
                  child: Text(
                    task.assignee.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: kcPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
