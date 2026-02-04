class Task {
  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.due,
    required this.status,
    required this.priority,
    required this.tag,
    required this.assignee,
    required this.assigneeAvatar,
    required this.department,
    this.progress = 0,
    this.subtasks = const [],
    this.comments = const [],
    this.attachments = const [],
  });

  final int id;
  final String title;
  final String description;
  final String due;
  final String status;
  final String priority;
  final String tag;
  final String assignee;
  final String assigneeAvatar;
  final String department;
  final int progress;
  final List<Subtask> subtasks;
  final List<Comment> comments;
  final List<Attachment> attachments;

  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? due,
    String? status,
    String? priority,
    String? tag,
    String? assignee,
    String? assigneeAvatar,
    String? department,
    int? progress,
    List<Subtask>? subtasks,
    List<Comment>? comments,
    List<Attachment>? attachments,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      due: due ?? this.due,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      tag: tag ?? this.tag,
      assignee: assignee ?? this.assignee,
      assigneeAvatar: assigneeAvatar ?? this.assigneeAvatar,
      department: department ?? this.department,
      progress: progress ?? this.progress,
      subtasks: subtasks ?? this.subtasks,
      comments: comments ?? this.comments,
      attachments: attachments ?? this.attachments,
    );
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    // Helper to format due date
    String formatDue(String? dateStr) {
      if (dateStr == null) return 'No due date';
      try {
        final date = DateTime.parse(dateStr);
        final now = DateTime.now();
        final diff = date.difference(now);

        if (date.day == now.day &&
            date.month == now.month &&
            date.year == now.year) {
          return 'Today';
        } else if (diff.inDays == 0 || diff.inDays == 1) {
          return 'Tomorrow';
        } else if (diff.inDays < 7 && diff.inDays > 0) {
          return '${date.day}/${date.month}';
        } else if (diff.inDays < 0) {
          return 'Overdue';
        }
        return '${date.day}/${date.month}';
      } catch (_) {
        return dateStr;
      }
    }

    // Avatar generation helper
    String getAvatar(Map<String, dynamic>? userObj) {
      if (userObj == null) {
        return 'https://api.dicebear.com/7.x/bottts/svg?seed=Unassigned';
      }
      final url = userObj['avatar_url'];
      if (url != null && url.toString().isNotEmpty) return url;

      final gender = userObj['gender'] as String?;
      // Seed priority: employee_id > email > full_name > User
      final seed = userObj['employee_id'] ??
          userObj['email'] ??
          userObj['full_name'] ??
          'User';

      String style;
      if (gender?.toLowerCase() == 'male') {
        style = 'adventurer';
      } else if (gender?.toLowerCase() == 'female') {
        style = 'adventurer-neutral';
      } else {
        style = 'bottts';
      }
      return 'https://api.dicebear.com/7.x/$style/svg?seed=$seed';
    }

    final assigneeObj = map['assignee']; // Object or null
    final assigneeName =
        assigneeObj != null ? assigneeObj['full_name'] : 'Unassigned';
    final dept = assigneeObj != null
        ? assigneeObj['department']
        : (map['organization'] ?? '');

    // Parse subtasks
    final subList =
        (map['subtasks'] as List?)?.map((s) => Subtask.fromMap(s)).toList() ??
            [];

    // Parse attachments
    final attList = (map['attachments'] as List?)
            ?.map((a) => Attachment.fromMap(a))
            .toList() ??
        [];

    // Parse comments
    final comList =
        (map['comments'] as List?)?.map((c) => Comment.fromMap(c)).toList() ??
            [];

    // Tags is array in DB but String in model?
    // Model has `tag` (singular). DB has `tags` TEXT[].
    // We'll take the first tag or join them.
    final tags = map['tags'] as List?;
    final tagStr = tags != null && tags.isNotEmpty ? tags.first.toString() : '';

    return Task(
      id: map['id'],
      title: map['title'] ?? 'Untitled',
      description: map['description'] ?? '',
      due: formatDue(map['due_date']),
      status: map['status'] ?? 'TODO',
      priority: map['priority'] ?? 'Medium',
      tag: tagStr,
      assignee: assigneeName ?? 'Unassigned',
      assigneeAvatar: getAvatar(assigneeObj),
      department: dept ?? '',
      progress: (map['progress'] as num?)?.toInt() ?? 0,
      subtasks: subList,
      attachments: attList,
      comments: comList,
    );
  }
}

class Subtask {
  Subtask({required this.id, required this.title, this.completed = false});
  final int id;
  final String title;
  bool completed;

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'],
      title: map['title'] ?? '',
      completed: map['completed'] ?? false,
    );
  }
}

class Comment {
  Comment({
    required this.author,
    required this.avatar,
    required this.text,
    required this.timestamp,
  });
  final String author;
  final String avatar;
  final String text;
  final String timestamp;

  factory Comment.fromMap(Map<String, dynamic> map) {
    final authorObj = map['author'];
    final authorName = authorObj != null ? authorObj['full_name'] : 'User';

    // Avatar generation helper (duplicated for static context)
    String getAvatar(Map<String, dynamic>? userObj) {
      if (userObj == null) {
        return 'https://api.dicebear.com/7.x/bottts/svg?seed=User';
      }
      final url = userObj['avatar_url'];
      if (url != null && url.toString().isNotEmpty) return url;

      final gender = userObj['gender'] as String?;
      // Seed priority: employee_id > email > full_name > User
      final seed = userObj['employee_id'] ??
          userObj['email'] ??
          userObj['full_name'] ??
          'User';

      String style;
      if (gender?.toLowerCase() == 'male') {
        style = 'adventurer';
      } else if (gender?.toLowerCase() == 'female') {
        style = 'adventurer-neutral';
      } else {
        style = 'bottts';
      }
      return 'https://api.dicebear.com/7.x/$style/svg?seed=$seed';
    }

    return Comment(
      author: authorName ?? 'User',
      avatar: getAvatar(authorObj),
      text: map['content'] ?? '',
      timestamp: map['created_at'] ?? '',
    );
  }
}

class Attachment {
  Attachment(
      {required this.name,
      required this.size,
      required this.type,
      required this.url});
  final String name;
  final String size;
  final String type;
  final String url;

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      name: map['file_name'] ?? 'File',
      size: map['file_size'] ?? '',
      type: map['file_type'] ?? 'file',
      url: map['file_url'] ?? '',
    );
  }
}
