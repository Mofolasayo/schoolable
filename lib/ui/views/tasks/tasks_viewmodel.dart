import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/services/cache_service.dart';
import 'package:schoolable/services/websocket_service.dart';
import 'package:schoolable/ui/views/tasks/task_model.dart';
import 'dart:async';
import 'package:schoolable/services/logging_service.dart';

class TasksViewModel extends BaseViewModel {
  final _backendService = locator<BackendApiService>();
  final _cacheService = locator<CacheService>();
  final _wsService = locator<WebSocketService>();

  List<Task> _allTasks = [];
  List<Map<String, String>> _statusFilters = [];
  List<Map<String, String>> _priorityFilters = [];
  final Map<String, String> _statusLabelsByValue = {};

  String searchQuery = '';
  String filterStatus = 'All';
  String filterPriority = 'All';
  String sortOption = 'Due soon';

  final List<String> sortOptions = [
    'Due soon',
    'Priority',
    'Progress',
    'Newest',
  ];

  List<Map<String, String>> get statusFilters => _statusFilters;
  List<Map<String, String>> get priorityFilters => _priorityFilters;
  List<Map<String, String>> get primaryStatusSegments =>
      _buildPrimarySegments();

  List<Task> get tasks {
    final filtered = _allTasks.where((task) {
      final matchesSearch = searchQuery.isEmpty ||
          task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          task.tag.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesStatus = filterStatus == 'All'
          ? true
          : filterStatus == 'Overdue'
              ? isTaskOverdue(task)
              : _normalizeStatus(task.status) == _normalizeStatus(filterStatus);

      // Note: Priority filter might need to match exact string case
      final matchesPriority = filterPriority == 'All' ||
          task.priority.toLowerCase() == filterPriority.toLowerCase();

      return matchesSearch && matchesStatus && matchesPriority;
    }).toList();

    _sortTasks(filtered);
    final active = <Task>[];
    final completed = <Task>[];
    for (final task in filtered) {
      if (isTaskCompleted(task)) {
        completed.add(task);
      } else {
        active.add(task);
      }
    }
    return [...active, ...completed];
  }

  int get totalCount => _allTasks.length;
  int get inProgressCount => _allTasks
      .where((t) => _normalizeStatus(t.status) == 'IN_PROGRESS')
      .length;
  int get completedCount => _allTasks.where((t) {
        final normalized = _normalizeStatus(t.status);
        return normalized == 'DONE' || normalized == 'COMPLETED';
      }).length;
  int get overdueCount => _allTasks.where(isTaskOverdue).length;

  Timer? _timer;
  final Set<int> _completingTaskIds = {};
  MessageCallback? _notificationHandler;

  void initialize() async {
    await _loadReferenceData();

    // 1. Load cached tasks first for instant display
    await _loadCachedTasks();

    // 2. Fetch fresh tasks in background
    await fetchTasks(showLoader: _allTasks.isEmpty);

    // 3. Polling every 30 seconds since we don't have real-time
    _timer = Timer.periodic(
        const Duration(seconds: 30), (timer) => fetchTasks(showLoader: false));

    await _subscribeToTaskUpdates();
  }

