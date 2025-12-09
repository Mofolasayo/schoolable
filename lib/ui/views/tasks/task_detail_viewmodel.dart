import 'package:stacked/stacked.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/supabase_service.dart';
import 'package:schoolable/ui/views/tasks/task_model.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:flutter/material.dart';

class TaskDetailViewModel extends BaseViewModel {
  final _supabaseService = locator<SupabaseService>();
  TaskDetailViewModel(this._initialTask);

  final Task _initialTask;
  late Task _task = _initialTask;
  Task get task => _task;

  late String _currentStatus;
  String get status => _currentStatus;
  bool get isCompleted => _currentStatus == 'Completed';

  RealtimeChannel? _subscription;
  Timer? _timer;

  String _userAvatar = '';
  String _userName = '';

  Future<void> initialize() async {
    _currentStatus = _task.status;
    _setupRealtimeSubscription();

    // Fetch current user details for optimistic updates
    try {
      final user = _supabaseService.currentUser;
      if (user != null) {
        final profile = await _supabaseService.getUserProfile();
        if (profile != null) {
          _userName = profile['full_name'] ?? 'You';
          // Seed priority: employee_id > email > full_name > User
          // Note: profile usually has these fields if they were saved, or from auth metadata.
          // SupabaseService.getUserProfile returns fields from 'profiles' table.
          // Ensure we have them.
          final seed = profile['employee_id'] ??
              profile['email'] ??
              profile['full_name'] ??
              'User';

          final gender = profile['gender'];

          // Generate default if avatar_url is missing
          _userAvatar = _supabaseService.getAvatarUrl(gender, seed);

          // If custom avatar exists, use it
          if (profile['avatar_url'] != null &&
              profile['avatar_url'].toString().isNotEmpty) {
            _userAvatar = profile['avatar_url'];
          }
        }
      }
    } catch (_) {}

    // Poll every 1 minute
    _timer =
        Timer.periodic(const Duration(minutes: 1), (timer) => refreshTask());
  }

