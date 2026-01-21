import 'package:flutter/material.dart';

/// Card component for displaying health score breakdown by category
class ScoreBreakdownCard extends StatelessWidget {
  final int respiratoryScore;
  final int cardiovascularScore;
  final int immuneScore;
  final int activityImpactScore;
  final bool showTrends;
  final bool compact;

  const ScoreBreakdownCard({
    Key? key,
    required this.respiratoryScore,
    required this.cardiovascularScore,
    required this.immuneScore,
    required this.activityImpactScore,
    this.showTrends = false,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactBreakdown(context);
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Health Score Breakdown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ..._buildScoreItems(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactBreakdown(BuildContext context) {
    final scores = [
      _ScoreItem('Respiratory', respiratoryScore, Icons.air, Colors.green),
      _ScoreItem('Cardiovascular', cardiovascularScore, Icons.favorite, Colors.red),
      _ScoreItem('Immune System', immuneScore, Icons.security, Colors.orange),
      _ScoreItem('Daily Activities', activityImpactScore, Icons.directions_run, Colors.blue),
    ];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: scores.map((score) => _buildCompactScoreItem(context, score)).toList(),
        ),
      ),
    );
  }

  List<Widget> _buildScoreItems(BuildContext context) {
    final scores = [
      _ScoreItem('Respiratory Health', respiratoryScore, Icons.air, Colors.green),
      _ScoreItem('Cardiovascular Health', cardiovascularScore, Icons.favorite, Colors.red),
      _ScoreItem('Immune System', immuneScore, Icons.security, Colors.orange),
      _ScoreItem('Activity Impact', activityImpactScore, Icons.directions_run, Colors.blue),
    ];

    return scores.map((score) => _buildScoreItem(context, score)).toList();
  }

  Widget _buildScoreItem(BuildContext context, _ScoreItem score) {
    final color = _getScoreColor(score.score);
    final label = _getScoreLabel(score.score);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                score.icon,
                color: score.color,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  score.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${score.score}/100',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildProgressBar(context, score.score, color),
        ],
      ),
    );
  }

  Widget _buildCompactScoreItem(BuildContext context, _ScoreItem score) {
    final color = _getScoreColor(score.score);
    final label = _getScoreLabel(score.score);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            score.icon,
            color: score.color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              score.title,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${score.score}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, int score, Color color) {
    return Stack(
      children: [
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        FractionallySizedBox(
          widthFactor: score / 100,
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 65) return Colors.lightGreen;
    if (score >= 50) return Colors.amber;
    if (score >= 30) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 65) return 'Good';
    if (score >= 50) return 'Fair';
    if (score >= 30) return 'Poor';
    return 'Critical';
  }
}

/// Detailed score breakdown with additional information
class DetailedScoreBreakdownCard extends StatefulWidget {
  final int respiratoryScore;
  final int cardiovascularScore;
  final int immuneScore;
  final int activityImpactScore;
  final Map<String, dynamic>? contributingFactors;
  final Function(_ScoreItem)? onScoreTap;

  const DetailedScoreBreakdownCard({
    Key? key,
    required this.respiratoryScore,
    required this.cardiovascularScore,
    required this.immuneScore,
    required this.activityImpactScore,
    this.contributingFactors,
    this.onScoreTap,
  }) : super(key: key);

  @override
  State<DetailedScoreBreakdownCard> createState() => _DetailedScoreBreakdownCardState();
}

