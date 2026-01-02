import 'package:flutter/material.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/ui/common/app_colors.dart';

/// Weekly peer helpfulness rating screen
/// Staff rate how helpful each colleague was to them this week
class PeerHelpfulnessView extends StatefulWidget {
  const PeerHelpfulnessView({Key? key}) : super(key: key);

  @override
  State<PeerHelpfulnessView> createState() => _PeerHelpfulnessViewState();
}

class _PeerHelpfulnessViewState extends State<PeerHelpfulnessView> {
  final _api = locator<BackendApiService>();
  List<Map<String, dynamic>> _colleagues = [];
  Map<String, int> _ratings = {};
  Map<String, String> _comments = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _weekNumber = 1;
  int _year = 2024;

  @override
  void initState() {
    super.initState();
    _loadColleagues();
  }

  Future<void> _loadColleagues() async {
    setState(() => _isLoading = true);
    try {
      final result = await _api.getColleaguesToRate();
      setState(() {
        _colleagues =
            List<Map<String, dynamic>>.from(result['colleagues'] ?? []);
        _weekNumber = result['weekNumber'] ?? 1;
        _year = result['year'] ?? DateTime.now().year;

        // Pre-fill existing ratings
        for (var colleague in _colleagues) {
          final id = colleague['id'].toString();
          if (colleague['currentRating'] != null) {
            _ratings[id] = colleague['currentRating'];
          }
          if (colleague['currentComment'] != null) {
            _comments[id] = colleague['currentComment'];
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading colleagues: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRatings() async {
    if (_ratings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please rate at least one colleague')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final ratings = _ratings.entries
          .map((e) => {
                'userId': e.key,
                'rating': e.value,
                'comment': _comments[e.key] ?? '',
              })
          .toList();

      await _api.submitPeerHelpfulnessRatings(ratings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ratings submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kcTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'Weekly Team Support',
              style: TextStyle(
                color: kcTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Week $_weekNumber, $_year',
              style: const TextStyle(
                color: kcTextMutedColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _colleagues.isEmpty
              ? _buildEmptyState()
              : _buildColleagueList(),
      bottomNavigationBar:
          !_isLoading && _colleagues.isNotEmpty ? _buildSubmitButton() : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No colleagues to rate',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kcTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColleagueList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _colleagues.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader();
        }
        return _buildColleagueCard(_colleagues[index - 1]);
      },
    );
  }

  Widget _buildHeader() {
    final ratedCount = _ratings.length;
    final totalCount = _colleagues.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kcPrimaryColor.withOpacity(0.1),
            Colors.purple.withOpacity(0.05)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kcPrimaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kcPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.handshake, color: kcPrimaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How helpful were your colleagues?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kcTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rate each colleague based on their support this week',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: totalCount > 0 ? ratedCount / totalCount : 0,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(kcPrimaryColor),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Text(
            '$ratedCount of $totalCount colleagues rated',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColleagueCard(Map<String, dynamic> colleague) {
    final id = colleague['id'].toString();
    final firstName = colleague['firstName'] ?? '';
    final lastName = colleague['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final department = colleague['department'] ?? '';
    final alreadyRated = colleague['alreadyRated'] == true;
    final currentRating = _ratings[id];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: currentRating != null
            ? Border.all(color: kcPrimaryColor.withOpacity(0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Row
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: kcPrimaryColor.withOpacity(0.1),
                child: Text(
                  '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}',
                  style: TextStyle(
                    color: kcPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: kcTextColor,
                      ),
                    ),
                    if (department.isNotEmpty)
                      Text(
                        department,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              if (alreadyRated && currentRating == null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Rated',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Star Rating
          const Text(
            'How helpful were they?',
            style: TextStyle(
              fontSize: 13,
              color: kcTextMutedColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _ratings[id] = starValue;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    currentRating != null && starValue <= currentRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: currentRating != null && starValue <= currentRating
                        ? Colors.amber
                        : Colors.grey[300],
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _getRatingLabel(currentRating),
              style: TextStyle(
                fontSize: 13,
                color:
                    currentRating != null ? kcPrimaryColor : Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingLabel(int? rating) {
    switch (rating) {
      case 1:
        return 'Not Helpful';
      case 2:
        return 'Slightly Helpful';
      case 3:
        return 'Moderately Helpful';
      case 4:
        return 'Very Helpful';
      case 5:
        return 'Extremely Helpful';
      default:
        return 'Tap to rate';
    }
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRatings,
        style: ElevatedButton.styleFrom(
          backgroundColor: kcPrimaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Submit Ratings (${_ratings.length}/${_colleagues.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
