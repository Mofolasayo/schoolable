import 'package:flutter/material.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:schoolable/ui/views/tasks/task_model.dart';

class CreateTaskView extends StatefulWidget {
  const CreateTaskView({super.key});

  @override
  State<CreateTaskView> createState() => _CreateTaskViewState();
}

class _CreateTaskViewState extends State<CreateTaskView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedPriority = 'Medium';
  String _selectedDepartment = 'Sales';
  String _selectedAssignee = 'Zainab Olagboye';
  final String _dueDate = '2024-01-20';
  final List<String> _selectedTags = [];

  final List<String> _priorities = ['Low', 'Medium', 'High'];
  final List<String> _departments = [
    'Sales',
    'Support',
    'Operations',
    'Engineering',
    'Marketing',
    'HR'
  ];
  final List<String> _assignees = [
    'Zainab Olagboye',
    'Deborah Olabode',
    'Captain Shaddai',
    'Ruth Ihechi',
    'Darlington Obiakonwa'
  ];
  final List<String> _availableTags = [
    'Documentation',
    'Onboarding',
    'HR',
    'Reviews',
    'Engineering',
    'Integration',
    'Reports',
    'Sales',
    'Marketing',
    'Website'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newTask = Task(
        id: DateTime.now().millisecondsSinceEpoch,
        title: _titleController.text,
        description: _descriptionController.text,
        due: 'Just now',
        status: 'Pending',
        priority: _selectedPriority,
        tag: _selectedTags.isNotEmpty ? _selectedTags.first : 'General',
        assignee: _selectedAssignee,
        assigneeAvatar: _selectedAssignee[0],
        department: _selectedDepartment,
      );
      Navigator.of(context).pop(newTask);
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
      body: SingleChildScrollView(
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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Organization *'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedDepartment,
                          items: _departments
                              .map((d) =>
                                  DropdownMenuItem(value: d, child: Text(d)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedDepartment = v!),
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
                        _buildLabel('Assignee *'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedAssignee,
                          items: _assignees
                              .map((a) =>
                                  DropdownMenuItem(value: a, child: Text(a)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedAssignee = v!),
                          decoration: _inputDecoration(''),
                        ),
                      ],
                    ),
                  ),
                ],
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
                          initialValue: _selectedPriority,
                          items: _priorities
                              .map((p) =>
                                  DropdownMenuItem(value: p, child: Text(p)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedPriority = v!),
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
                          onTap: () {}, // Date picker logic would go here
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
                                Text(_dueDate,
                                    style: const TextStyle(fontSize: 14)),
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
              Wrap(
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
                      color: isSelected ? kcPrimaryColor : kcTextMutedColor,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kcPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
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
