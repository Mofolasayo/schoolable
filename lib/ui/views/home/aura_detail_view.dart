import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:schoolable/ui/views/home/home_viewmodel.dart';

/// Detailed Aura Score breakdown page
class AuraDetailView extends StatelessWidget {
  final AuraData auraData;

  const AuraDetailView({Key? key, required this.auraData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pillars = auraData.pillars.values.toList();

    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Score Card
            _buildMainScoreCard(),
            const SizedBox(height: 32),

            // Grade Info Card
            _buildGradeInfoCard(),
            const SizedBox(height: 32),

            // Pillar Breakdown
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: kcPrimaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Performance Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kcTextColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Detailed analysis across all 5 measurement pillars',
              style: TextStyle(
                fontSize: 14,
                color: kcTextMutedColor.withOpacity(0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Pillar Cards
            ...pillars.map((pillar) => _buildPillarCard(pillar)),

            const SizedBox(height: 32),

            // Info Section
            _buildInfoSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMainScoreCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kcBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Large Radial Progress
          SizedBox(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: _RadialProgressPainter(
                value: auraData.auraScore / 100,
                color: kcPrimaryColor,
                backgroundColor: kcBackgroundColor,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${auraData.auraScore.round()}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: kcTextColor,
                        height: 1,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '/100',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: kcTextMutedColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Grade & QGPA Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getGradeColor(auraData.grade).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(
                      'Grade ${auraData.grade}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getGradeColor(auraData.grade),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: kcBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'QGPA ${auraData.qgpa.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kcTextMutedColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradeInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kcBorderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _getGradeColor(auraData.grade).withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                auraData.grade,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _getGradeColor(auraData.grade),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGradeDescription(auraData.grade),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kcTextColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getGradeSubtext(auraData.grade),
                  style: TextStyle(
                    fontSize: 13,
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

  Widget _buildPillarCard(PillarDetail pillar) {
    // Determine data source label
    String sourceLabel;
    if (pillar.dataSource == 'auto') {
      sourceLabel = 'Automated';
    } else if (pillar.dataSource == 'mixed') {
      sourceLabel = 'Mixed Sources';
    } else {
      sourceLabel = 'Team Lead';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kcBorderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kcPrimaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getPillarIcon(pillar.name),
                  color: kcPrimaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pillar.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kcTextColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kcBackgroundColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: kcBorderColor),
                          ),
                          child: Text(
                            sourceLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: kcTextMutedColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${pillar.weight.round()}% Weight',
                          style: TextStyle(
                            fontSize: 11,
                            color: kcTextMutedColor.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${pillar.score.round()}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: kcTextColor,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: kcBackgroundColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: pillar.score / 100,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: _getScoreColor(pillar.score),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Contributes ',
                style: TextStyle(
                  fontSize: 11,
                  color: kcTextMutedColor.withOpacity(0.6),
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
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kcBorderColor.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kcBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: kcTextMutedColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Understanding your score',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: kcTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoItem(
              'Technical', 'Based on your task completion & quality'),
          _buildInfoItem(
              'Behavioral', 'Work ethic & professionalism (Team Lead rated)'),
          _buildInfoItem('Culture Fit', 'Values alignment and collaboration'),
          _buildInfoItem('Growth', 'Learning initiatives and certifications'),
          const SizedBox(height: 16),
          Divider(color: kcBorderColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          if (auraData.quarterStart != null)
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
      ),
    );
  }

  Widget _buildInfoItem(String label, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: kcTextMutedColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
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
    const strokeWidth = 14.0;

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

    // Create a sweep gradient for the progress
    final rect =
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    final gradient = SweepGradient(
      startAngle: -3.14159 / 2,
      endAngle: -3.14159 / 2 + (2 * 3.14159),
      tileMode: TileMode.repeated,
      colors: const [
        Color(0xFF6366F1), // Indigo
        Color(0xFF8B5CF6), // Violet
      ],
    );

    progressPaint.shader = gradient.createShader(rect);

    final sweepAngle = 2 * 3.14159 * value.clamp(0.001, 1.0);

    canvas.drawArc(
      rect,
      -3.14159 / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
