import 'package:flutter/material.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'home_viewmodel.dart';

/// A clean, simple announcement detail page
class AnnouncementDetailView extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback? onMarkAsRead;

  const AnnouncementDetailView({
    Key? key,
    required this.announcement,
    this.onMarkAsRead,
  }) : super(key: key);

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

  IconData _getAnnouncementIcon(String type) {
    switch (type) {
      case 'alert':
        return Icons.warning_rounded;
      case 'success':
        return Icons.check_circle_rounded;
      case 'info':
      default:
        return Icons.campaign_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getAnnouncementColor(announcement.type);
    final icon = _getAnnouncementIcon(announcement.type);
    final isUnread = !announcement.isRead;

    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kcTextColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Announcement',
          style: TextStyle(
            color: kcTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: color, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              announcement.type.toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kcPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: kcPrimaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: kcTextMutedColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            announcement.time,
                            style: const TextStyle(
                              fontSize: 12,
                              color: kcTextMutedColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    announcement.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: kcTextColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kcTextMutedColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    announcement.message,
                    style: const TextStyle(
                      fontSize: 15,
                      color: kcTextColor,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mark as Read Button (if not already read)
            if (!announcement.isRead)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onMarkAsRead?.call();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kcPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Mark as Read',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // Done/Close Button (if already read)
            if (announcement.isRead)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kcTextColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: kcBorderColor),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
