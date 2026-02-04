import 'package:stacked/stacked.dart';
import 'dart:async';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/ui/views/tasks/task_model.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:flutter/material.dart';

class TaskDetailViewModel extends BaseViewModel {
  final _backendService = locator<BackendApiService>();
  TaskDetailViewModel(this._initialTask);

  final Task _initialTask;
  late Task _task = _initialTask;
  Task get task => _task;

  late String _currentStatus;
  String get status => _currentStatus;
  String get displayStatus => _formatStatus(_currentStatus);
  bool get isCompleted {
    final normalized = _normalizeStatus(_currentStatus);
    return normalized == 'completed' || normalized == 'done';
  }

  Timer? _timer;
  DateTime? _ignoreRefreshUntil;

  String _userAvatar = '';
  String _userName = '';

  Future<void> initialize() async {
    _currentStatus = _task.status;

    // Fetch current user details for optimistic updates
    try {
      final profile = await _backendService.getUserProfile();
      if (profile != null) {
        _userName = profile['full_name'] ?? 'You';
        // Seed priority: employee_id > email > full_name > User
        final seed = profile['employee_id'] ??
            profile['email'] ??
            profile['full_name'] ??
            'User';

        final gender = profile['gender'];

        // Generate default if avatar_url is missing
        _userAvatar = _backendService.getAvatarUrl(gender, seed);

        // If custom avatar exists, use it
        if (profile['avatar_url'] != null &&
            profile['avatar_url'].toString().isNotEmpty) {
          _userAvatar = profile['avatar_url'];
        }
      }
    } catch (_) {}

    // Poll every 30 seconds since we don't have real-time
    _timer =
        Timer.periodic(const Duration(seconds: 30), (timer) => refreshTask());
  }

