import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:schoolable/services/logging_service.dart';

/// Weekly Pulse Survey for quick team sentiment checks
class PulseSurveyView extends StackedView<PulseSurveyViewModel> {
  const PulseSurveyView({Key? key}) : super(key: key);

  @override
  PulseSurveyViewModel viewModelBuilder(BuildContext context) =>
      PulseSurveyViewModel();

  @override
  void onViewModelReady(PulseSurveyViewModel viewModel) {
    viewModel.initialize();
  }

  @override
  Widget builder(
      BuildContext context, PulseSurveyViewModel viewModel, Widget? child) {
    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Weekly Pulse',
          style: TextStyle(
            color: kcTextColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: kcTextColor),
      ),
      body: viewModel.isBusy
          ? const Center(child: CircularProgressIndicator())
          : viewModel.hasNoSurvey
              ? _buildNoSurveyState()
              : viewModel.hasSubmitted
                  ? _buildSubmittedState(viewModel)
                  : _buildSurveyContent(context, viewModel),
    );
  }

  Widget _buildNoSurveyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kcPrimaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: kcPrimaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Survey Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kcTextColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'There\'s no pulse survey this week.\nCheck back next week!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: kcTextMutedColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmittedState(PulseSurveyViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.teal.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.thumb_up,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Thanks for your feedback!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kcTextColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your response helps us understand\nhow the team is feeling.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: kcTextMutedColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kcBorderColor.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  const Text(
                    'You responded:',
                    style: TextStyle(
                      fontSize: 12,
                      color: kcTextMutedColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final emoji = _getEmoji(index + 1);
                      final isSelected = index + 1 == viewModel.submittedRating;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          emoji,
                          style: TextStyle(
                            fontSize: isSelected ? 48 : 24,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyContent(
      BuildContext context, PulseSurveyViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Survey header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kcPrimaryColor.withValues(alpha: 0.1),
                  Colors.blue.withValues(alpha: 0.05)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  '📊',
                  style: TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  viewModel.surveyQuestion,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kcTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Week ${viewModel.weekNumber}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: kcTextMutedColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Rating options
          const Text(
            'How do you feel?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kcTextColor,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final rating = index + 1;
              final emoji = _getEmoji(rating);
              final label = _getLabel(rating);
              final isSelected = viewModel.selectedRating == rating;

              return GestureDetector(
                onTap: () => viewModel.setRating(rating),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _getRatingColor(rating).withValues(alpha: 0.15)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? _getRatingColor(rating)
                          : kcBorderColor.withValues(alpha: 0.5),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _getRatingColor(rating)
                                  .withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        emoji,
                        style: TextStyle(
                          fontSize: isSelected ? 40 : 32,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? _getRatingColor(rating)
                              : kcTextMutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 32),

          // Optional comment
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Any additional thoughts? (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kcTextColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: viewModel.commentController,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Share what\'s on your mind...',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: kcTextMutedColor,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kcBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kcBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kcPrimaryColor, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Anonymous notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your response is anonymous. We only collect aggregate data.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  viewModel.selectedRating != null && !viewModel.isSubmitting
                      ? () => viewModel.submitSurvey()
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kcPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                disabledBackgroundColor: kcPrimaryColor.withValues(alpha: 0.5),
              ),
              child: viewModel.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Submit Response',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getEmoji(int rating) {
    switch (rating) {
      case 1:
        return '😞';
      case 2:
        return '😐';
      case 3:
        return '🙂';
      case 4:
        return '😊';
      case 5:
        return '🤩';
      default:
        return '😶';
    }
  }

  String _getLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Very Bad';
      case 2:
        return 'Bad';
      case 3:
        return 'Okay';
      case 4:
        return 'Good';
      case 5:
        return 'Great';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

/// ViewModel for Pulse Survey
class PulseSurveyViewModel extends BaseViewModel {
  final BackendApiService _backendService = locator<BackendApiService>();
  final TextEditingController commentController = TextEditingController();

  String? _surveyId;
  String _surveyQuestion = 'How are you feeling at work this week?';
  int _weekNumber = 1;
  int? _selectedRating;
  bool _hasNoSurvey = false;
  bool _hasSubmitted = false;
  bool _isSubmitting = false;
  int? _submittedRating;

  String get surveyQuestion => _surveyQuestion;
  int get weekNumber => _weekNumber;
  int? get selectedRating => _selectedRating;
  bool get hasNoSurvey => _hasNoSurvey;
  bool get hasSubmitted => _hasSubmitted;
  bool get isSubmitting => _isSubmitting;
  int? get submittedRating => _submittedRating;

  Future<void> initialize() async {
    await _loadCurrentSurvey();
  }

  Future<void> _loadCurrentSurvey() async {
    setBusy(true);
    try {
      final survey = await _backendService.getCurrentPulseSurvey();

      if (survey == null || survey['id'] == null) {
        _hasNoSurvey = true;
      } else {
        _surveyId = survey['id'].toString();
        _surveyQuestion =
            survey['question'] ?? 'How are you feeling at work this week?';
        _weekNumber = survey['week_number'] ?? _calculateWeekNumber();
        _hasSubmitted = survey['already_responded'] == true;
        _submittedRating = survey['my_response'];
      }
    } catch (e) {
      AppLogger.log('Error loading pulse survey: $e');
      _hasNoSurvey = true;
    } finally {
      setBusy(false);
    }
  }

  int _calculateWeekNumber() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    return ((now.difference(startOfYear).inDays + startOfYear.weekday) / 7)
        .ceil();
  }

  void setRating(int rating) {
    _selectedRating = rating;
    rebuildUi();
  }

  Future<void> submitSurvey() async {
    if (_surveyId == null || _selectedRating == null) return;

    _isSubmitting = true;
    rebuildUi();

    try {
      final success = await _backendService.submitPulseSurveyResponse(
        surveyId: _surveyId!,
        rating: _selectedRating!,
        comment: commentController.text.trim().isNotEmpty
            ? commentController.text.trim()
            : null,
      );

      if (success) {
        _hasSubmitted = true;
        _submittedRating = _selectedRating;
      }
    } catch (e) {
      AppLogger.log('Error submitting pulse survey: $e');
    } finally {
      _isSubmitting = false;
      rebuildUi();
    }
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }
}