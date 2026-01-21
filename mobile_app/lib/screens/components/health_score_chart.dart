import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../models/health_score_data.dart';

/// Chart component for displaying health score trends over time
class HealthScoreChart extends StatefulWidget {
  final List<HealthScoreHistory> data;
  final double height;
  final bool showLegend;
  final bool showTooltips;
  final String? title;

  const HealthScoreChart({
    Key? key,
    required this.data,
    this.height = 250,
    this.showLegend = true,
    this.showTooltips = true,
    this.title,
  }) : super(key: key);

  @override
  State<HealthScoreChart> createState() => _HealthScoreChartState();
}

class _HealthScoreChartState extends State<HealthScoreChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LineChart(
            _buildChartData(),
            swapAnimationDuration: const Duration(milliseconds: 300),
            swapAnimationCurve: Curves.easeInOut,
          ),
        ),
        if (widget.showLegend) ...[
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ],
    );
  }

  LineChartData _buildChartData() {
    final sortedData = List<HealthScoreHistory>.from(widget.data)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final spots = sortedData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      
      return FlSpot(index.toDouble(), data.overallScore.toDouble());
    }).toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 20,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey[300]!,
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey[300]!,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() < 0 || value.toInt() >= sortedData.length) {
                return const Text('');
              }
              
              final data = sortedData[value.toInt()];
              return Text(
                DateFormat('MM/dd').format(data.timestamp),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      minX: 0,
      maxX: (sortedData.length - 1).toDouble(),
      minY: 0,
      maxY: 100,
      lineTouchData: LineTouchData(
        enabled: widget.showTooltips,
        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
          setState(() {
            if (touchResponse != null && touchResponse.lineBarSpots != null) {
              _touchedIndex = touchResponse.lineBarSpots!.first.spotIndex;
            } else {
              _touchedIndex = -1;
            }
          });
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => Colors.white,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              final data = sortedData[touchedSpot.spotIndex];
              return LineTooltipItem(
                '${data.timestamp.day}/${data.timestamp.month}\nScore: ${data.overallScore}',
                const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        // Overall Score Line
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: _touchedIndex == index ? Colors.blue : Colors.white,
                strokeColor: Colors.blue,
                strokeWidth: 2,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.withOpacity(0.3),
                Colors.blue.withOpacity(0.05),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.blue, 'Overall Score'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey[300]!,
          style: BorderStyle.none,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No health score data available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your health score history will appear here',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Multi-score chart for comparing different health score components
class MultiScoreChart extends StatefulWidget {
  final List<HealthScoreHistory> data;
  final double height;
  final bool showLegend;
  final bool showTooltips;

  const MultiScoreChart({
    Key? key,
    required this.data,
    this.height = 250,
    this.showLegend = true,
    this.showTooltips = true,
  }) : super(key: key);

  @override
  State<MultiScoreChart> createState() => _MultiScoreChartState();
}

class _MultiScoreChartState extends State<MultiScoreChart> {
  int _touchedIndex = -1;
  Set<int> _selectedScores = {0}; // Overall score selected by default

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LineChart(
            _buildMultiChartData(),
            swapAnimationDuration: const Duration(milliseconds: 300),
            swapAnimationCurve: Curves.easeInOut,
          ),
        ),
        if (widget.showLegend) ...[
          const SizedBox(height: 16),
          _buildMultiLegend(),
        ],
      ],
    );
  }

  LineChartData _buildMultiChartData() {
    final sortedData = List<HealthScoreHistory>.from(widget.data)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final spots = {
      0: sortedData.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value.overallScore.toDouble());
      }).toList(),
      1: sortedData.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value.respiratoryScore.toDouble());
      }).toList(),
      2: sortedData.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value.cardiovascularScore.toDouble());
      }).toList(),
      3: sortedData.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value.immuneScore.toDouble());
      }).toList(),
      4: sortedData.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value.activityImpactScore.toDouble());
      }).toList(),
    };

    final lineBarsData = <LineChartBarData>[];
    
    spots.forEach((scoreType, dataSpots) {
      if (_selectedScores.contains(scoreType)) {
        lineBarsData.add(
          LineChartBarData(
            spots: dataSpots,
            isCurved: _isCurved(scoreType),
            color: _getScoreColor(scoreType),
            barWidth: scoreType == 0 ? 3 : 2, // Thicker line for overall score
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: scoreType == 0 ? 5 : 3,
                  color: _touchedIndex == index ? _getScoreColor(scoreType) : Colors.white,
                  strokeColor: _getScoreColor(scoreType),
                  strokeWidth: 2,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: scoreType == 0, // Only show area for overall score
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _getScoreColor(scoreType).withOpacity(0.3),
                  _getScoreColor(scoreType).withOpacity(0.05),
                ],
              ),
            ),
          ),
        );
      }
    });

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 20,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey[300]!,
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey[300]!,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() < 0 || value.toInt() >= sortedData.length) {
                return const Text('');
              }
              
              final data = sortedData[value.toInt()];
              return Text(
                DateFormat('MM/dd').format(data.timestamp),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      minX: 0,
      maxX: (sortedData.length - 1).toDouble(),
      minY: 0,
      maxY: 100,
      lineTouchData: LineTouchData(
        enabled: widget.showTooltips,
        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
          setState(() {
            if (touchResponse != null && touchResponse.lineBarSpots != null) {
              _touchedIndex = touchResponse.lineBarSpots!.first.spotIndex;
            } else {
              _touchedIndex = -1;
            }
          });
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => Colors.white,
          getTooltipItems: (touchedSpots) {
            if (touchedSpots.isEmpty) return [];
            
            final data = sortedData[touchedSpots.first.spotIndex];
            return touchedSpots.map((LineBarSpot touchedSpot) {
              final scoreType = touchedSpot.barIndex;
              return LineTooltipItem(
                '${DateFormat('MM/dd HH:mm').format(data.timestamp)}\n${_getScoreLabel(scoreType)}: ${touchedSpot.y.toInt()}',
                TextStyle(
                  color: _getScoreColor(scoreType),
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: lineBarsData,
    );
  }

  Widget _buildMultiLegend() {
    const scoreTypes = [
      'Overall',
      'Respiratory',
      'Cardiovascular',
      'Immune',
      'Activity',
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: List.generate(scoreTypes.length, (index) {
        final isSelected = _selectedScores.contains(index);
        final color = _getScoreColor(index);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedScores.remove(index);
                if (_selectedScores.isEmpty) {
                  _selectedScores.add(index); // Always keep at least one selected
                }
              } else {
                _selectedScores.add(index);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : null,
              border: Border.all(
                color: color,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 3,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  scoreTypes[index],
                  style: TextStyle(
                    color: isSelected ? color : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Color _getScoreColor(int scoreType) {
    switch (scoreType) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getScoreLabel(int scoreType) {
    switch (scoreType) {
      case 0:
        return 'Overall Score';
      case 1:
        return 'Respiratory Score';
      case 2:
        return 'Cardiovascular Score';
      case 3:
        return 'Immune Score';
      case 4:
        return 'Activity Impact Score';
      default:
        return 'Unknown';
    }
  }

  bool _isCurved(int scoreType) {
    return scoreType == 0; // Only curve the overall score line
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey[300]!,
          style: BorderStyle.none,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.multiline_chart,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No multi-score data available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Compare different health score components over time',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}