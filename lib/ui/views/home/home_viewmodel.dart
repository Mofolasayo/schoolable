import 'package:stacked/stacked.dart';

class KpiCard {
  KpiCard({required this.label, required this.value, required this.trend});

  final String label;
  final String value;
  final String trend;
}

class TaskItem {
  TaskItem({
    required this.title,
    required this.description,
    required this.due,
    required this.status,
    required this.priority,
    required this.progress,
  });

  final String title;
  final String description;
  final String due;
  final String status;
  final String priority;
  final int progress;
}

class ChatMessage {
  ChatMessage({
    required this.sender,
    required this.time,
    required this.text,
    required this.isMe,
  });

  final String sender;
  final String time;
  final String text;
  final bool isMe;
}

class Announcement {
  Announcement({
    required this.title,
    required this.message,
    required this.time,
    required this.type,
  });

  final String title;
  final String message;
  final String time;
  final String type; // 'info', 'alert', 'success'
}

class HomeViewModel extends BaseViewModel {
  int currentTab = 0;

  final kpiCards = <KpiCard>[
    KpiCard(label: 'Task Score', value: '92%', trend: '+5%'),
    KpiCard(label: 'Attendance', value: '88%', trend: '+2%'),
    KpiCard(label: 'Compliance', value: '96%', trend: '+1%'),
    KpiCard(label: 'Feedback', value: '4.6', trend: '+0.3'),
  ];

  final announcements = <Announcement>[
    Announcement(
      title: 'New Policy Update',
      message: 'Please review the updated remote work guidelines.',
      time: '2h ago',
      type: 'info',
    ),
    Announcement(
      title: 'System Maintenance',
      message: 'Scheduled downtime this Saturday at 2 AM.',
      time: '5h ago',
      type: 'alert',
    ),
    Announcement(
      title: 'Goal Reached!',
      message: 'Q3 targets have been met. Great job team!',
      time: '1d ago',
      type: 'success',
    ),
  ];

  final todayTasks = <TaskItem>[
    TaskItem(
      title: 'Update onboarding tickets',
      description: 'Refresh copy for new attendance rules.',
      due: 'Today · 4:00 PM',
      status: 'In Progress',
      priority: 'High',
      progress: 65,
    ),
    TaskItem(
      title: 'Close support tickets',
      description: 'Resolve pending escalations in Support',
      due: 'Today · 6:00 PM',
      status: 'Pending',
      priority: 'Medium',
      progress: 0,
    ),
    TaskItem(
      title: 'Weekly standup notes',
      description: 'Summarize achievements and risks',
      due: 'Tomorrow',
      status: 'Draft',
      priority: 'Low',
      progress: 20,
    ),
  ];

  final chatMessages = <ChatMessage>[
    ChatMessage(
      sender: 'Olivia',
      time: '09:14',
      text: 'Reminder: maintenance Sat 2AM',
      isMe: false,
    ),
    ChatMessage(
      sender: 'You',
      time: '09:16',
      text: 'Copy, will notify ops.',
      isMe: true,
    ),
    ChatMessage(
      sender: 'Alex',
      time: '09:20',
      text: 'Drafting announcement now.',
      isMe: false,
    ),
  ];

  void setTab(int index) {
    currentTab = index;
    rebuildUi();
  }
}