  Future<void> refreshTask({bool force = false}) async {
    if (!force && _isRefreshSuppressed()) {
      return;
    }
    final updatedData = await _backendService.getTask(_task.id);
    if (updatedData != null) {
      _task = Task.fromMap(updatedData);
      _currentStatus = _task.status;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color getStatusColor() {
    switch (_normalizeStatus(_currentStatus)) {
      case 'completed':
      case 'done':
        return kcTealColor;
      case 'in_progress':
      case 'review':
        return kcPrimaryColor;
      case 'overdue':
        return kcRoseColor;
      case 'pending':
      case 'todo':
        return kcAmberColor;
      default:
        return kcTextMutedColor;
    }
  }

  String _normalizeStatus(String status) {
    return status.trim().replaceAll(' ', '_').toLowerCase();
  }

  String _formatStatus(String status) {
    final normalized = status.trim().replaceAll('_', ' ').toLowerCase();
    if (normalized.isEmpty) return status;
    return normalized
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  bool _isRefreshSuppressed() {
    if (_ignoreRefreshUntil == null) return false;
    return DateTime.now().isBefore(_ignoreRefreshUntil!);
  }

  void _suppressRefresh([Duration duration = const Duration(seconds: 8)]) {
    _ignoreRefreshUntil = DateTime.now().add(duration);
  }


  Future<bool> markAsComplete() async {
    final previousTask = _task; // Snapshot for rollback
    final previousStatus = _currentStatus;

    _suppressRefresh();
    // 1. Optimistic Update
    _currentStatus = 'Completed';
    // Create new subtasks list with all completed
    final updatedSubtasks = _task.subtasks
        .map((s) => Subtask(id: s.id, title: s.title, completed: true))
        .toList();

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
      progress: 100,
      subtasks: updatedSubtasks,
      comments: _task.comments,
      attachments: _task.attachments,
    );
    notifyListeners();

    try {
      final success = await _backendService.completeTask(_task.id);
      if (!success) {
        _task = previousTask;
        _currentStatus = previousStatus;
        notifyListeners();
        return false;
      }
      await refreshTask(force: true);
      return true;
    } catch (e) {
      // Rollback
      _task = previousTask;
      _currentStatus = previousStatus;
      notifyListeners();
      return false;
    }
  }

  Future<void> addSubtask(String title) async {
    if (title.trim().isEmpty) return;

    _suppressRefresh();
    // Optimistic Update
    final newSubtask = Subtask(
      id: DateTime.now().millisecondsSinceEpoch, // Temp ID
      title: title,
      completed: false,
    );

    final updatedSubtasks = List<Subtask>.from(_task.subtasks)..add(newSubtask);

    // Recalculate progress
    final total = updatedSubtasks.length;
    final completedCount = updatedSubtasks.where((s) => s.completed).length;
    final newProgress =
        total == 0 ? 0 : ((completedCount / total) * 100).round();

    _task = Task(
      id: _task.id,
      title: _task.title,
      description: _task.description,
      due: _task.due,
      status: newProgress == 100
          ? 'Completed'
          : (newProgress > 0 ? 'In Progress' : _task.status),
      priority: _task.priority,
      tag: _task.tag,
      assignee: _task.assignee,
      assigneeAvatar: _task.assigneeAvatar,
      department: _task.department,
      progress: newProgress,
      subtasks: updatedSubtasks,
      comments: _task.comments,
      attachments: _task.attachments,
    );
    notifyListeners();

    try {
      final result = await _backendService.addSubtask(_task.id, title);
      // If successful, the refreshTask timer will eventually retrieve the real ID
      // or we could force a refresh now.
      if (result != null) {
        // Optionally update the temp ID with real ID if needed immediatley,
        // but easier to just let refresh handle it.
        await refreshTask(force: true);
      }
    } catch (e) {
      // Revert logic would go here
    }
  }

  Future<void> toggleSubtask(Subtask subtask) async {
    final originalState = subtask.completed;
    final originalStatus = _currentStatus;
    subtask.completed = !subtask.completed;

    _suppressRefresh();
    // INSTANTLY recalculate progress
    final total = _task.subtasks.length;
    final completedCount = _task.subtasks.where((s) => s.completed).length;
    final newProgress =
        total == 0 ? 0 : ((completedCount / total) * 100).round();

    // Calculate new status based on progress
    String newStatus;
    if (newProgress == 100) {
      newStatus = 'Completed';
    } else if (newProgress > 0) {
      newStatus = 'In Progress';
    } else {
      newStatus = 'Pending';
    }
    _currentStatus = newStatus;

    // Create a new task object locally to update the progress value in the UI
    _task = Task(
      id: _task.id,
      title: _task.title,
      description: _task.description,
      due: _task.due,
      status: newStatus,
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
      // Update the subtask on the backend (this also recalculates progress and status server-side)
      final success = await _backendService.updateSubtaskStatus(
          subtask.id, subtask.completed);
      if (!success) {
        // Rollback on failure
        subtask.completed = originalState;
        _currentStatus = originalStatus;
        notifyListeners();
      } else {
        await refreshTask(force: true);
      }
    } catch (e) {
      subtask.completed = originalState; // Revert
      _currentStatus = originalStatus;
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
      await _backendService.createTaskComment(task.id, text);
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
    try {
      await _backendService.updateTaskDescription(task.id, description);
    } catch (e) {
      // rollback or show error
    }
  }

  Future<void> updateStatus(String newStatus) async {
    final originalStatus = _currentStatus;
    _currentStatus = newStatus;
    notifyListeners();

    _suppressRefresh();
    try {
      int progress =
          newStatus == 'Completed' ? 100 : (newStatus == 'Pending' ? 0 : 50);
      final success = await _backendService.updateTaskStatus(
          task.id, newStatus, progress);
      if (!success) {
        _currentStatus = originalStatus;
        notifyListeners();
      } else {
        await refreshTask(force: true);
      }
    } catch (e) {
      _currentStatus = originalStatus;
      notifyListeners();
    }
  }

  Future<void> toggleStatus() async {
    await markAsComplete();
  }
}
