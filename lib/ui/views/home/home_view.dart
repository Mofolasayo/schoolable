import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:schoolable/ui/views/tasks/tasks_view.dart';
import 'package:schoolable/ui/views/attendance/attendance_view.dart';
import 'package:schoolable/ui/views/chat/chat_view.dart';
import 'package:schoolable/ui/views/profile/profile_view.dart';
import 'package:schoolable/ui/views/tasks/task_detail_view.dart';
import 'package:schoolable/ui/views/home/announcements_view.dart';
import 'package:schoolable/ui/views/home/aura_detail_view.dart';
import 'package:schoolable/ui/views/home/team_insights_view.dart';
import 'package:schoolable/ui/common/widgets/app_avatar.dart';

import 'package:schoolable/ui/views/compliance/compliance_submission_view.dart';
import 'package:schoolable/ui/views/home/peer_helpfulness_view.dart';

import 'home_viewmodel.dart';

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
          'job_title': viewModel
              .userRole, // userRole already contains job_title from HomeViewModel
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

                  // Peer Helpfulness Rating Prompt
                  if (viewModel.hasPendingPeerRatings) ...[
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PeerHelpfulnessView(),
                        ),
                      ).then((_) => viewModel.refresh()),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kcPrimaryColor.withOpacity(0.1),
                              Colors.purple.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: kcPrimaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kcPrimaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                children: [
                                  Icon(
                                    Icons.handshake,
                                    color: kcPrimaryColor,
                                    size: 24,
                                  ),
                                  if (viewModel.pendingPeerRatingsCount > 0)
                                    Positioned(
                                      top: -4,
                                      right: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${viewModel.pendingPeerRatingsCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Weekly Team Support',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: kcTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rate how helpful your ${viewModel.pendingPeerRatingsCount} colleagues were this week',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: kcTextMutedColor.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: kcPrimaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Action Required (Compliance)
                  if (viewModel.complianceItems.isNotEmpty) ...[
                    const Row(
                      children: [
                        Icon(Icons.assignment_late_outlined,
                            size: 16, color: kcTextColor),
                        SizedBox(width: 8),
                        Text(
                          'Action Required',
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
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: viewModel.complianceItems.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final item = viewModel.complianceItems[index];
                          return GestureDetector(
                            onTap: () => _showComplianceDetails(context, item),
                            child: Container(
                              width: 280,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: kcBorderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color:
                                              kcPrimaryColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.assignment_late_outlined,
                                                size: 12,
                                                color: kcPrimaryColor),
                                            SizedBox(width: 4),
                                            Text(
                                              'ACTION',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: kcPrimaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      if (item.status == 'pending')
                                        const Icon(Icons.circle,
                                            size: 8, color: kcRoseColor),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: kcTextColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Expanded(
                                    child: Text(
                                      item.description,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: kcTextMutedColor,
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded,
                                          size: 12, color: kcAmberColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Due: ${item.deadline.toString().split(' ')[0]}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: kcAmberColor,
                                        ),
                                      ),
                                    ],
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
                      final isTeamScore = kpi.label == 'Team Score';

                      return GestureDetector(
                        onTap: isTeamScore
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const TeamInsightsView(),
                                  ),
                                );
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isTeamScore
                                  ? const Color(0xFF6366F1).withOpacity(0.3)
                                  : kcBorderColor,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isTeamScore
                                    ? const Color(0xFF6366F1).withOpacity(0.08)
                                    : Colors.black.withValues(alpha: 0.02),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      kpi.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isTeamScore
                                            ? const Color(0xFF6366F1)
                                            : kcTextMutedColor,
                                        letterSpacing: 0.5,
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                                  if (isTeamScore)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.insights,
                                          size: 12,
                                          color: const Color(0xFF6366F1)
                                              .withOpacity(0.7),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'View Insights',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: const Color(0xFF6366F1)
                                                .withOpacity(0.7),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    )
                                  else if (kpi.trend != '--')
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
                                    )
                                  else
                                    Text(
                                      'Current quarter',
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
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Aura Score Card - Always visible
                  _buildAuraScoreCard(context, viewModel),
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
                                'All Time',
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
                        if (viewModel.totalTaskCount == 0) ...[
                          // Empty state
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.chart_bar_alt_fill,
                                  size: 40,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No tasks yet',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your task distribution will appear here',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Bar Chart Representation
                          Builder(
                            builder: (context) {
                              final flex = viewModel.taskDistributionFlex;

                              return Row(
                                children: [
                                  if (flex[0] > 0)
                                    Expanded(
                                      flex: flex[0],
                                      child: Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF575ff4),
                                          borderRadius: BorderRadius.horizontal(
                                            left: const Radius.circular(4),
                                            right: flex[1] == 0 && flex[2] == 0
                                                ? const Radius.circular(4)
                                                : Radius.zero,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (flex[1] > 0)
                                    Expanded(
                                      flex: flex[1],
                                      child: Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFa8acf8),
                                          borderRadius: BorderRadius.horizontal(
                                            left: flex[0] == 0
                                                ? const Radius.circular(4)
                                                : Radius.zero,
                                            right: flex[2] == 0
                                                ? const Radius.circular(4)
                                                : Radius.zero,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (flex[2] > 0)
                                    Expanded(
                                      flex: flex[2],
                                      child: Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFf59e0b),
                                          borderRadius: BorderRadius.horizontal(
                                            left: flex[0] == 0 && flex[1] == 0
                                                ? const Radius.circular(4)
                                                : Radius.zero,
                                            right: const Radius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildLegendItem(
                                  'Completed',
                                  '${viewModel.completedTaskCount}',
                                  const Color(0xFF575ff4)),
                              _buildLegendItem(
                                  'Pending',
                                  '${viewModel.pendingTaskCount}',
                                  const Color(0xFFa8acf8)),
                              _buildLegendItem(
                                  'Overdue',
                                  '${viewModel.overdueTaskCount}',
                                  const Color(0xFFf59e0b)),
                            ],
                          ),
                        ],
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
                  if (viewModel.todayTasks.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 48, horizontal: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kcBorderColor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt_rounded,
                            size: 48,
                            color: kcTextMutedColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No tasks available for you',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: kcTextMutedColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tasks assigned to you will appear here',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: kcTextMutedColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
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
                                builder: (context) =>
                                    TaskDetailView(task: task),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              size: 12,
                                              color: kcTextMutedColor),
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
                                              color: _getPriorityColor(
                                                      task.priority)
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
      case 'Team Score':
        icon = Icons.groups_rounded;
        color = const Color(0xFF6366F1);
        break;
      case 'QGPA':
        icon = Icons.school_rounded;
        color = kcAmberColor;
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

  /// Build the Aura Score card widget
  Widget _buildAuraScoreCard(BuildContext context, HomeViewModel viewModel) {
    final auraData = viewModel.auraData;

    // Loading or no data yet
    if (viewModel.isLoadingAura || auraData == null) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kcBorderColor),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoActivityIndicator(),
              SizedBox(height: 12),
              Text(
                'Calculating Aura...',
                style: TextStyle(
                  color: kcTextMutedColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AuraDetailView(auraData: auraData),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kcBorderColor),
        ),
        child: Row(
          children: [
            // Radial Progress Ring
            SizedBox(
              width: 80,
              height: 80,
              child: CustomPaint(
                painter: _RadialProgressPainter(
                  value: auraData.auraScore / 100,
                  color: kcPrimaryColor,
                  backgroundColor: kcBackgroundColor,
                ),
                child: Center(
                  child: Text(
                    '${auraData.auraScore.round()}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: kcTextColor,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Aura Score',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: kcTextMutedColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Grade ${auraData.grade}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _getGradeTextColor(auraData.grade),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'QGPA: ${auraData.qgpa.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: kcTextMutedColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: kcTextMutedColor.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGradeTextColor(String grade) {
    switch (grade) {
      case 'A':
        return kcTealColor;
      case 'B':
        return kcPrimaryColor;
      case 'C':
        return kcAmberColor;
      case 'D':
      case 'F':
        return kcRoseColor;
      default:
        return kcTextColor;
    }
  }

  void _showComplianceDetails(BuildContext context, ComplianceItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kcPrimaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assignment_late_outlined,
                      color: kcPrimaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compliance Required',
                        style: TextStyle(
                          fontSize: 12,
                          color: kcTextMutedColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kcTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: kcTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              style: const TextStyle(
                fontSize: 15,
                color: kcTextMutedColor,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kcAmberColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kcAmberColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: kcAmberColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deadline',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kcTextColor,
                          ),
                        ),
                        Text(
                          'Complete by ${item.deadline.toString().split(' ')[0]}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: kcTextMutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close sheet
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ComplianceSubmissionView(item: item),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kcPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Complete Action',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _RadialProgressPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color backgroundColor;

  _RadialProgressPainter({
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 10.0;

    // Draw Background
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Draw Progress
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Create a sweep gradient for the progress
    final rect =
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    final gradient = SweepGradient(
      startAngle: -3.14159 / 2,
      endAngle: -3.14159 / 2 + (2 * 3.14159),
      tileMode: TileMode.repeated,
      colors: const [
        Color(0xFF6366F1), // Indigo
        Color(0xFF8B5CF6), // Violet
      ],
    );

    progressPaint.shader = gradient.createShader(rect);

    // Ensure we draw at least a tiny bit if value > 0 but small, or clamp cleanly
    final sweepAngle = 2 * 3.14159 * value.clamp(0.001, 1.0);

    canvas.drawArc(
      rect,
      -3.14159 / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
