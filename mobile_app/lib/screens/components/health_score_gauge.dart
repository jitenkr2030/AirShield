import 'package:flutter/material.dart';
import 'package:syncusion_flutter_gauges/syncusion_flutter_gauges.dart';

/// Custom gauge component for displaying health score
/// Supports multiple styles and animations
class HealthScoreGauge extends StatefulWidget {
  final int score; // 0-100
  final double size;
  final bool showLabels;
  final bool showTicks;
  final String? title;
  final String? subtitle;
  final Color? color;
  final bool animated;

  const HealthScoreGauge({
    Key? key,
    required this.score,
    this.size = 150,
    this.showLabels = true,
    this.showTicks = true,
    this.title,
    this.subtitle,
    this.color,
    this.animated = true,
  }) : super(key: key);

  @override
  State<HealthScoreGauge> createState() => _HealthScoreGaugeState();
}

class _HealthScoreGaugeState extends State<HealthScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scoreAnimation;
  int _animatedScore = 0;

  @override
  void initState() {
    super.initState();
    
    if (widget.animated) {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );
      
      _scoreAnimation = Tween<double>(
        begin: 0.0,
        end: widget.score.toDouble(),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ));

      _animationController.addListener(() {
        setState(() {
          _animatedScore = _scoreAnimation.value.round();
        });
      });

      _animationController.forward();
    } else {
      _animatedScore = widget.score;
    }
  }

  @override
  void dispose() {
    if (widget.animated) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(HealthScoreGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.animated && oldWidget.score != widget.score) {
      _animationController.reset();
      _scoreAnimation = Tween<double>(
        begin: _animatedScore.toDouble(),
        end: widget.score.toDouble(),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ));
      
      _animationController.forward();
    } else if (!widget.animated) {
      _animatedScore = widget.score;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gaugeColor = widget.color ?? _getScoreColor(widget.score);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: widget.size,
          width: widget.size,
          child: SfRadialGauge(
            axes: <RadialAxis>[
              RadialAxis(
                minimum: 0,
                maximum: 100,
                startAngle: 180,
                endAngle: 0,
                showLabels: widget.showLabels,
                showTicks: widget.showTicks,
                tickOffset: 10,
                labelOffset: 15,
                axisLabelStyle: const GaugeLabelStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                tickStyle: TickStyle(
                  thickness: 2,
                  color: Colors.grey[400]!,
                ),
                majorTickStyle: MajorTickStyle(
                  thickness: 3,
                  color: Colors.grey[600]!,
                ),
                minorTickStyle: MinorTickStyle(
                  thickness: 1,
                  color: Colors.grey[300]!,
                ),
                ranges: <GaugeRange>[
                  // Critical range (0-30) - Red
                  GaugeRange(
                    startValue: 0,
                    endValue: 30,
                    startWidth: 20,
                    endWidth: 20,
                    color: Colors.red.shade400,
                    gradient: SweepGradient(
                      colors: [
                        Colors.red.shade300,
                        Colors.red.shade600,
                      ],
                    ),
                  ),
                  
                  // Poor range (30-50) - Orange
                  GaugeRange(
                    startValue: 30,
                    endValue: 50,
                    startWidth: 20,
                    endWidth: 20,
                    color: Colors.orange.shade400,
                    gradient: SweepGradient(
                      colors: [
                        Colors.orange.shade300,
                        Colors.orange.shade600,
                      ],
                    ),
                  ),
                  
                  // Fair range (50-65) - Yellow
                  GaugeRange(
                    startValue: 50,
                    endValue: 65,
                    startWidth: 20,
                    endWidth: 20,
                    color: Colors.amber.shade400,
                    gradient: SweepGradient(
                      colors: [
                        Colors.amber.shade300,
                        Colors.amber.shade600,
                      ],
                    ),
                  ),
                  
                  // Good range (65-80) - Light Green
                  GaugeRange(
                    startValue: 65,
                    endValue: 80,
                    startWidth: 20,
                    endWidth: 20,
                    color: Colors.lightGreen.shade400,
                    gradient: SweepGradient(
                      colors: [
                        Colors.lightGreen.shade300,
                        Colors.lightGreen.shade600,
                      ],
                    ),
                  ),
                  
                  // Excellent range (80-100) - Green
                  GaugeRange(
                    startValue: 80,
                    endValue: 100,
                    startWidth: 20,
                    endWidth: 20,
                    color: Colors.green.shade400,
                    gradient: SweepGradient(
                      colors: [
                        Colors.green.shade300,
                        Colors.green.shade600,
                      ],
                    ),
                  ),
                ],
                pointers: <GaugePointer>[
                  NeedlePointer(
                    value: _animatedScore.toDouble(),
                    enableAnimation: widget.animated,
                    animationDuration: 1500,
                    animationType: AnimationType.elasticOut,
                    needleColor: gaugeColor,
                    needleWidth: 4,
                    knobStyle: KnobStyle(
                      color: gaugeColor,
                      knobRadius: 8,
                      borderWidth: 2,
                      borderColor: Colors.white,
                    ),
                  ),
                ],
                annotations: <GaugeAnnotation>[
                  GaugeAnnotation(
                    angle: 90,
                    positionFactor: 0.8,
                    widget: Container(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_animatedScore',
                            style: TextStyle(
                              fontSize: widget.size * 0.15,
                              fontWeight: FontWeight.bold,
                              color: gaugeColor,
                            ),
                          ),
                          Text(
                            '/ 100',
                            style: TextStyle(
                              fontSize: widget.size * 0.08,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

/// Compact circular gauge for smaller spaces
class CompactHealthScoreGauge extends StatelessWidget {
  final int score;
  final double size;
  final bool showLabel;

  const CompactHealthScoreGauge({
    Key? key,
    required this.score,
    this.size = 80,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 6,
            ),
            color: color.withOpacity(0.1),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: size * 0.25,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (showLabel) ...[
                  const SizedBox(height: 2),
                  Text(
                    '/100',
                    style: TextStyle(
                      fontSize: size * 0.12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            _getScoreLabel(score),
            style: TextStyle(
              fontSize: size * 0.12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

/// Linear gauge for horizontal layout
class LinearHealthScoreGauge extends StatelessWidget {
  final int score;
  final double width;
  final double height;
  final bool showLabels;

  const LinearHealthScoreGauge({
    Key? key,
    required this.score,
    this.width = 200,
    this.height = 40,
    this.showLabels = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height / 2),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.red,
                    Colors.orange,
                    Colors.amber,
                    Colors.lightGreen,
                    Colors.green,
                  ],
                ),
              ),
            ),
            Positioned(
              right: 0,
              child: Container(
                width: width * (1 - score / 100),
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  color: Colors.white,
                ),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Text(
                  '$score',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: height * 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showLabels) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '50',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '100',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
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
}