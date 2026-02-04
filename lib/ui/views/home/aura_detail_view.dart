import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:schoolable/ui/views/home/home_viewmodel.dart';

/// Detailed Aura Score breakdown page with expandable pillar sub-metrics
class AuraDetailView extends StatefulWidget {
  final AuraData auraData;

  const AuraDetailView({Key? key, required this.auraData}) : super(key: key);

  @override
  State<AuraDetailView> createState() => _AuraDetailViewState();
}

class _AuraDetailViewState extends State<AuraDetailView> {
  String? expandedPillarKey;

  // Individual KPIs state
  List<IndividualKpi> myKpis = [];
  double myKpiAverageAchievement = 0;
  bool isLoadingKpis = true;

  late AuraData _auraData;
  bool auraLoadFailed = false;

  AuraData get auraData => _auraData;

  @override
  void initState() {
    super.initState();
    _auraData = widget.auraData;
    _fetchMyKpis();
  }

  Future<void> _fetchMyKpis({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        isLoadingKpis = true;
      });
    }
    try {
      final backendService = locator<BackendApiService>();
      final response = await backendService.getMyIndividualKpis();
      if (response != null && mounted) {
        final kpisList = response['kpis'] as List<dynamic>? ?? [];
        setState(() {
          myKpis = kpisList
              .map((k) => IndividualKpi.fromMap(k as Map<String, dynamic>))
              .toList();
          myKpiAverageAchievement =
              (response['averageAchievement'] as num?)?.toDouble() ?? 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          myKpis = [];
          myKpiAverageAchievement = 0;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingKpis = false;
        });
      }
    }
  }

  Future<void> _refreshAura() async {
    if (mounted) {
      setState(() {
        auraLoadFailed = false;
      });
    }

    try {
      final backendService = locator<BackendApiService>();
      final data = await backendService.getAutoAuraDashboard();
      if (data != null) {
        if (mounted) {
          setState(() {
            _auraData = AuraData.fromMap(data);
          });
        }
      } else {
        final fallback = await backendService.getMyAuraDashboard();
        if (fallback != null && mounted) {
          setState(() {
            _auraData = AuraData.fromMap(fallback);
          });
        } else if (mounted) {
          setState(() {
            auraLoadFailed = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          auraLoadFailed = true;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _refreshAura(),
      _fetchMyKpis(showLoader: false),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final pillars = auraData.pillars.values.toList();

    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: AppBar(
        backgroundColor: kcBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kcTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Aura Score Details',
          style: TextStyle(
            color: kcTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: kcPrimaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (auraLoadFailed)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kcAmberColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: kcAmberColor.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 18, color: kcAmberColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Unable to refresh Aura data. Showing the last saved score.',
                          style: TextStyle(
                            fontSize: 12,
                            color: kcTextMutedColor.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Main Score Card
              _buildMainScoreCard(),
              const SizedBox(height: 24),

              // Grade Info Card
              _buildGradeInfoCard(),
              const SizedBox(height: 24),

              // My KPIs Section
              _buildMyKpisSection(),
              const SizedBox(height: 24),

              // Pillar Breakdown
              _buildSectionHeader(
                title: 'Performance Breakdown',
                subtitle: 'Tap a pillar to see detailed sub-metrics',
              ),
              const SizedBox(height: 16),

              // Pillar Cards (with index for key tracking)
              ...pillars.asMap().entries.map(
                  (entry) => _buildPillarCard(entry.value, entry.key.toString())),

              const SizedBox(height: 24),

              // Info Section
              _buildInfoSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainScoreCard() {
    final auraScore =
        auraData.qgpa > 0 ? auraData.qgpa : auraData.auraScore / 20;
    final auraScoreText = auraScore.toStringAsFixed(1);
    final scoreChange =
        auraData.scoreChange != null ? auraData.scoreChange! / 20 : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aura Score',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kcTextMutedColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  auraScoreText,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: kcTextColor,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildMetaPill(
                      'Grade ${auraData.grade}',
                      color: _getGradeColor(auraData.grade),
                      useFill: false,
                    ),
                    const SizedBox(width: 8),
                    _buildMetaPill(
                      'QGPA ${auraData.qgpa.toStringAsFixed(2)}',
                      color: kcTextMutedColor,
                      useFill: false,
                    ),
                  ],
                ),
                if (scoreChange != null && scoreChange != 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${scoreChange > 0 ? '+' : ''}${scoreChange.toStringAsFixed(1)} today',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scoreChange > 0 ? kcTealColor : kcRoseColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 84,
            height: 84,
            child: CustomPaint(
              painter: _RadialProgressPainter(
                value: auraScore / 5,
                color: kcPrimaryColor,
                backgroundColor: kcBorderColor.withOpacity(0.4),
              ),
              child: Center(
                child: Text(
                  auraScoreText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kcTextColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Text(
            auraData.grade,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _getGradeColor(auraData.grade),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGradeDescription(auraData.grade),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kcTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getGradeSubtext(auraData.grade),
                  style: TextStyle(
                    fontSize: 12,
                    color: kcTextMutedColor.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the My KPIs section showing individual KPIs set by team lead
  Widget _buildMyKpisSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'My Individual KPIs',
          subtitle: 'KPIs set by your team lead for this quarter',
        ),
        const SizedBox(height: 10),

        // KPIs Content
        if (isLoadingKpis)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: const Center(
              child: CupertinoActivityIndicator(),
            ),
          )
        else if (myKpis.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                const Text(
                  'No KPIs yet',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kcTextColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your team lead hasn\'t set individual KPIs for you this quarter.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: kcTextMutedColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                // Average Achievement Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Average Achievement',
                            style: TextStyle(
                              fontSize: 12,
                              color: kcTextMutedColor,
                            ),
                          ),
                          Text(
                            '${myKpiAverageAchievement.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: kcTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kcBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kcBorderColor),
                      ),
                      child: Text(
                        '${myKpis.length} KPIs',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kcTextMutedColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // KPI List
                ...myKpis.map((kpi) => _buildKpiItem(kpi)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader({required String title, String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: kcTextColor,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: kcTextMutedColor.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetaPill(String label,
      {Color color = kcTextMutedColor, bool useFill = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: useFill ? color.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: kcSurfaceColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kcBorderColor.withOpacity(0.6)),
    );
  }

  Widget _buildKpiItem(IndividualKpi kpi) {
    final progressColor = kpi.achievementPercentage >= 80
        ? kcTealColor
        : kpi.achievementPercentage >= 50
            ? kcAmberColor
            : kcRoseColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  kpi.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kcTextColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${kpi.achievementPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (kpi.description != null && kpi.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                kpi.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: kcTextMutedColor.withOpacity(0.85),
                ),
              ),
            ),
          Row(
            children: [
              Text(
                'Current: ${kpi.currentValue.toStringAsFixed(1)} / Target: ${kpi.targetValue.toStringAsFixed(1)} ${kpi.targetUnit ?? ''}',
                style: TextStyle(
                  fontSize: 11,
                  color: kcTextMutedColor.withOpacity(0.9),
                ),
              ),
              const Spacer(),
              Text(
                'Weight: ${kpi.weight}%',
                style: TextStyle(
                  fontSize: 11,
                  color: kcTextMutedColor.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (kpi.achievementPercentage / 100).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: kcBorderColor.withOpacity(0.35),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarCard(PillarDetail pillar, String pillarKey) {
    final isExpanded = expandedPillarKey == pillarKey;

    // Determine data source label
    String sourceLabel;
    if (pillar.dataSource == 'auto') {
      sourceLabel = 'Automated';
    } else if (pillar.dataSource == 'mixed') {
      sourceLabel = 'Mixed Sources';
    } else {
      sourceLabel = 'Team Lead';
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (expandedPillarKey == pillarKey) {
            expandedPillarKey = null;
          } else {
            expandedPillarKey = pillarKey;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kcSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded
                ? kcPrimaryColor.withOpacity(0.35)
                : kcBorderColor.withOpacity(0.6),
          ),
        ),
        child: Column(
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _getPillarIcon(pillar.name),
                  color: kcPrimaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pillar.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kcTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$sourceLabel · ${pillar.weight.round()}% weight',
                        style: TextStyle(
                          fontSize: 11,
                          color: kcTextMutedColor.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${pillar.score.round()}%',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: kcTextColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: kcTextMutedColor.withOpacity(0.6),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress Bar
            Stack(
              children: [
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kcBackgroundColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: pillar.score / 100,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: _getScoreColor(pillar.score),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Contribution ',
                  style: TextStyle(
                    fontSize: 11,
                    color: kcTextMutedColor.withOpacity(0.7),
                  ),
                ),
                Text(
                  '+${pillar.contribution.toStringAsFixed(1)} points',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kcTextColor,
                  ),
                ),
              ],
            ),
            // Expanded Sub-metrics Section
            if (isExpanded && pillar.subMetrics.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kcBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kcBorderColor.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sub-metrics',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kcTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...pillar.subMetrics.map((sm) => _buildSubMetricRow(sm)),
                  ],
                ),
              ),
            ] else if (isExpanded && pillar.subMetrics.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Sub-metrics will be available soon.',
                style: TextStyle(
                  fontSize: 12,
                  color: kcTextMutedColor.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubMetricRow(SubMetricDetail sm) {
    // Get source icon
    IconData sourceIcon;
    switch (sm.source.toLowerCase()) {
      case 'auto':
        sourceIcon = Icons.settings_suggest;
        break;
      case 'team_lead':
        sourceIcon = Icons.person;
        break;
      case 'peer_feedback':
        sourceIcon = Icons.people;
        break;
      case 'admin':
        sourceIcon = Icons.admin_panel_settings;
        break;
      default:
        sourceIcon = Icons.data_usage;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            sourceIcon,
            size: 14,
            color: kcTextMutedColor,
          ),
          const SizedBox(width: 10),
          // Name and Weight
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sm.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kcTextColor,
                  ),
                ),
                Text(
                  '${sm.weightInPillar.round()}% of pillar',
                  style: TextStyle(
                    fontSize: 10,
                    color: kcTextMutedColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          // Score
          Text(
            '${sm.score.round()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getScoreColor(sm.score),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Understanding your score',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kcTextColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            'Technical (35%)',
            'Daily reports, task completion, individual KPIs',
          ),
          _buildInfoItem(
            'Behavioral (25%)',
            'Attendance, punctuality, work consistency',
          ),
          _buildInfoItem(
            'Culture Fit (20%)',
            'Policy compliance, values alignment',
          ),
          _buildInfoItem(
            'Growth (20%)',
            'Training, certifications, improvement trend',
          ),
          const SizedBox(height: 12),
          Divider(color: kcBorderColor.withOpacity(0.5)),
          const SizedBox(height: 10),
          Text(
            'Most of your score is calculated automatically from daily activity.',
            style: TextStyle(
              fontSize: 12,
              color: kcTextMutedColor.withOpacity(0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          // Update frequency
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Score updates',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: kcTextMutedColor,
                ),
              ),
              Text(
                'Daily at 11:59 PM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: kcTextColor.withOpacity(0.85),
                ),
              ),
            ],
          ),
          if (auraData.quarterStart != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Quarter',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: kcTextMutedColor,
                  ),
                ),
                Text(
                  auraData.quarterStart!.substring(0, 7),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kcTextColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            color: kcTextMutedColor,
            height: 1.5,
            fontFamily: 'Inter',
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: kcTextColor,
              ),
            ),
            TextSpan(text: desc),
          ],
        ),
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

  String _getGradeDescription(String grade) {
    switch (grade) {
      case 'A':
        return 'Excellent Performance';
      case 'B':
        return 'Good Performance';
      case 'C':
        return 'Average Performance';
      case 'D':
        return 'Below Average';
      case 'F':
        return 'Needs Improvement';
      default:
        return 'Not Rated';
    }
  }

  String _getGradeSubtext(String grade) {
    switch (grade) {
      case 'A':
        return 'Keep up the outstanding work!';
      case 'B':
        return 'You\'re doing great, push a bit more!';
      case 'C':
        return 'There\'s room for improvement.';
      case 'D':
        return 'Focus on improving key areas.';
      case 'F':
        return 'Consult with your team lead for support.';
      default:
        return 'Data not available yet.';
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return kcTealColor;
    if (score >= 60) return kcPrimaryColor;
    if (score >= 40) return kcAmberColor;
    return kcRoseColor;
  }

  IconData _getPillarIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('technical')) return Icons.code;
    if (lower.contains('behavioral')) return Icons.psychology;
    if (lower.contains('culture')) return Icons.favorite;
    if (lower.contains('growth') || lower.contains('learning'))
      return Icons.trending_up;
    if (lower.contains('collaboration')) return Icons.group;
    return Icons.auto_awesome;
  }
}

class _RadialProgressPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color backgroundColor;

  _RadialProgressPainter({
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 10.0;

    // Draw Background
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Draw Progress
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    progressPaint.color = color;

    final sweepAngle = 2 * 3.14159 * value.clamp(0.001, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -3.14159 / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
