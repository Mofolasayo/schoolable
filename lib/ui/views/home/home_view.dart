import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:schoolable/ui/views/tasks/tasks_view.dart';
import 'package:schoolable/ui/views/attendance/attendance_view.dart';
import 'package:schoolable/ui/views/chat/chat_view.dart';
import 'package:schoolable/ui/views/profile/profile_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:schoolable/ui/views/tasks/task_detail_view.dart';
import 'package:schoolable/ui/views/home/announcements_view.dart';
import 'package:schoolable/ui/common/widgets/app_avatar.dart'; // Added import

import 'home_viewmodel.dart';

import 'package:schoolable/ui/views/tasks/task_model.dart';
import 'package:flutter/cupertino.dart'; // Add this import

class HomeView extends StackedView<HomeViewModel> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget builder(BuildContext context, HomeViewModel viewModel, Widget? child) {
    return Scaffold(
      backgroundColor: kcBackgroundColor,
      body: viewModel.isBusy
          ? const Center(child: CupertinoActivityIndicator())
          : _getViewForIndex(viewModel.currentTab, viewModel),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: kcBorderColor)),
        ),
        child: BottomNavigationBar(
          currentIndex: viewModel.currentTab,
          onTap: viewModel.setTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: kcPrimaryColor,
          unselectedItemColor: kcTextMutedColor,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.task_alt_rounded),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_rounded),
              label: 'Check-in',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_rounded),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _getViewForIndex(int index, HomeViewModel viewModel) {
    switch (index) {
      case 0:
        return const _HomeContent();
      case 1:
        return const TasksView();
      case 2:
        return const AttendanceView();
      case 3:
        return const ChatView();
      case 4:
        // Pass cached profile data to avoid flickering
        return ProfileView(userProfile: {
          'full_name': viewModel.userName,
          'role': viewModel.userRole,
          'department': viewModel.userDepartment,
          'status': viewModel.userStatus,
          'gender': viewModel.userGender,
          'avatar_url': viewModel.avatarUrl,
        });
      default:
        return const _HomeContent();
    }
  }

  @override
  HomeViewModel viewModelBuilder(BuildContext context) => HomeViewModel();
}

