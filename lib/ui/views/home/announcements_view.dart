import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:schoolable/ui/common/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    final data = await widget.viewModel.fetchAllAnnouncements();
    if (mounted) {
      setState(() {
        _allAnnouncements = data;
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(color: kcTextColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kcTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _allAnnouncements == null || _allAnnouncements!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _allAnnouncements!.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final a = _allAnnouncements![index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: a.isRead
                            ? Colors.white
                            : kcPrimaryColor.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: a.isRead
                              ? Colors.grey[200]!
                              : kcPrimaryColor.withOpacity(0.2),
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
                              fontWeight:
                                  a.isRead ? FontWeight.w500 : FontWeight.w600,
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
                          ),
                          if (!a.isRead) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  widget.viewModel.markAsRead(a);
                                  setState(() {
                                    // Refresh local list to update UI
                                    _loadAnnouncements();
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Mark as Read',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            )
                          ]
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
