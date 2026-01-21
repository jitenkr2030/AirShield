import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/health_score_data.dart';

/// Card component for displaying health score trend analysis
class TrendAnalysisCard extends StatelessWidget {
  final List<HealthScoreHistory> historicalData;
  final HealthScoreData currentScore;
  final bool showDetailedAnalysis;

  const TrendAnalysisCard({
    Key? key,
    required this.historicalData,
    required this.currentScore,
    this.showDetailedAnalysis = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (historicalData.isEmpty) {
      return _buildEmptyState(context);
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
                  Icons.trending_up,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Trend Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTrendOverview(context),
            const SizedBox(height: 16),
            _buildScoreTrends(context),
            const SizedBox(height: 16),
            _buildInsights(context),
            if (showDetailedAnalysis) ...[
              const SizedBox(height: 16),
              _buildDetailedAnalysis(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendOverview(BuildContext context) {
    final analysis = _analyzeOverallTrend();
    final trendIcon = _getTrendIcon(analysis['direction']);
    final trendColor = _getTrendColor(analysis['direction']);
    final changeAmount = analysis['change'].abs();
    final changeText = analysis['direction'] == 'improving' 
        ? '+$changeAmount points'
        : '-$changeAmount points';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: trendColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            trendIcon,
            color: trendColor,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${analysis['summary']}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Change: $changeText over ${historicalData.length} days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreTrends(BuildContext context) {
    final sortedData = List<HealthScoreHistory>.from(historicalData)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (sortedData.length < 2) {
      return const SizedBox.shrink();
    }

    final earliest = sortedData.first;
    final latest = sortedData.last;

    final trends = [
      _TrendItem('Overall Score', latest.overallScore, earliest.overallScore, Icons.analytics),
      _TrendItem('Respiratory', latest.respiratoryScore, earliest.respiratoryScore, Icons.air),
      _TrendItem('Cardiovascular', latest.cardiovascularScore, earliest.cardiovascularScore, Icons.favorite),
      _TrendItem('Immune System', latest.immuneScore, earliest.immuneScore, Icons.security),
      _TrendItem('Activity Impact', latest.activityImpactScore, earliest.activityImpactScore, Icons.directions_run),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Component Trends',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...trends.map((trend) => _buildTrendItem(context, trend)),
      ],
    );
  }

  Widget _buildTrendItem(BuildContext context, _TrendItem trend) {
    final change = trend.currentScore - trend.previousScore;
    final changeText = change >= 0 ? '+$change' : '$change';
    final changeColor = change >= 0 ? Colors.green : Colors.red;
    final changeIcon = change >= 0 ? Icons.trending_up : Icons.trending_down;
    final trendDirection = _getTrendDirection(change);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            trend.icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trend.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${trend.previousScore} → ${trend.currentScore}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      changeIcon,
                      size: 14,
                      color: changeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$changeText ($trendDirection)',
                      style: TextStyle(
                        fontSize: 12,
                        color: changeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsights(BuildContext context) {
    final insights = _generateInsights();

    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Insights',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...insights.map((insight) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  insight,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildDetailedAnalysis(BuildContext context) {
    final analysis = _generateDetailedAnalysis();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Analysis',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            analysis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.trending_up,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Trend Data Available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Collect more health score data to see trends and insights',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _analyzeOverallTrend() {
    if (historicalData.length < 2) {
      return {
        'direction': 'stable',
        'change': 0,
        'summary': 'Insufficient data for trend analysis',
      };
    }

    final sortedData = List<HealthScoreHistory>.from(historicalData)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final firstScore = sortedData.first.overallScore;
    final lastScore = sortedData.last.overallScore;
    final change = lastScore - firstScore;

    String direction;
    String summary;

    if (change > 5) {
      direction = 'improving';
      summary = 'Your health score is improving';
    } else if (change < -5) {
      direction = 'declining';
      summary = 'Your health score is declining';
    } else {
      direction = 'stable';
      summary = 'Your health score is stable';
    }

    return {
      'direction': direction,
      'change': change.round(),
      'summary': summary,
    };
  }

  List<String> _generateInsights() {
    final insights = <String>[];

    if (historicalData.length < 3) {
      return ['Continue tracking to identify patterns'];
    }

    final sortedData = List<HealthScoreHistory>.from(historicalData)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Analyze overall score trend
    final overallTrend = _analyzeComponentTrend(
      sortedData.map((d) => d.overallScore).toList(),
    );

    if (overallTrend == 'improving') {
      insights.add('Your overall health score shows positive improvement');
    } else if (overallTrend == 'declining') {
      insights.add('Your overall health score has declined recently');
    }

    // Analyze respiratory score trend
    final respiratoryTrend = _analyzeComponentTrend(
      sortedData.map((d) => d.respiratoryScore).toList(),
    );

    if (respiratoryTrend == 'declining') {
      insights.add('Respiratory health may need attention');
    } else if (respiratoryTrend == 'improving') {
      insights.add('Respiratory health is improving');
    }

    // Analyze cardiovascular trend
    final cardiovascularTrend = _analyzeComponentTrend(
      sortedData.map((d) => d.cardiovascularScore).toList(),
    );

    if (cardiovascularTrend == 'declining') {
      insights.add('Cardiovascular health requires monitoring');
    }

    // Check for volatility
    final volatility = _calculateVolatility(
      sortedData.map((d) => d.overallScore).toList(),
    );

    if (volatility > 15) {
      insights.add('Your health score shows high variability - consider environmental factors');
    }

    return insights;
  }

  String _generateDetailedAnalysis() {
    if (historicalData.length < 5) {
      return 'More data points are needed for a comprehensive trend analysis. Continue tracking your health score regularly.';
    }

    final sortedData = List<HealthScoreHistory>.from(historicalData)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final daysTracked = sortedData.length;
    final scoreRange = _calculateScoreRange(sortedData.map((d) => d.overallScore).toList());
    final volatility = _calculateVolatility(sortedData.map((d) => d.overallScore).toList());
    final improvementRate = _calculateImprovementRate(sortedData.map((d) => d.overallScore).toList());

    return '''
Based on $daysTracked days of data:
- Score range: ${scoreRange['min']} - ${scoreRange['max']} points
- Volatility: ${volatility.toInt()}% (variation from average)
- Improvement rate: ${improvementRate >= 0 ? '+' : ''}${improvementRate.toStringAsFixed(1)} points per week

${_getRecommendationBasedOnTrends(improvementRate, volatility)}
''';
  }

  String _analyzeComponentTrend(List<int> scores) {
    if (scores.length < 3) return 'stable';

    final firstThird = scores.sublist(0, scores.length ~/ 3);
    final lastThird = scores.sublist((scores.length * 2) ~/ 3);

    final firstAvg = firstThird.reduce((a, b) => a + b) / firstThird.length;
    final lastAvg = lastThird.reduce((a, b) => a + b) / lastThird.length;
    final change = lastAvg - firstAvg;

    if (change > 5) return 'improving';
    if (change < -5) return 'declining';
    return 'stable';
  }

  double _calculateVolatility(List<int> scores) {
    if (scores.isEmpty) return 0;

    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final variance = scores.map((score) => (score - mean) * (score - mean)).reduce((a, b) => a + b) / scores.length;
    final standardDeviation = variance.sqrt();

    return (standardDeviation / mean) * 100;
  }

  Map<String, int> _calculateScoreRange(List<int> scores) {
    return {
      'min': scores.reduce(math.min),
      'max': scores.reduce(math.max),
    };
  }

  double _calculateImprovementRate(List<int> scores) {
    if (scores.length < 2) return 0;

    final sortedScores = List<int>.from(scores)..sort();
    final firstScore = sortedScores.first;
    final lastScore = sortedScores.last;
    final weeks = scores.length / 7; // Assuming daily measurements

    return (lastScore - firstScore) / weeks;
  }

  String _getRecommendationBasedOnTrends(double improvementRate, double volatility) {
    if (volatility > 20) {
      return 'High volatility suggests external factors significantly affect your health score. Consider tracking your activities and environmental conditions more closely.';
    } else if (improvementRate > 2) {
      return 'Your positive trend indicates current health practices are effective. Continue your current approach.';
    } else if (improvementRate < -2) {
      return 'The declining trend suggests you may need to reassess your health protection strategies.';
    } else {
      return 'Your stable trend indicates consistent health conditions. Continue monitoring for any changes.';
    }
  }

  IconData _getTrendIcon(String direction) {
    switch (direction) {
      case 'improving':
        return Icons.trending_up;
      case 'declining':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(String direction) {
    switch (direction) {
      case 'improving':
        return Colors.green;
      case 'declining':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTrendDirection(int change) {
    if (change > 5) return 'improving';
    if (change < -5) return 'declining';
    return 'stable';
  }
}

/// Quick trend indicator widget
class QuickTrendIndicator extends StatelessWidget {
  final List<HealthScoreHistory> historicalData;
  final int currentScore;
  final bool compact;

  const QuickTrendIndicator({
    Key? key,
    required this.historicalData,
    required this.currentScore,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (historicalData.isEmpty) {
      return _buildNoDataState(context);
    }

    final trend = _calculateQuickTrend();
    final trendColor = _getTrendColor(trend['direction']);
    final trendIcon = _getTrendIcon(trend['direction']);

    if (compact) {
      return _buildCompactIndicator(context, trendIcon, trendColor);
    }

    return _buildDetailedIndicator(context, trendIcon, trendColor);
  }

  Widget _buildCompactIndicator(BuildContext context, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '${trend['change'] >= 0 ? '+' : ''}${trend['change']}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedIndicator(BuildContext context, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            '${trend['direction']} (${trend['change'] >= 0 ? '+' : ''}${trend['change']})',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.help_outline,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 6),
          Text(
            'No data',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateQuickTrend() {
    if (historicalData.length < 2) {
      return {'direction': 'stable', 'change': 0};
    }

    final sortedData = List<HealthScoreHistory>.from(historicalData)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final previousScore = sortedData.last.overallScore;
    final change = currentScore - previousScore;

    String direction;
    if (change > 3) direction = 'improving';
    else if (change < -3) direction = 'declining';
    else direction = 'stable';

    return {
      'direction': direction,
      'change': change,
    };
  }

  IconData _getTrendIcon(String direction) {
    switch (direction) {
      case 'improving':
        return Icons.trending_up;
      case 'declining':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(String direction) {
    switch (direction) {
      case 'improving':
        return Colors.green;
      case 'declining':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _TrendItem {
  final String name;
  final int currentScore;
  final int previousScore;
  final IconData icon;

  _TrendItem(this.name, this.currentScore, this.previousScore, this.icon);
}