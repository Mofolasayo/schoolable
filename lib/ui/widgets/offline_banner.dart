import 'dart:async';
import 'package:flutter/material.dart';
import 'package:schoolable/services/connectivity_service.dart';
import 'package:schoolable/ui/common/app_colors.dart';

/// A widget that displays an offline banner when there's no network connectivity.
/// Place this at the top of your scaffold body or wrap your main content with it.
class OfflineBanner extends StatefulWidget {
  final Widget child;
  final bool showSyncStatus;

  const OfflineBanner({
    Key? key,
    required this.child,
    this.showSyncStatus = false,
  }) : super(key: key);

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  final ConnectivityService _connectivityService = ConnectivityService();
  late StreamSubscription<bool> _subscription;
  bool _isOffline = false;
  int _pendingSyncCount = 0;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Check initial status
    _isOffline = !_connectivityService.isOnline;
    if (_isOffline) {
      _animationController.forward();
    }
    _loadPendingSyncCount();

    // Listen for changes
    _subscription = _connectivityService.onlineStatusStream.listen((isOnline) {
      setState(() {
        _isOffline = !isOnline;
      });
      if (_isOffline) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
      _loadPendingSyncCount();
    });
  }

  Future<void> _loadPendingSyncCount() async {
    if (widget.showSyncStatus) {
      final count = await _connectivityService.getPendingSyncCount();
      if (mounted) {
        setState(() {
          _pendingSyncCount = count;
        });
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Offline Banner
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            if (!_isOffline && _slideAnimation.value <= -0.99) {
              return const SizedBox.shrink();
            }
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -1),
                end: Offset.zero,
              ).animate(_animationController),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _isOffline ? Colors.grey.shade800 : kcTealColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      Icon(
                        _isOffline
                            ? Icons.cloud_off_rounded
                            : Icons.cloud_done_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isOffline ? "You're offline" : "Back online",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (_isOffline &&
                                widget.showSyncStatus &&
                                _pendingSyncCount > 0)
                              Text(
                                '$_pendingSyncCount ${_pendingSyncCount == 1 ? 'action' : 'actions'} pending sync',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 11,
                                ),
                              ),
                            if (!_isOffline)
                              Text(
                                'Syncing your data...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_isOffline)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cached, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Cached',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Main content
        Expanded(child: widget.child),
      ],
    );
  }
}

/// A small sync indicator for the app bar
class SyncIndicator extends StatefulWidget {
  const SyncIndicator({Key? key}) : super(key: key);

  @override
  State<SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator>
    with SingleTickerProviderStateMixin {
  final ConnectivityService _connectivityService = ConnectivityService();
  late StreamSubscription<bool> _subscription;
  bool _isOffline = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _isOffline = !_connectivityService.isOnline;

    _subscription = _connectivityService.onlineStatusStream.listen((isOnline) {
      setState(() {
        _isOffline = !isOnline;
      });
      if (!isOnline) {
        _rotationController.stop();
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            'Offline',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
