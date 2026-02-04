import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:schoolable/ui/views/home/home_viewmodel.dart';
import 'package:schoolable/ui/views/home/team_insights_view.dart';

class TeamScoreView extends StatelessWidget {
  const TeamScoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: () => HomeViewModel(),
      disposeViewModel: false,
      initialiseSpecialViewModelsOnce: true,
      builder: (context, viewModel, child) {
        final score = viewModel.teamScore;
        final insight = viewModel.teamInsight;
        final scoreNotice = _resolveScoreNotice(score?.aiSummary, insight);

        return Scaffold(
          backgroundColor: kcBackgroundColor,
          appBar: AppBar(
            title: const Text(
              'Team Score',
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
                  child: CircularProgressIndicator(color: kcPrimaryColor),
                )
              : RefreshIndicator(
                  onRefresh: viewModel.loadTeamData,
                  color: kcPrimaryColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (score == null && insight == null)
                          _buildEmptyState()
                        else ...[
                          if (score != null) _buildHeader(score),
                          if (scoreNotice != null) ...[
                            const SizedBox(height: 12),
                            _buildErrorBanner(scoreNotice),
                          ],
                          const SizedBox(height: 16),
                          _buildStatsRow(score, insight),
                          const SizedBox(height: 16),
                          if (score != null) _buildGradeCard(score),
                          if (score != null) const SizedBox(height: 16),
                          if (score?.aiSummary != null &&
                              score!.aiSummary!.isNotEmpty)
                            _buildSummaryCard(
                              title: 'Team Summary',
                              summary: score.aiSummary!,
                            )
                          else if (insight != null)
                            _buildSummaryCard(
                              title: 'Team Summary',
                              summary: insight.summary,
                            ),
                          if (score != null || insight != null)
                            const SizedBox(height: 16),
                          if (insight != null)
                            _buildInsightPreview(context, insight),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  String? _resolveScoreNotice(
      String? scoreSummary, TeamInsightData? insight) {
    if (insight?.generationStatus == 'FALLBACK') {
      return insight?.summary;
    }
    if (scoreSummary == null || scoreSummary.trim().isEmpty) {
      return null;
    }
    final normalized = scoreSummary.toLowerCase();
    if (normalized.contains('could not be accessed') ||
        normalized.contains('no weekly reports') ||
        normalized.contains('team score is 0')) {
      return scoreSummary;
    }
    return null;
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

  Widget _buildHeader(TeamScoreData score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          score.teamName.isNotEmpty ? score.teamName : 'Team Score',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: kcTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${score.quarter} ${score.year} • ${score.department}',
          style: TextStyle(
            fontSize: 12,
            color: kcTextMutedColor.withOpacity(0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(TeamScoreData? score, TeamInsightData? insight) {
    final overallScore = score?.overallScore ?? insight?.kpiScore ?? 0.0;
    final kpiScore = score?.kpiScore ?? insight?.kpiScore ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Overall Score',
            value: '${overallScore.toStringAsFixed(1)}%',
            icon: Icons.insights_rounded,
            color: kcPrimaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'KPI Score',
            value: '${kpiScore.toStringAsFixed(1)}%',
            icon: Icons.track_changes,
            color: kcTealColor,
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
  }) {
    return Container(
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: kcTextColor,
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

  Widget _buildGradeCard(TeamScoreData score) {
    final gradeColor = _getGradeColor(score.grade);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kcBorderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: gradeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                score.grade,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: gradeColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Overall grade for ${score.teamName.isNotEmpty ? score.teamName : 'your team'}',
              style: TextStyle(
                fontSize: 12,
                color: kcTextMutedColor.withOpacity(0.85),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: gradeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              score.grade,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: gradeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required String summary}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kcBorderColor),
      ),
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
          Text(
            summary,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: kcTextMutedColor.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightPreview(BuildContext context, TeamInsightData insight) {
    return Container(
      width: double.infinity,
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
              const Text(
                'Latest AI Insight',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kcTextColor,
                ),
              ),
              const Spacer(),
              Text(
                'Week ${insight.weekNumber}',
                style: TextStyle(
                  fontSize: 11,
                  color: kcTextMutedColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight.summary,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: kcTextMutedColor.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TeamInsightsView(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: kcPrimaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: const Text('View full insights'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.insights_outlined,
              size: 36, color: kcTextMutedColor.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text(
            'No team score available yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kcTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Once your team submits reports and KPIs, the score will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: kcTextMutedColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
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
