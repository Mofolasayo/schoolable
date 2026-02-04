import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/services/websocket_service.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:schoolable/ui/views/compliance/compliance_submission_view.dart';
import 'package:schoolable/ui/views/home/announcement_detail_view.dart';
import 'home_viewmodel.dart'; // To access HomeViewModel and Announcement class

class AnnouncementsView extends StatefulWidget {
  final HomeViewModel viewModel;

  const AnnouncementsView({Key? key, required this.viewModel})
      : super(key: key);

  @override
  State<AnnouncementsView> createState() => _AnnouncementsViewState();
}

class _AnnouncementsViewState extends State<AnnouncementsView> {
  List<Announcement>? _allAnnouncements;
  bool _isLoading = true;
  final _backendService = locator<BackendApiService>();
  final _wsService = locator<WebSocketService>();
  MessageCallback? _notificationHandler;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
    _subscribeToRealtimeUpdates();
  }

  Future<void> _loadAnnouncements() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    final data = await widget.viewModel.fetchAllAnnouncements();
    if (mounted) {
      setState(() {
        _allAnnouncements = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _subscribeToRealtimeUpdates() async {
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
      if (notificationType.contains('announcement')) {
        _loadAnnouncements();
      }
    };

    _wsService.subscribeToNotifications(onNotification: _notificationHandler!);
  }

  @override
  void dispose() {
    if (_notificationHandler != null) {
      _wsService.unsubscribeFromNotifications(_notificationHandler!);
      _notificationHandler = null;
    }
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(color: kcTextColor, fontWeight: FontWeight.bold)),
        backgroundColor: kcBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kcTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AnimatedBuilder(
        animation: widget.viewModel,
        builder: (context, _) {
          // Combine lists for display, or show sections?
          // Let's show sections: "Action Required" vs "Notifications"
          final complianceItems = widget.viewModel.complianceItems.where((item) {
            final status = item.status.toLowerCase();
            return status == 'pending' || status == 'rejected';
          }).toList();
          final announcements = _allAnnouncements
              ?.where((announcement) => !announcement.isRead)
              .toList();

          final isEmpty = (complianceItems.isEmpty) &&
              (announcements == null || announcements.isEmpty);

          if (_isLoading) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 48, color: kcBorderColor),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(color: kcTextMutedColor),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (complianceItems.isNotEmpty) ...[
                const Text(
                  'Action Required',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: kcTextMutedColor,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                ...complianceItems
                    .map((item) => _buildComplianceItem(context, item)),
                const SizedBox(height: 24),
              ],
              if (announcements != null && announcements.isNotEmpty) ...[
                const Text(
                  'Recent Updates',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: kcTextMutedColor,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                ...announcements
                    .map((a) => _buildAnnouncementItem(context, a)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildComplianceItem(BuildContext context, ComplianceItem item) {
    return GestureDetector(
      onTap: () => _showComplianceDetails(context, item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kcSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kcBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kcPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.assignment_late_outlined,
                          size: 14, color: kcPrimaryColor),
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
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: kcRoseColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kcTextColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: kcTextMutedColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 14, color: kcAmberColor),
                const SizedBox(width: 4),
                Text(
                  'Due: ${item.deadline.toString().split(' ')[0]}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: kcAmberColor,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Tap to review',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: kcPrimaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementItem(BuildContext context, Announcement a) {
    return GestureDetector(
      onTap: () {
        // Navigate to announcement detail page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AnnouncementDetailView(
              announcement: a,
              onMarkAsRead: () async {
                await widget.viewModel.markAsRead(a);
                await _loadAnnouncements();
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kcSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: kcBorderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.campaign_rounded,
                  size: 16,
                  color: _getAnnouncementColor(a.type),
                ),
                const SizedBox(width: 8),
                Text(
                  'Announcement',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getAnnouncementColor(a.type),
                  ),
                ),
                const Spacer(),
                Text(
                  a.time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: kcTextMutedColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              a.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: kcTextColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              a.message,
              style: const TextStyle(
                fontSize: 13,
                color: kcTextMutedColor,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
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
                'Acknowledge',
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
} // End of class
