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
                fontWeight: FontWeight.w700,
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
                        if (viewModel.teamInsight?.generationStatus ==
                            'FALLBACK') ...[
                          const SizedBox(height: 16),
                          _buildErrorBanner(viewModel.teamInsight!.summary),
                        ],
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
                              kcTealColor,
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (viewModel
                              .teamInsight!.needsAttention.isNotEmpty) ...[
                            _buildInsightSection(
                              'Needs Attention',
                              viewModel.teamInsight!.needsAttention,
                              kcAmberColor,
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (viewModel
                              .teamInsight!.recommendations.isNotEmpty) ...[
                            _buildInsightSection(
                              'Recommendations',
                              viewModel.teamInsight!.recommendations,
                              kcPrimaryColor,
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (viewModel.teamInsight!.riskAlerts.isNotEmpty) ...[
                            _buildInsightSection(
                              'Risk Alerts',
                              viewModel.teamInsight!.riskAlerts,
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
    final kpiScore = score?.kpiScore ?? insight?.kpiScore ?? 0;
    final grade = score?.grade ?? 'N/A';

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Team KPI Score',
            value: '${kpiScore.round()}%',
            icon: Icons.track_changes,
            color: kcTealColor,
            meta: score?.quarter ?? 'Q1',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'Overall Grade',
            value: grade,
            icon: Icons.grade_outlined,
            color: _getGradeColor(grade),
            meta: insight != null ? 'Week ${insight.weekNumber}' : null,
            valueColor: _getGradeColor(grade),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? meta,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
              if (meta != null)
                Text(
                  meta,
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
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor ?? kcTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: kcTextMutedColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kcAmberColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kcAmberColor.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 18, color: kcAmberColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Insight generation issue',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kcTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  style: TextStyle(
                    fontSize: 12,
                    color: kcTextMutedColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(TeamInsightData insight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Summary',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kcTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            insight.summary,
            style: TextStyle(
              fontSize: 12,
              color: kcTextMutedColor.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightSection(
      String title, List<String> items, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kcTextColor,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => _buildInsightItem(item, color)),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String item, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item,
              style: TextStyle(
                fontSize: 12,
                color: kcTextMutedColor.withOpacity(0.9),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoInsightsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(
            Icons.insights_outlined,
            size: 32,
            color: kcTextMutedColor.withOpacity(0.6),
          ),
          const SizedBox(height: 12),
          const Text(
            'No Insights Yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kcTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'AI insights are generated weekly based on your team\'s KPI progress reports.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: kcTextMutedColor.withOpacity(0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kcBorderColor),
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
