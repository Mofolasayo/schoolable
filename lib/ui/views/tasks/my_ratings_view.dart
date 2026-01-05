import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/ui/common/app_colors.dart';

/// View showing ratings received by the current user on their completed tasks
class MyRatingsView extends StackedView<MyRatingsViewModel> {
  const MyRatingsView({Key? key}) : super(key: key);

  @override
  MyRatingsViewModel viewModelBuilder(BuildContext context) =>
      MyRatingsViewModel();

  @override
  void onViewModelReady(MyRatingsViewModel viewModel) {
    viewModel.initialize();
  }

  @override
  Widget builder(
      BuildContext context, MyRatingsViewModel viewModel, Widget? child) {
    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Performance Ratings',
          style: TextStyle(
            color: kcTextColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: kcTextColor),
        actions: [
          IconButton(
            onPressed: viewModel.refresh,
            icon: const Icon(Icons.refresh_rounded, size: 22),
          ),
        ],
      ),
      body: viewModel.isBusy
          ? const Center(
              child: CupertinoActivityIndicator(),
            )
          : viewModel.hasError
              ? _buildErrorState(viewModel)
              : _buildContent(context, viewModel),
    );
  }

  Widget _buildErrorState(MyRatingsViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline,
                  size: 48, color: Colors.red.shade400),
            ),
            const SizedBox(height: 20),
            const Text(
              'Failed to load ratings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kcTextColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again',
              style: TextStyle(fontSize: 14, color: kcTextMutedColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: viewModel.refresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kcPrimaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MyRatingsViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Average Rating Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kcPrimaryColor, kcPrimaryColor.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'Your Average Task Rating',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Colors.amber.shade300,
                      size: 40,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      viewModel.averageRating?.toStringAsFixed(1) ?? '—',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '/5',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (viewModel.totalRatingsCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Based on ${viewModel.totalRatingsCount} rated ${viewModel.totalRatingsCount == 1 ? "task" : "tasks"}',
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Rating Breakdown
          if (viewModel.ratingBreakdown.isNotEmpty) ...[
            const Text(
              'Rating Distribution',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kcTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kcBorderColor),
              ),
              child: Column(
                children: List.generate(5, (index) {
                  final starCount = 5 - index;
                  final count = viewModel.ratingBreakdown[starCount] ?? 0;
                  final total = viewModel.totalRatingsCount;
                  final percentage = total > 0 ? (count / total) * 100 : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '$starCount',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: kcTextColor,
                            ),
                          ),
                        ),
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: kcBorderColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: percentage / 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _getRatingColor(starCount),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 30,
                          child: Text(
                            '$count',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: kcTextMutedColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Recent Ratings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Task Ratings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kcTextColor,
                ),
              ),
              Text(
                '${viewModel.taskRatings.length} tasks',
                style: const TextStyle(fontSize: 12, color: kcTextMutedColor),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (viewModel.taskRatings.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kcBorderColor),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kcPrimaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_border_rounded,
                        color: kcPrimaryColor, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No ratings yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kcTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Complete tasks to receive ratings from your team lead',
                    style: TextStyle(fontSize: 13, color: kcTextMutedColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...viewModel.taskRatings.map((rating) => _buildRatingCard(rating)),

          const SizedBox(height: 24),

          // Peer Helpfulness Ratings Section
          if (viewModel.peerRatings.isNotEmpty) ...[
            const Text(
              'Peer Helpfulness Feedback',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kcTextColor,
              ),
            ),
            const SizedBox(height: 12),
            ...viewModel.peerRatings
                .map((rating) => _buildPeerRatingCard(rating)),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> rating) {
    final taskTitle = rating['task_title'] ?? rating['taskTitle'] ?? 'Task';
    final ratingValue = rating['rating'] ?? rating['score'] ?? 0;
    final comment = rating['comment'] ?? rating['feedback'];
    final ratedBy = rating['rated_by'] ?? rating['ratedBy'] ?? 'Team Lead';
    final ratedAt = rating['rated_at'] ?? rating['ratedAt'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kcBorderColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  taskTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: kcTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRatingColor(ratingValue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded,
                        color: _getRatingColor(ratingValue), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      ratingValue.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getRatingColor(ratingValue),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kcBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote,
                      size: 16, color: kcTextMutedColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      comment,
                      style: const TextStyle(
                        fontSize: 13,
                        color: kcTextColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 14, color: kcTextMutedColor),
              const SizedBox(width: 4),
              Text(
                ratedBy,
                style: const TextStyle(fontSize: 11, color: kcTextMutedColor),
              ),
              if (ratedAt != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.access_time,
                    size: 14, color: kcTextMutedColor),
                const SizedBox(width: 4),
                Text(
                  _formatDate(ratedAt),
                  style: const TextStyle(fontSize: 11, color: kcTextMutedColor),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeerRatingCard(Map<String, dynamic> rating) {
    final fromName = rating['from_name'] ?? rating['fromName'] ?? 'Colleague';
    final score = rating['rating'] ?? rating['score'] ?? 0;
    final feedback = rating['feedback'] ?? rating['comment'];
    final week = rating['week_number'] ?? rating['weekNumber'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kcBorderColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kcTealColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.handshake_rounded,
                color: kcTealColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fromName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if (week != null)
                  Text(
                    'Week $week',
                    style:
                        const TextStyle(fontSize: 11, color: kcTextMutedColor),
                  ),
                if (feedback != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      feedback,
                      style: const TextStyle(
                          fontSize: 12, color: kcTextMutedColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getRatingColor(score).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.star_rounded,
                    color: _getRatingColor(score), size: 16),
                const SizedBox(width: 2),
                Text(
                  '$score',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getRatingColor(score),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}';
    } catch (_) {
      return dateStr;
    }
  }

  Color _getRatingColor(int rating) {
    if (rating >= 5) return Colors.green;
    if (rating >= 4) return Colors.teal;
    if (rating >= 3) return Colors.amber;
    if (rating >= 2) return Colors.orange;
    return Colors.red;
  }
}

/// ViewModel for My Ratings View
class MyRatingsViewModel extends BaseViewModel {
  final BackendApiService _backendService = locator<BackendApiService>();

  double? _averageRating;
  double? get averageRating => _averageRating;

  int _totalRatingsCount = 0;
  int get totalRatingsCount => _totalRatingsCount;

  Map<int, int> _ratingBreakdown = {};
  Map<int, int> get ratingBreakdown => _ratingBreakdown;

  List<Map<String, dynamic>> _taskRatings = [];
  List<Map<String, dynamic>> get taskRatings => _taskRatings;

  List<Map<String, dynamic>> _peerRatings = [];
  List<Map<String, dynamic>> get peerRatings => _peerRatings;

  Future<void> initialize() async {
    await refresh();
  }

  Future<void> refresh() async {
    setBusy(true);
    setError(null);

    try {
      // Fetch task quality ratings received
      final employeeId = _backendService.currentUserId;
      if (employeeId != null) {
        final avgResult = await _backendService.getAverageRating(employeeId);
        _averageRating = (avgResult['averageRating'] as num?)?.toDouble();
        _totalRatingsCount = avgResult['totalRatings'] as int? ?? 0;

        // Get task ratings list
        _taskRatings = (avgResult['ratings'] as List<dynamic>?)
                ?.map((r) => Map<String, dynamic>.from(r as Map))
                .toList() ??
            [];

        // Calculate rating breakdown
        _ratingBreakdown = {};
        for (final rating in _taskRatings) {
          final score = rating['rating'] as int? ?? 0;
          _ratingBreakdown[score] = (_ratingBreakdown[score] ?? 0) + 1;
        }
      }

      // Fetch peer helpfulness ratings received
      try {
        final peerResult = await _backendService.getReceivedRatings();
        _peerRatings = (peerResult['ratings'] as List<dynamic>?)
                ?.map((r) => Map<String, dynamic>.from(r as Map))
                .toList() ??
            [];
      } catch (e) {
        print('Error fetching peer ratings: $e');
        _peerRatings = [];
      }

      notifyListeners();
    } catch (e) {
      setError(e);
    } finally {
      setBusy(false);
    }
  }
}
