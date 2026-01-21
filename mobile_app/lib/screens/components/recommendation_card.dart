import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../models/health_score_data.dart';

/// Card component for displaying health recommendations
class RecommendationCard extends StatefulWidget {
  final HealthRecommendation recommendation;
  final bool showPriority;
  final bool showCategory;
  final Function(String)? onDismiss;
  final Function(String)? onComplete;
  final Function(String)? onTap;

  const RecommendationCard({
    Key? key,
    required this.recommendation,
    this.showPriority = false,
    this.showCategory = false,
    this.onDismiss,
    this.onComplete,
    this.onTap,
  }) : super(key: key);

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(widget.recommendation.priority);
    final typeIcon = _getTypeIcon(widget.recommendation.type);
    final isUrgent = widget.recommendation.isUrgent || widget.recommendation.priority == 'Critical';

    return Card(
      elevation: _isExpanded ? 8 : 4,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
          if (_isExpanded) {
            _expandController.forward();
          } else {
            _expandController.reverse();
          }
          widget.onTap?.call(widget.recommendation.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(priorityColor, typeIcon, isUrgent),
              const SizedBox(height: 12),
              Text(
                widget.recommendation.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _isExpanded ? priorityColor : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.recommendation.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: _isExpanded ? null : 2,
                overflow: _isExpanded ? null : TextOverflow.ellipsis,
              ),
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildActionsList(),
                    const SizedBox(height: 12),
                    _buildMetadata(),
                    const SizedBox(height: 8),
                    _buildActionButtons(),
                  ],
                ),
              ),
              if (!_isExpanded) ...[
                const SizedBox(height: 8),
                Center(
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color priorityColor, IconData typeIcon, bool isUrgent) {
    return Row(
      children: [
        if (isUrgent) ...[
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.notification_important,
              color: Colors.red,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Icon(
          typeIcon,
          color: priorityColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.recommendation.type,
                style: TextStyle(
                  color: priorityColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              if (widget.showPriority) ...[
                const SizedBox(height: 2),
                Text(
                  widget.recommendation.priority,
                  style: TextStyle(
                    color: priorityColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (widget.showCategory) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.recommendation.category,
              style: TextStyle(
                color: priorityColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Actions:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.recommendation.actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          final isCompleted = action.toLowerCase().contains('completed');
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 16,
                  color: isCompleted ? Colors.green : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    action,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? Colors.grey[600] : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMetadata() {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                'Recommendation Details',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Created:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _formatDateTime(widget.recommendation.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Type:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      widget.recommendation.type,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (widget.onDismiss != null)
          TextButton.icon(
            onPressed: () => widget.onDismiss?.call(widget.recommendation.id),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Dismiss'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
          ),
        if (widget.onComplete != null)
          ElevatedButton.icon(
            onPressed: () => widget.onComplete?.call(widget.recommendation.id),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Mark Complete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'medical':
        return Icons.medical_services;
      case 'respiratory':
        return Icons.air;
      case 'activity':
        return Icons.directions_run;
      case 'indoor':
        return Icons.home;
      case 'outdoor':
        return Icons.nature;
      case 'lifestyle':
        return Icons.lifestyle;
      default:
        return Icons.lightbulb;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Compact recommendation card for lists
class CompactRecommendationCard extends StatelessWidget {
  final HealthRecommendation recommendation;
  final Function(String)? onTap;
  final Function(String)? onAction;

  const CompactRecommendationCard({
    Key? key,
    required this.recommendation,
    this.onTap,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(recommendation.priority);
    final typeIcon = _getTypeIcon(recommendation.type);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => onTap?.call(recommendation.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                typeIcon,
                color: priorityColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recommendation.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  recommendation.priority,
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onAction != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => onAction?.call(recommendation.id),
                  icon: const Icon(Icons.more_vert, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'medical':
        return Icons.medical_services;
      case 'respiratory':
        return Icons.air;
      case 'activity':
        return Icons.directions_run;
      case 'indoor':
        return Icons.home;
      case 'outdoor':
        return Icons.nature;
      case 'lifestyle':
        return Icons.lifestyle;
      default:
        return Icons.lightbulb;
    }
  }
}

/// Urgent recommendation banner
class UrgentRecommendationBanner extends StatelessWidget {
  final List<HealthRecommendation> recommendations;
  final Function(String)? onAction;
  final Function()? onDismiss;

  const UrgentRecommendationBanner({
    Key? key,
    required this.recommendations,
    this.onAction,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notification_important,
                  color: Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Urgent Health Recommendation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...recommendations.take(2).map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rec.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )),
            if (recommendations.length > 2) ...[
              Text(
                '+${recommendations.length - 2} more urgent recommendations',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Navigate to recommendations screen
                  },
                  child: const Text('View All'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (onAction != null) {
                      onAction!.call(recommendations.first.id);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Take Action'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}