class _DetailedScoreBreakdownCardState extends State<DetailedScoreBreakdownCard> {
  int _expandedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final scores = [
      _ScoreItem('Respiratory Health', widget.respiratoryScore, Icons.air, Colors.green, 
        'Breathing health impact from air quality'),
      _ScoreItem('Cardiovascular Health', widget.cardiovascularScore, Icons.favorite, Colors.red,
        'Heart health impact from pollutants'),
      _ScoreItem('Immune System', widget.immuneScore, Icons.security, Colors.orange,
        'Immune system resilience to pollution'),
      _ScoreItem('Activity Impact', widget.activityImpactScore, Icons.directions_run, Colors.blue,
        'Impact on daily activities and exercise'),
    ];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Detailed Health Score Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...scores.asMap().entries.map((entry) {
              final index = entry.key;
              final score = entry.value;
              return _buildDetailedScoreItem(context, score, index);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedScoreItem(BuildContext context, _ScoreItem score, int index) {
    final isExpanded = _expandedIndex == index;
    final color = _getScoreColor(score.score);
    final label = _getScoreLabel(score.score);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedIndex = isExpanded ? -1 : index;
              });
              widget.onScoreTap?.call(score);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    score.icon,
                    color: score.color,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          score.title,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          score.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${score.score}/100',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: color,
                        ),
                      ),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            _buildExpandedContent(context, score),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, _ScoreItem score) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScoreAnalysis(context, score),
          const SizedBox(height: 12),
          _buildRecommendations(context, score),
          const SizedBox(height: 12),
          _buildContributingFactors(context, score),
        ],
      ),
    );
  }

  Widget _buildScoreAnalysis(BuildContext context, _ScoreItem score) {
    final analysis = _getScoreAnalysis(score.score, score.title);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            analysis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context, _ScoreItem score) {
    final recommendations = _getRecommendations(score.score, score.title);
    
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specific Recommendations',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...recommendations.map((rec) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.arrow_right,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rec,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildContributingFactors(BuildContext context, _ScoreItem score) {
    final factors = _getContributingFactors(score.title);
    
    if (factors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Factors',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...factors.entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Text(
                '${entry.key}:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.value.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  String _getScoreAnalysis(int score, String category) {
    if (category.contains('Respiratory')) {
      if (score >= 80) return 'Your respiratory system shows excellent resilience to current air quality conditions.';
      if (score >= 65) return 'Your respiratory health is generally good, but monitor for any breathing changes.';
      if (score >= 50) return 'Air quality is moderately affecting your respiratory health. Consider protective measures.';
      if (score >= 30) return 'Poor air quality is significantly impacting your breathing health. Take immediate action.';
      return 'Critical respiratory health impact. Seek medical attention and minimize exposure.';
    } else if (category.contains('Cardiovascular')) {
      if (score >= 80) return 'Your cardiovascular system demonstrates strong resistance to air pollution effects.';
      if (score >= 65) return 'Heart health is good, but continue monitoring during high pollution periods.';
      if (score >= 50) return 'Air quality is moderately affecting cardiovascular health. Be cautious with physical activities.';
      if (score >= 30) return 'Poor air quality poses significant cardiovascular risks. Consider medical consultation.';
      return 'Critical cardiovascular risk from air pollution. Immediate medical attention recommended.';
    } else if (category.contains('Immune')) {
      if (score >= 80) return 'Your immune system shows excellent resilience and recovery capacity.';
      if (score >= 65) return 'Immune system health is good, but maintain healthy lifestyle practices.';
      if (score >= 50) return 'Air quality is moderately weakening immune system function.';
      if (score >= 30) return 'Poor air quality is significantly impacting immune system health.';
      return 'Critical immune system impact from air pollution. Strengthen health practices immediately.';
    } else {
      if (score >= 80) return 'Air quality has minimal impact on your daily activities and exercise capacity.';
      if (score >= 65) return 'Daily activities are largely unaffected, but be mindful during high pollution.';
      if (score >= 50) return 'Air quality moderately restricts outdoor activities and exercise options.';
      if (score >= 30) return 'Significant impact on outdoor activities. Consider indoor alternatives.';
      return 'Major restrictions on outdoor activities and exercise. Prioritize indoor environments.';
    }
  }

  List<String> _getRecommendations(int score, String category) {
    if (category.contains('Respiratory')) {
      if (score < 50) return [
        'Use N95 masks when outdoors',
        'Keep windows closed during high pollution',
        'Consider air purifiers with HEPA filters',
        'Monitor breathing patterns closely',
      ];
      return ['Maintain good ventilation indoors', 'Avoid outdoor exercise during peak pollution hours'];
    } else if (category.contains('Cardiovascular')) {
      if (score < 50) return [
        'Reduce strenuous outdoor activities',
        'Monitor heart rate during exercise',
        'Consider indoor exercise alternatives',
        'Consult cardiologist if experiencing symptoms',
      ];
      return ['Be mindful during high pollution days', 'Choose less polluted routes for outdoor activities'];
    } else if (category.contains('Immune')) {
      if (score < 50) return [
        'Increase antioxidant-rich foods',
        'Consider vitamin D and C supplements',
        'Ensure adequate sleep and stress management',
        'Practice deep breathing exercises indoors',
      ];
      return ['Maintain healthy diet and exercise routine', 'Focus on stress reduction and adequate sleep'];
    } else {
      if (score < 50) return [
        'Move exercise indoors during poor air days',
        'Use air quality apps to plan activities',
        'Consider exercising during early morning or evening',
        'Choose less polluted areas for outdoor activities',
      ];
      return ['Plan activities around air quality forecasts', 'Choose optimal times for outdoor activities'];
    }
  }

  Map<String, dynamic> _getContributingFactors(String category) {
    if (category.contains('Respiratory')) {
      return {
        'PM2.5 Impact': 'High',
        'Age Factor': 'Moderate',
        'Health Conditions': 'None reported',
        'Activity Level': 'Moderate',
      };
    } else if (category.contains('Cardiovascular')) {
      return {
        'PM2.5 Impact': 'High',
        'Age Factor': 'Moderate',
        'BMI': 'Normal',
        'Exercise Frequency': '3-4 times/week',
      };
    } else if (category.contains('Immune')) {
      return {
        'Overall Health': 'Good',
        'Sleep Quality': 'Adequate',
        'Stress Level': 'Moderate',
        'Nutrition': 'Balanced',
      };
    } else {
      return {
        'Current AQI': 'Moderate',
        'Activity Preferences': 'Outdoor sports',
        'Location': 'Urban area',
        'Weather Conditions': 'Clear',
      };
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 65) return Colors.lightGreen;
    if (score >= 50) return Colors.amber;
    if (score >= 30) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 65) return 'Good';
    if (score >= 50) return 'Fair';
    if (score >= 30) return 'Poor';
    return 'Critical';
  }
}

class _ScoreItem {
  final String title;
  final int score;
  final IconData icon;
  final Color color;
  final String description;

  _ScoreItem(this.title, this.score, this.icon, this.color, [this.description = '']);
}

/// Quick health score overview widget
class QuickScoreOverview extends StatelessWidget {
  final int respiratoryScore;
  final int cardiovascularScore;
  final int immuneScore;
  final int activityImpactScore;
  final Function()? onTap;

  const QuickScoreOverview({
    Key? key,
    required this.respiratoryScore,
    required this.cardiovascularScore,
    required this.immuneScore,
    required this.activityImpactScore,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scores = [
      respiratoryScore,
      cardiovascularScore,
      immuneScore,
      activityImpactScore,
    ];
    
    final averageScore = scores.reduce((a, b) => a + b) ~/ scores.length;
    final color = _getScoreColor(averageScore);
    final label = _getScoreLabel(averageScore);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Score Overview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  '$averageScore',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 65) return Colors.lightGreen;
    if (score >= 50) return Colors.amber;
    if (score >= 30) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent health';
    if (score >= 65) return 'Good health';
    if (score >= 50) return 'Fair health';
    if (score >= 30) return 'Poor health';
    return 'Critical health';
  }
}