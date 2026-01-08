import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:schoolable/ui/views/home/home_viewmodel.dart';

/// Team Insights View - Simplified and Clean
/// Displays AI-generated insights and recommendations for the team
class TeamInsightsView extends StatelessWidget {
  const TeamInsightsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: () => HomeViewModel(),
      disposeViewModel: false,
      initialiseSpecialViewModelsOnce: true,
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: kcBackgroundColor,
          appBar: AppBar(
            title: const Text(
              'Team Insights',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            backgroundColor: Colors.white,
            foregroundColor: kcTextColor,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: viewModel.isLoadingTeamData
              ? const Center(
                  child: CircularProgressIndicator(color: kcPrimaryColor))
              : RefreshIndicator(
                  onRefresh: () async => viewModel.loadTeamData(),
                  color: kcPrimaryColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Simple Header Stats Row
                        _buildSimpleStatsRow(viewModel),
                        const SizedBox(height: 24),

                        // AI Summary Section
                        if (viewModel.teamInsight != null) ...[
                          _buildSummaryCard(viewModel.teamInsight!),
                          const SizedBox(height: 20),

                          // Insight Sections
                          if (viewModel
                              .teamInsight!.topPerforming.isNotEmpty) ...[
                            _buildInsightSection(
                              'Top Performing',
                              viewModel.teamInsight!.topPerforming,
                              Icons.trending_up_rounded,
                              kcTealColor,
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (viewModel
                              .teamInsight!.needsAttention.isNotEmpty) ...[
                            _buildInsightSection(
                              'Needs Attention',
                              viewModel.teamInsight!.needsAttention,
                              Icons.warning_amber_rounded,
                              kcAmberColor,
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (viewModel
                              .teamInsight!.recommendations.isNotEmpty) ...[
                            _buildInsightSection(
                              'Recommendations',
                              viewModel.teamInsight!.recommendations,
                              Icons.lightbulb_outline_rounded,
                              kcPrimaryColor,
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (viewModel.teamInsight!.riskAlerts.isNotEmpty) ...[
                            _buildInsightSection(
                              'Risk Alerts',
                              viewModel.teamInsight!.riskAlerts,
                              Icons.error_outline_rounded,
                              kcRoseColor,
                            ),
                          ],
                        ] else
                          _buildNoInsightsCard(),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  /// Simple stats row at the top - replaces the big purple card
  Widget _buildSimpleStatsRow(HomeViewModel viewModel) {
    final score = viewModel.teamScore;
    final insight = viewModel.teamInsight;
    final kpiScore = score?.overallScore ?? insight?.kpiScore ?? 0;
    final grade = score?.grade ?? 'N/A';

    return Row(
      children: [
        // KPI Score
        Expanded(
          child: Container(
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kcPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.analytics_outlined,
                        size: 16,
                        color: kcPrimaryColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      score?.quarter ?? 'Q1',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kcTextMutedColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${kpiScore.round()}%',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kcTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Team KPI Score',
                  style: TextStyle(
                    fontSize: 12,
                    color: kcTextMutedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Grade
        Expanded(
          child: Container(
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getGradeColor(grade).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.grade_outlined,
                        size: 16,
                        color: _getGradeColor(grade),
                      ),
                    ),
                    const Spacer(),
                    if (insight != null)
                      Text(
                        'Week ${insight.weekNumber}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kcTextMutedColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  grade,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _getGradeColor(grade),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Overall Grade',
                  style: TextStyle(
                    fontSize: 12,
                    color: kcTextMutedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(TeamInsightData insight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kcPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: kcPrimaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kcTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            insight.summary,
            style: TextStyle(
              fontSize: 14,
              color: kcTextMutedColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightSection(
      String title, List<String> items, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kcTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          color: kcTextMutedColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildNoInsightsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
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
            child: const Icon(
              Icons.insights_outlined,
              size: 32,
              color: kcPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Insights Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kcTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI insights are generated weekly based on your team\'s KPI progress reports.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: kcTextMutedColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String? grade) {
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
        return kcTextMutedColor;
    }
  }
}