class _HomeContent extends ViewModelWidget<HomeViewModel> {
  const _HomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, HomeViewModel viewModel) {
    return SafeArea(
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: viewModel.refresh,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: kcPrimaryColor, width: 2),
                            ),
                            child: AppAvatar(
                              imageUrl: viewModel.avatarUrl,
                              radius: 24,
                              fallbackInitials:
                                  viewModel.userName?.split(' ').first ?? 'U',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${viewModel.userName?.split(' ').first ?? 'User'}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kcTextColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (viewModel.userRole != null ||
                                  viewModel.userDepartment != null)
                                Row(
                                  children: [
                                    if (viewModel.userRole != null) ...[
                                      Text(
                                        viewModel.userRole!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: kcTextMutedColor.withValues(
                                              alpha: 0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (viewModel.userDepartment != null) ...[
                                        const Text(' • ',
                                            style: TextStyle(
                                                color: kcTextMutedColor)),
                                        Text(
                                          viewModel.userDepartment!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: kcTextMutedColor.withValues(
                                                alpha: 0.8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ] else if (viewModel.userDepartment != null)
                                      Text(
                                        viewModel.userDepartment!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: kcTextMutedColor.withValues(
                                              alpha: 0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                )
                              else
                                Text(
                                  'Let\'s be productive today',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        kcTextMutedColor.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Status Badge
                          const SizedBox(width: 8),
                          // Notifications Button
                          InkWell(
                            onTap: () =>
                                _showAllAnnouncements(context, viewModel),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kcBorderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(
                                    Icons.notifications_outlined,
                                    color: kcTextColor,
                                    size: 22,
                                  ),
                                  if (viewModel.announcements.isNotEmpty)
                                    Positioned(
                                      top: -2,
                                      right: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: kcRoseColor,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          '${viewModel.announcements.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // KPI Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: viewModel.kpiCards.length,
                    itemBuilder: (context, index) {
                      final kpi = viewModel.kpiCards[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kcBorderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  kpi.label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: kcTextMutedColor,
                                    letterSpacing: 0.5,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _getKpiIcon(kpi.label),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kpi.value,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: kcTextColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      kpi.trend,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: kpi.trend.startsWith('+')
                                            ? kcTealColor
                                            : kcRoseColor,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'vs last week',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: kcTextMutedColor.withValues(
                                            alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Task Distribution Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kcBorderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Task Distribution',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: kcTextColor,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'By current task status',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kcTextMutedColor,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: kcBackgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Today',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: kcTextMutedColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Simple Bar Chart Representation
                        Row(
                          children: [
                            Expanded(
                              flex: 62,
                              child: Container(
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF575ff4),
                                  borderRadius: BorderRadius.horizontal(
                                      left: Radius.circular(4)),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 27,
                              child: Container(
                                height: 8,
                                color: const Color(0xFFa8acf8),
                              ),
                            ),
                            Expanded(
                              flex: 11,
                              child: Container(
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFf59e0b),
                                  borderRadius: BorderRadius.horizontal(
                                      right: Radius.circular(4)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildLegendItem(
                                'Completed', '148', const Color(0xFF575ff4)),
                            _buildLegendItem(
                                'Pending', '64', const Color(0xFFa8acf8)),
                            _buildLegendItem(
                                'Overdue', '26', const Color(0xFFf59e0b)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Announcements
                  if (viewModel.announcements.isNotEmpty) ...[
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Announcements',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: kcTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 130,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: viewModel.announcements.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final announcement = viewModel.announcements[index];
                          return GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(24)),
                                  ),
                                  padding:
                                      const EdgeInsets.fromLTRB(24, 12, 24, 32),
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.of(context).size.height *
                                            0.60,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Drag handle
                                      Center(
                                        child: Container(
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Header
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: _getAnnouncementColor(
                                                      announcement.type)
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.campaign_rounded,
                                              color: _getAnnouncementColor(
                                                  announcement.type),
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Announcement',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getAnnouncementColor(
                                                      announcement.type),
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                announcement.time,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: kcTextMutedColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),

                                      // Content
                                      Text(
                                        announcement.title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: kcTextColor,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Text(
                                            announcement.message,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(
                                                  0xFF4B5563), // Slate 600
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Action Button
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            viewModel.markAsRead(announcement);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: kcPrimaryColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: const Text(
                                            'Mark as Read',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 260,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: kcBorderColor,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.campaign_rounded,
                                        size: 16,
                                        color: _getAnnouncementColor(
                                            announcement.type),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Announcement',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _getAnnouncementColor(
                                              announcement.type),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        announcement.time,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: kcTextMutedColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    announcement.title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: kcTextColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    announcement.message,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: kcTextMutedColor,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Today's Tasks
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today\'s Tasks',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kcTextColor,
                        ),
                      ),
                      InkWell(
                        onTap: () => viewModel.setTab(1),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kcPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: viewModel.todayTasks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final task = viewModel.todayTasks[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailView(task: task),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kcBorderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: task.status == 'Completed'
                                        ? kcPrimaryColor
                                        : kcBorderColor,
                                    width: 2,
                                  ),
                                  color: task.status == 'Completed'
                                      ? kcPrimaryColor
                                      : Colors.transparent,
                                ),
                                child: task.status == 'Completed'
                                    ? const Icon(Icons.check,
                                        size: 12, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: kcTextColor,
                                        decoration: task.status == 'Completed'
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time,
                                            size: 12, color: kcTextMutedColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          task.due,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: kcTextMutedColor,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color:
                                                _getPriorityColor(task.priority)
                                                    .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            task.priority,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: _getPriorityColor(
                                                  task.priority),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: kcTextMutedColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kcTextColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _getKpiIcon(String label) {
    IconData icon;
    Color color;

    switch (label) {
      case 'Task Score':
        icon = Icons.assignment_turned_in_rounded;
        color = kcPrimaryColor;
        break;
      case 'Attendance':
        icon = Icons.location_on_rounded;
        color = kcTealColor;
        break;
      case 'Compliance':
        icon = Icons.verified_user_rounded;
        color = kcPurpleColor;
        break;
      case 'Feedback':
        icon = Icons.star_rounded;
        color = kcAmberColor;
        break;
      default:
        icon = Icons.analytics_rounded;
        color = kcTextMutedColor;
    }

    return Icon(icon, size: 18, color: color);
  }

  Color _getPriorityColor(String priority) {
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

  Color _getAnnouncementColor(String type) {
    switch (type) {
      case 'alert':
        return kcRoseColor;
      case 'success':
        return kcTealColor;
      case 'info':
      default:
        return kcPrimaryColor;
    }
  }

  void _showAllAnnouncements(BuildContext context, HomeViewModel viewModel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnouncementsView(viewModel: viewModel),
      ),
    );
  }
}
