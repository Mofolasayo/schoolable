import 'package:flutter/material.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'home_viewmodel.dart';

/// A full-page view for displaying announcement details
class AnnouncementDetailView extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDetailView({
    Key? key,
    required this.announcement,
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

  String _formatDate(String time) {
    // Return the time string as-is since it's already formatted
    return time;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getAnnouncementColor(announcement.type);
    final icon = _getAnnouncementIcon(announcement.type);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App bar with gradient
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: color,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                announcement.type.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    announcement.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kcTextColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Time
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: kcTextMutedColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(announcement.time),
                        style: const TextStyle(
                          fontSize: 13,
                          color: kcTextMutedColor,
                        ),
                      ),
                      if (!announcement.isRead) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: kcPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: kcPrimaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.grey[100],
                  ),

                  const SizedBox(height: 32),

                  // Content section
                  const Text(
                    'Message',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: kcTextMutedColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Message content
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[100]!),
                    ),
                    child: Text(
                      announcement.message,
                      style: const TextStyle(
                        fontSize: 15,
                        color: kcTextColor,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
