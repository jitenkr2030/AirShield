import 'package:json_annotation/json_annotation.dart';

part 'health_score_data.g.dart';

@JsonSerializable()
class HealthScoreData {
  final String id;
  final String userId;
  final int overallScore; // 0-100 scale
  final int respiratoryScore; // Breathing health impact
  final int cardiovascularScore; // Heart health impact  
  final int immuneScore; // General immune system impact
  final int activityImpactScore; // Impact on daily activities
  final double riskLevel; // 0-1 scale where 1 = highest risk
  final String riskCategory; // Low, Medium, High, Critical
  final Map<String, dynamic> contributingFactors;
  final List<HealthRecommendation> recommendations;
  final DateTime timestamp;
  final DateTime expiresAt; // Score expires after this time

  const HealthScoreData({
    required this.id,
    required this.userId,
    required this.overallScore,
    required this.respiratoryScore,
    required this.cardiovascularScore,
    required this.immuneScore,
    required this.activityImpactScore,
    required this.riskLevel,
    required this.riskCategory,
    required this.contributingFactors,
    required this.recommendations,
    required this.timestamp,
    required this.expiresAt,
  });

  factory HealthScoreData.fromJson(Map<String, dynamic> json) =>
      _$HealthScoreDataFromJson(json);

  Map<String, dynamic> toJson() => _$HealthScoreDataToJson(this);

  HealthScoreData copyWith({
    String? id,
    String? userId,
    int? overallScore,
    int? respiratoryScore,
    int? cardiovascularScore,
    int? immuneScore,
    int? activityImpactScore,
    double? riskLevel,
    String? riskCategory,
    Map<String, dynamic>? contributingFactors,
    List<HealthRecommendation>? recommendations,
    DateTime? timestamp,
    DateTime? expiresAt,
  }) {
    return HealthScoreData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      overallScore: overallScore ?? this.overallScore,
      respiratoryScore: respiratoryScore ?? this.respiratoryScore,
      cardiovascularScore: cardiovascularScore ?? this.cardiovascularScore,
      immuneScore: immuneScore ?? this.immuneScore,
      activityImpactScore: activityImpactScore ?? this.activityImpactScore,
      riskLevel: riskLevel ?? this.riskLevel,
      riskCategory: riskCategory ?? this.riskCategory,
      contributingFactors: contributingFactors ?? this.contributingFactors,
      recommendations: recommendations ?? this.recommendations,
      timestamp: timestamp ?? this.timestamp,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  String get riskCategoryColor {
    switch (riskCategory.toLowerCase()) {
      case 'low':
        return '#28A745';
      case 'medium':
        return '#FFC107';
      case 'high':
        return '#FF9800';
      case 'critical':
        return '#DC3545';
      default:
        return '#6C757D';
    }
  }

  String get scoreDescription {
    if (overallScore >= 90) return 'Excellent health resilience';
    if (overallScore >= 75) return 'Good health protection';
    if (overallScore >= 60) return 'Moderate health concern';
    if (overallScore >= 40) return 'Health awareness needed';
    return 'Immediate health protection required';
  }

  List<HealthScoreHistory> get historicalData {
    // This would be populated from historical data
    return [];
  }

  @override
  String toString() {
    return 'HealthScoreData(id: $id, overallScore: $overallScore, riskCategory: $riskCategory, timestamp: $timestamp)';
  }
}

@JsonSerializable()
class HealthRecommendation {
  final String id;
  final String type; // Indoor, Outdoor, Activity, Medical
  final String priority; // Low, Medium, High, Critical
  final String title;
  final String description;
  final List<String> actions;
  final String category;
  final bool isUrgent;
  final DateTime createdAt;

  const HealthRecommendation({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.actions,
    required this.category,
    required this.isUrgent,
    required this.createdAt,
  });

  factory HealthRecommendation.fromJson(Map<String, dynamic> json) =>
      _$HealthRecommendationFromJson(json);

  Map<String, dynamic> toJson() => _$HealthRecommendationToJson(this);
}

@JsonSerializable()
class HealthScoreHistory {
  final DateTime timestamp;
  final int overallScore;
  final int respiratoryScore;
  final int cardiovascularScore;
  final int immuneScore;
  final int activityImpactScore;
  final String riskCategory;
  final Map<String, dynamic> environmentalFactors;

  const HealthScoreHistory({
    required this.timestamp,
    required this.overallScore,
    required this.respiratoryScore,
    required this.cardiovascularScore,
    required this.immuneScore,
    required this.activityImpactScore,
    required this.riskCategory,
    required this.environmentalFactors,
  });

  factory HealthScoreHistory.fromJson(Map<String, dynamic> json) =>
      _$HealthScoreHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$HealthScoreHistoryToJson(this);
}

enum RiskCategory {
  low,
  medium,
  high,
  critical,
}

extension RiskCategoryExtension on RiskCategory {
  String get displayName {
    switch (this) {
      case RiskCategory.low:
        return 'Low Risk';
      case RiskCategory.medium:
        return 'Medium Risk';
      case RiskCategory.high:
        return 'High Risk';
      case RiskCategory.critical:
        return 'Critical Risk';
    }
  }
  
  int get priority {
    switch (this) {
      case RiskCategory.low:
        return 1;
      case RiskCategory.medium:
        return 2;
      case RiskCategory.high:
        return 3;
      case RiskCategory.critical:
        return 4;
    }
  }
}

enum HealthScoreType {
  respiratory,
  cardiovascular,
  immune,
  activity,
  overall,
}