  void _setupRealtimeSubscription() {
    final channel = _supabaseService.client.channel('public:tasks:${_task.id}');
    channel
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tasks',
            filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
                value: _task.id),
            callback: (payload) => refreshTask())
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'task_comments',
            filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'task_id',
                value: _task.id),
            callback: (payload) => refreshTask())
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'task_subtasks',
            filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'task_id',
                value: _task.id),
            callback: (payload) => refreshTask())
        .subscribe();
    _subscription = channel;
  }

  Future<void> refreshTask() async {
    final updatedData = await _supabaseService.getTask(_task.id);
    if (updatedData != null) {
      _task = Task.fromMap(updatedData);
      _currentStatus = _task.status;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    _timer?.cancel();
    super.dispose();
  }

  Color getStatusColor() {
    switch (_currentStatus.toLowerCase()) {
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

  Future<void> markAsComplete() async {
    final previousTask = _task; // Snapshot for rollback
    final previousStatus = _currentStatus;

    // 1. Optimistic Update
    _currentStatus = 'Completed';
    // Create new subtasks list with all completed
    final updatedSubtasks = _task.subtasks
        .map((s) => Subtask(id: s.id, title: s.title, completed: true))
        .toList();

    // We need to implement 'copyWith' on Task ideally, but for now hack it or re-instantiate
    // Since Task fields are final, we can't just set them.
    // Wait, Task subtasks is final.
    // I will recreate the Task object.
    _task = Task(
      id: _task.id,
      title: _task.title,
      description: _task.description,
      due: _task.due,
      status: 'Completed',
      priority: _task.priority,
      tag: _task.tag,
      assignee: _task.assignee,
      assigneeAvatar: _task.assigneeAvatar,
      department: _task.department,
      progress: 100, // Explicitly set to 100
      subtasks: updatedSubtasks,
      comments: _task.comments,
      attachments: _task.attachments,
    );
    notifyListeners();

    try {
      await _supabaseService.completeTask(_task.id);
    } catch (e) {
      // Rollback
      _task = previousTask;
      _currentStatus = previousStatus;
      notifyListeners();
      // Show error
    }
  }

  Future<void> toggleSubtask(Subtask subtask) async {
    final originalState = subtask.completed;
    subtask.completed = !subtask.completed;

    // INSTANTLY recalculate progress
    // Note: _task.subtasks holds reference to 'subtask' which we just mutated.
    // So counting them now will give new count.
    final total = _task.subtasks.length;
    final completedCount = _task.subtasks.where((s) => s.completed).length;
    final newProgress =
        total == 0 ? 0 : ((completedCount / total) * 100).round();

    // Create a new task object locally to update the progress value in the UI
    // (Since 'progress' field is final)
    _task = Task(
      id: _task.id,
      title: _task.title,
      description: _task.description,
      due: _task.due,
      status: _task.status,
      priority: _task.priority,
      tag: _task.tag,
      assignee: _task.assignee,
      assigneeAvatar: _task.assigneeAvatar,
      department: _task.department,
      progress: newProgress,
      subtasks: _task.subtasks,
      comments: _task.comments,
      attachments: _task.attachments,
    );

    notifyListeners();

    try {
      await _supabaseService.updateSubtaskStatus(subtask.id, subtask.completed);
    } catch (e) {
      subtask.completed = originalState; // Revert
      // Revert progress?
      // The Realtime subscription or refresh will fix it,
      // or we could force a refresh here on error.
      notifyListeners();
    }
  }

  Future<void> addComment(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Optimistic Update
    final newComment = Comment(
      author: _userName.isNotEmpty ? _userName : 'You',
      avatar: _userAvatar.isNotEmpty
          ? _userAvatar
          : 'https://api.dicebear.com/7.x/bottts/svg?seed=You',
      text: text,
      timestamp: DateTime.now().toIso8601String(),
    );

    // We need to add to the list. accessing .comments which is final List
    // We can't modify the const/final list if it was created that way.
    // Task.comments is List<Comment>.
    // Let's hope it's a growable list from Task.fromMap (it is).
    // But wait, Task.fromMap uses .toList() which creates a growable list by default.

    // However, recommedation: Recreate the task object to trigger updates properly if needed,
    // but just modifying the list and calling notifyListeners() works for Stacked.

    // IMPORTANT: 'comments' in Task is final. We can operate on the list instance.
    // But if Task was created with const [], we might crash.
    // Task.fromMap uses .toList() so it should be fine.

    // We want the comment at the END (or beginning depending on UI).
    // UI maps them in order. Usually newest at bottom?
    // In UI: ...currentTask.comments.map
    // It seems to render in order.

    // Existing comments are usually fetched ordered by created_at.
    // If we append, it shows at bottom.

    // Let's create a NEW list to be safe and update _task.
    final updatedComments = List<Comment>.from(_task.comments)..add(newComment);

    final oldTask = _task;
    _task = Task(
      id: _task.id,
      title: _task.title,
      description: _task.description,
      due: _task.due,
      status: _task.status,
      priority: _task.priority,
      tag: _task.tag,
      assignee: _task.assignee,
      assigneeAvatar: _task.assigneeAvatar,
      department: _task.department,
      progress: _task.progress,
      subtasks: _task.subtasks,
      comments: updatedComments,
      attachments: _task.attachments,
    );
    notifyListeners();

    try {
      await _supabaseService.createTaskComment(task.id, text);
      // We don't need to do anything on success, eventually the real-time sub will fire
      // and replace our optimistic list with the real one (which might cause a slight jump if timestamps differ slightly but acceptable).
    } catch (e) {
      // Revert
      _task = oldTask;
      notifyListeners();
    }
  }

  Future<void> addAttachment() async {
    // Placeholder
  }

  Future<void> updateDescription(String description) async {
    // Optimistic update
    // We could clone the task with new description but since we refresh on change, just wait or notify.
    // For now, let's just call service.

    try {
      await _supabaseService.updateTaskDescription(task.id, description);
    } catch (e) {
      // rollback or show error
    }
  }

  Future<void> updateStatus(String newStatus) async {
    final originalStatus = _currentStatus;
    _currentStatus = newStatus;
    notifyListeners();

    try {
      int progress =
          newStatus == 'Completed' ? 100 : (newStatus == 'Pending' ? 0 : 50);
      await _supabaseService.updateTaskStatus(task.id, newStatus, progress);
    } catch (e) {
      _currentStatus = originalStatus;
      notifyListeners();
    }
  }

  // Method to just toggle for the simple button if we still had it,
  // but we are replacing with markAsComplete.
  Future<void> toggleStatus() async {
    await markAsComplete();
  }
}
