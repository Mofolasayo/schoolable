import 'package:stacked/stacked.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/supabase_service.dart';
import 'package:schoolable/ui/views/tasks/task_model.dart';
import 'dart:async';

class TasksViewModel extends BaseViewModel {
  final _supabaseService = locator<SupabaseService>();

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

  RealtimeChannel? _subscription;
  Timer? _timer;

  void initialize() {
    fetchTasks();
    _setupRealtimeSubscription();
    // Safety polling every 2 minutes
    _timer =
        Timer.periodic(const Duration(minutes: 2), (timer) => fetchTasks());
  }

  void _setupRealtimeSubscription() {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    final channel = _supabaseService.client.channel('public:tasks:list');
    channel
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tasks',
            filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'assignee_id',
                value: user.id),
            callback: (payload) => fetchTasks())
        .subscribe();
    _subscription = channel;
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchTasks() async {
    setBusy(true);
    try {
      final data = await _supabaseService.getTasks();
      _allTasks = data.map((e) => Task.fromMap(e)).toList();
    } catch (e) {
      // Handle error
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