  /// Load cached tasks for instant display
  Future<void> _loadCachedTasks() async {
    try {
      final cached = await _cacheService.getCachedTasks();
      if (cached != null && cached.isNotEmpty) {
        _allTasks = cached
            .cast<Map<String, dynamic>>()
            .map((e) => Task.fromMap(e))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      AppLogger.log('Error loading cached tasks: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_notificationHandler != null) {
      _wsService.unsubscribeFromNotifications(_notificationHandler!);
      _notificationHandler = null;
    }
    super.dispose();
  }

  Future<void> fetchTasks({bool showLoader = true}) async {
    if (showLoader) {
      setBusy(true);
    }
    try {
      final data = await _backendService.getTasks();
      _allTasks = data.map((e) => Task.fromMap(e)).toList();

      // Cache the tasks for future use
      await _cacheService.cacheTasks(data);
    } catch (e) {
      AppLogger.log('Error fetching tasks: $e');
    } finally {
      if (showLoader) {
        setBusy(false);
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> _subscribeToTaskUpdates() async {
    if (_notificationHandler != null) {
      return;
    }

    if (!_wsService.isConnected) {
      final token = await _backendService.getCurrentToken();
      if (token != null) {
        await _wsService.connect(token);
      }
    }

    _notificationHandler = (message) {
      final notificationType =
          message.data['notificationType']?.toString() ?? '';
      if (notificationType.contains('task')) {
        fetchTasks(showLoader: false);
      }
    };

    _wsService.subscribeToNotifications(onNotification: _notificationHandler!);
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setFilterStatus(String status) {
    filterStatus = status;
    notifyListeners();
  }

  void setFilterPriority(String priority) {
    filterPriority = priority;
    notifyListeners();
  }

  void setSortOption(String option) {
    sortOption = option;
    notifyListeners();
  }

  bool isCompleting(int taskId) => _completingTaskIds.contains(taskId);

  void updateTask(Task updatedTask) {
    final index = _allTasks.indexWhere((task) => task.id == updatedTask.id);
    if (index == -1) {
      return;
    }
    final updated = List<Task>.from(_allTasks);
    updated[index] = updatedTask;
    _allTasks = updated;
    notifyListeners();
  }

  Future<void> quickCompleteTask(Task task) async {
    final normalized = _normalizeStatus(task.status);
    if (normalized == 'COMPLETED' || normalized == 'DONE') return;
    if (_completingTaskIds.contains(task.id)) return;

    _completingTaskIds.add(task.id);
    notifyListeners();

    try {
      final success = await _backendService.completeTask(task.id);
      if (success) {
        _allTasks = _allTasks
            .map((t) => t.id == task.id
                ? t.copyWith(status: 'Completed', progress: 100)
                : t)
            .toList();
      }
    } catch (e) {
      AppLogger.log('Error completing task: $e');
    } finally {
      _completingTaskIds.remove(task.id);
      notifyListeners();
    }
  }

  String getStatusLabel(Task task) {
    if (isTaskCompleted(task)) {
      return 'Done';
    }
    if (isTaskOverdue(task)) {
      return _statusLabelsByValue[_normalizeStatus('Overdue')] ?? 'Overdue';
    }
    return _statusLabelsByValue[_normalizeStatus(task.status)] ?? task.status;
  }

  bool isTaskOverdue(Task task) {
    if (isTaskCompleted(task)) {
      return false;
    }
    return task.due.toLowerCase() == 'overdue';
  }

  bool isTaskCompleted(Task task) {
    final normalized = _normalizeStatus(task.status);
    return normalized == 'DONE' || normalized == 'COMPLETED';
  }

  bool isTaskInProgress(Task task) {
    final normalized = _normalizeStatus(task.status);
    return normalized == 'IN_PROGRESS' || normalized == 'REVIEW';
  }

  String _normalizeStatus(String status) {
    return status.trim().replaceAll(' ', '_').toUpperCase();
  }

  void _sortTasks(List<Task> tasks) {
    switch (sortOption) {
      case 'Priority':
        tasks.sort((a, b) => _priorityRank(a).compareTo(_priorityRank(b)));
        break;
      case 'Progress':
        tasks.sort((a, b) => b.progress.compareTo(a.progress));
        break;
      case 'Newest':
        tasks.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'Due soon':
      default:
        tasks.sort((a, b) => _dueRank(a).compareTo(_dueRank(b)));
        break;
    }
  }

  int _priorityRank(Task task) {
    switch (task.priority.toLowerCase()) {
      case 'high':
        return 0;
      case 'medium':
        return 1;
      case 'low':
        return 2;
      default:
        return 3;
    }
  }

  int _dueRank(Task task) {
    final due = task.due.toLowerCase();
    if (due.contains('overdue')) return 0;
    if (due.contains('today')) return 1;
    if (due.contains('tomorrow')) return 2;
    if (due.contains('no due')) return 9;
    return 5;
  }

  List<Map<String, String>> _buildPrimarySegments() {
    return [
      {'label': 'All', 'value': 'All'},
      {
        'label': 'Todo',
        'value': _resolveStatusValue(
          ['TODO', 'TO_DO', 'PENDING'],
          'TODO',
        )
      },
      {
        'label': 'In Progress',
        'value': _resolveStatusValue(
          ['IN_PROGRESS', 'REVIEW'],
          'IN_PROGRESS',
        )
      },
      {
        'label': 'Done',
        'value': _resolveStatusValue(
          ['COMPLETED', 'DONE'],
          'COMPLETED',
        )
      },
      {'label': 'Overdue', 'value': 'Overdue'},
    ];
  }

  String _resolveStatusValue(List<String> normalizedOptions, String fallback) {
    for (final option in normalizedOptions) {
      final match = _statusFilters.firstWhere(
        (item) =>
            _normalizeStatus(item['value'] ?? '') ==
            _normalizeStatus(option),
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        return match['value'] ?? fallback;
      }
    }
    return fallback;
  }

  Future<void> _loadReferenceData() async {
    try {
      final refData = await _backendService.getReferenceData();
      final filters = refData['taskStatusFilters'];
      if (filters is List) {
        final parsed = <Map<String, String>>[];
        for (final entry in filters) {
          if (entry is Map) {
            final value = entry['value']?.toString();
            if (value == null || value.isEmpty) continue;
            final label = entry['label']?.toString() ?? value;
            parsed.add({'value': value, 'label': label});
            _statusLabelsByValue[_normalizeStatus(value)] = label;
          }
        }
        _statusFilters = parsed;
        if (_statusFilters.isNotEmpty &&
            filterStatus != 'All' &&
            !_statusFilters.any((item) => item['value'] == filterStatus)) {
          filterStatus = _statusFilters.first['value'] ?? 'All';
        }
        notifyListeners();
      }

      final priorities = refData['taskPriorities'];
      if (priorities is List) {
        final parsed = <Map<String, String>>[];
        for (final entry in priorities) {
          if (entry is Map) {
            final value = entry['value']?.toString();
            if (value == null || value.isEmpty) continue;
            final label = entry['label']?.toString() ?? value;
            parsed.add({'value': value, 'label': label});
          }
        }
        _priorityFilters = [
          {'value': 'All', 'label': 'All'},
          ...parsed,
        ];
      } else {
        _priorityFilters = const [
          {'value': 'All', 'label': 'All'},
          {'value': 'High', 'label': 'High'},
          {'value': 'Medium', 'label': 'Medium'},
          {'value': 'Low', 'label': 'Low'},
        ];
      }

      if (!_priorityFilters
          .any((item) => item['value'] == filterPriority)) {
        filterPriority = _priorityFilters.first['value'] ?? 'All';
      }

      if (filterStatus.isEmpty) {
        filterStatus = 'All';
      }
    } catch (e) {
      AppLogger.log('Error loading task status reference data: $e');
    }
  }
}
