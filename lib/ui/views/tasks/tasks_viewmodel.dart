import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/services/cache_service.dart';
import 'package:schoolable/ui/views/tasks/task_model.dart';
import 'dart:async';

class TasksViewModel extends BaseViewModel {
  final _backendService = locator<BackendApiService>();
  final _cacheService = locator<CacheService>();

  List<Task> _allTasks = [];

  String searchQuery = '';
  String filterStatus = 'All';
  String filterPriority = 'All';

  List<Task> get tasks {
    return _allTasks.where((task) {
      final matchesSearch = searchQuery.isEmpty ||
          task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          task.tag.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesStatus =
          filterStatus == 'All' || task.status == filterStatus;

      // Note: Priority filter might need to match exact string case
      final matchesPriority =
          filterPriority == 'All' || task.priority == filterPriority;

      return matchesSearch && matchesStatus && matchesPriority;
    }).toList();
  }

  int get totalCount => _allTasks.length;
  int get inProgressCount =>
      _allTasks.where((t) => t.status == 'In Progress').length;
  int get completedCount =>
      _allTasks.where((t) => t.status == 'Completed').length;
  int get overdueCount => _allTasks.where((t) => t.status == 'Overdue').length;

  Timer? _timer;

  void initialize() async {
    // 1. Load cached tasks first for instant display
    await _loadCachedTasks();

    // 2. Fetch fresh tasks in background
    await fetchTasks();

    // 3. Polling every 30 seconds since we don't have real-time
    _timer =
        Timer.periodic(const Duration(seconds: 30), (timer) => fetchTasks());
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
      print('Error loading cached tasks: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchTasks() async {
    setBusy(true);
    try {
      final data = await _backendService.getTasks();
      _allTasks = data.map((e) => Task.fromMap(e)).toList();

      // Cache the tasks for future use
      await _cacheService.cacheTasks(data);
    } catch (e) {
      print('Error fetching tasks: $e');
    } finally {
      setBusy(false);
    }
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setFilterStatus(String status) {
    filterStatus = status;
    notifyListeners();
  }
}
