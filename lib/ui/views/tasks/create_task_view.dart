import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:schoolable/services/logging_service.dart';

class CreateTaskView extends StatefulWidget {
  const CreateTaskView({super.key});

  @override
  State<CreateTaskView> createState() => _CreateTaskViewState();
}

class _CreateTaskViewState extends State<CreateTaskView> {
  final _backendService = locator<BackendApiService>();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;

  String _selectedPriority = '';
  String? _selectedDepartment;
  final Set<String> _selectedAssigneeIds = {};
  DateTime? _dueDate;
  final List<String> _selectedTags = [];

  List<Map<String, String>> _priorityOptions = [];
  List<String> _departments = [];
  List<Map<String, String>> _assignees = [];
  List<String> _availableTags = [];

  @override
  void initState() {
    super.initState();
    _loadReferenceData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadReferenceData() async {
    setState(() => _isLoading = true);
    try {
      final departments = await _backendService.getDepartments();
      final profile = await _backendService.getUserProfile();
      final teamMembers = await _backendService.getTeamMembers();
      final tasks = await _backendService.getTasks();
      final referenceData = await _backendService.getReferenceData();

      final assignees = <Map<String, String>>[];
      final seen = <String>{};

      void addAssignee(Map<String, dynamic> data) {
        final id = data['id']?.toString();
        if (id == null || id.isEmpty || seen.contains(id)) return;
        seen.add(id);
        assignees.add({
          'id': id,
          'name': data['full_name']?.toString() ??
              data['name']?.toString() ??
              'User',
          'department': data['department']?.toString() ?? '',
        });
      }

      if (profile != null) {
        addAssignee(profile);
      }
      for (final member in teamMembers) {
        addAssignee(member);
      }

      final tagSet = <String>{};
      for (final task in tasks) {
        final tag = task['tag']?.toString();
        if (tag != null && tag.trim().isNotEmpty) {
          tagSet.add(tag.trim());
        }
        final tags = task['tags'];
        if (tags is List) {
          for (final item in tags) {
            final tagValue = item?.toString();
            if (tagValue != null && tagValue.trim().isNotEmpty) {
              tagSet.add(tagValue.trim());
            }
          }
        }
      }

      String? initialDepartment;
      final profileDept = profile?['department']?.toString();
      if (profileDept != null &&
          profileDept.isNotEmpty &&
          departments.contains(profileDept)) {
        initialDepartment = profileDept;
      } else if (departments.isNotEmpty) {
        initialDepartment = departments.first;
      }

      final initialAssigneeIds = <String>{};
      if (profile?['id'] != null) {
        initialAssigneeIds.add(profile?['id']?.toString() ?? '');
      }
      if (initialAssigneeIds.isEmpty && assignees.isNotEmpty) {
        final firstId = assignees.first['id'];
        if (firstId != null && firstId.isNotEmpty) {
          initialAssigneeIds.add(firstId);
        }
      }

      final priorityOptions = <Map<String, String>>[];
      final priorityData = referenceData['taskPriorities'];
      if (priorityData is List) {
        for (final entry in priorityData) {
          if (entry is Map) {
            final value = entry['value']?.toString();
            if (value == null || value.isEmpty) continue;
            final label = entry['label']?.toString();
            priorityOptions.add({
              'value': value,
              'label': label != null && label.isNotEmpty ? label : value,
            });
          }
        }
      }

      String selectedPriority = _selectedPriority;
      if (priorityOptions.isNotEmpty &&
          !priorityOptions.any((option) => option['value'] == selectedPriority)) {
        final mediumOption = priorityOptions.firstWhere(
          (option) => option['value'] == 'Medium',
          orElse: () => priorityOptions.first,
        );
        selectedPriority = mediumOption['value'] ?? '';
      }

      if (mounted) {
        setState(() {
          _departments = departments;
          _assignees = assignees;
          _availableTags = tagSet.toList()..sort();
          _selectedDepartment = initialDepartment;
          _selectedAssigneeIds
            ..clear()
            ..addAll(initialAssigneeIds.where((id) => id.isNotEmpty));
          _priorityOptions = priorityOptions;
          _selectedPriority = selectedPriority;
        });
      }
    } catch (e) {
      AppLogger.log('Error loading task references: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartment == null || _selectedAssigneeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a department and at least one assignee')),
      );
      return;
    }
    if (_selectedPriority.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a priority')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _backendService.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assigneeIds: _selectedAssigneeIds.toList(),
        organization: _selectedDepartment!,
        priority: _selectedPriority,
        dueDate: _dueDate?.toIso8601String(),
        tags: _selectedTags,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create task: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: kcTextColor),
        title: const Text(
          'Create New Task',
          style: TextStyle(
              color: kcTextColor, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: kcBorderColor),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              _buildLabel('Task Title *'),
              TextFormField(
                controller: _titleController,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a title'
                    : null,
                decoration: _inputDecoration('Enter task title'),
              ),
              const SizedBox(height: 20),
              _buildLabel('Description *'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a description'
                    : null,
                decoration: _inputDecoration('Enter task description'),
              ),
              const SizedBox(height: 20),
              _buildLabel('Organization *'),
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                items: _departments
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: _departments.isEmpty
                    ? null
                    : (v) => setState(() => _selectedDepartment = v),
                decoration: _inputDecoration(''),
              ),
              const SizedBox(height: 20),
              _buildLabel('Assignees *'),
              _assignees.isEmpty
                  ? const Text(
                      'No team members available',
                      style: TextStyle(
                        fontSize: 12,
                        color: kcTextMutedColor,
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _assignees.map((assignee) {
                        final id = assignee['id'];
                        if (id == null) return const SizedBox.shrink();
                        final isSelected = _selectedAssigneeIds.contains(id);
                        return FilterChip(
                          label: Text(assignee['name'] ?? 'User'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAssigneeIds.add(id);
                              } else {
                                _selectedAssigneeIds.remove(id);
                              }
                            });
                          },
                          selectedColor: kcPrimaryColor.withOpacity(0.2),
                          checkmarkColor: kcPrimaryColor,
                          labelStyle: TextStyle(
                            color:
                                isSelected ? kcPrimaryColor : kcTextMutedColor,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Priority *'),
                        DropdownButtonFormField<String>(
                          value: _selectedPriority.isNotEmpty
                              ? _selectedPriority
                              : null,
                          items: _priorityOptions
                              .map((option) => DropdownMenuItem(
                                    value: option['value'],
                                    child: Text(
                                      option['label'] ?? option['value'] ?? '',
                                    ),
                                  ))
                              .toList(),
                          onChanged: _priorityOptions.isEmpty
                              ? null
                              : (v) =>
                                  setState(() => _selectedPriority = v ?? ''),
                          decoration: _inputDecoration(''),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Due Date'),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dueDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setState(() => _dueDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: kcBorderColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _dueDate == null
                                      ? 'Select date'
                                      : _formatDate(_dueDate!),
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const Icon(Icons.calendar_today,
                                    size: 16, color: kcTextMutedColor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildLabel('Tags'),
              _availableTags.isEmpty
                  ? const Text(
                      'No tags available yet',
                      style: TextStyle(
                        fontSize: 12,
                        color: kcTextMutedColor,
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.remove(tag);
                              }
                            });
                          },
                          selectedColor: kcPrimaryColor.withOpacity(0.2),
                          checkmarkColor: kcPrimaryColor,
                          labelStyle: TextStyle(
                            color:
                                isSelected ? kcPrimaryColor : kcTextMutedColor,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kcPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Task',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kcTextMutedColor, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kcBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kcBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kcPrimaryColor),
      ),
    );
  }
}