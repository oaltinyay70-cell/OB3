/// Sprint 10 (Epic 6): Medal system models.
library;

class Medal {
  final String id;
  final String name;
  final String description;
  final String nationality; // Only players of this nationality can earn it
  final String criteriaType; // 'vp', 'kills', 'scenario_complete', 'campaign_complete'
  final int criteriaValue;   // Threshold value
  final String iconAsset;

  const Medal({
    required this.id,
    required this.name,
    required this.description,
    required this.nationality,
    required this.criteriaType,
    required this.criteriaValue,
    this.iconAsset = 'assets/images/medal_default.png',
  });

  factory Medal.fromRow(Map<String, dynamic> row) => Medal(
    id: row['id']?.toString() ?? '',
    name: row['name'] as String? ?? 'Unknown Medal',
    description: row['description'] as String? ?? '',
    nationality: row['nationality'] as String? ?? 'Any',
    criteriaType: row['criteria_type'] as String? ?? 'vp',
    criteriaValue: row['criteria_value'] as int? ?? 0,
    iconAsset: row['icon_asset'] as String? ?? 'assets/images/medal_default.png',
  );
}

class EarnedMedal {
  final String medalId;
  final String medalName;
  final DateTime earnedAt;

  const EarnedMedal({
    required this.medalId,
    required this.medalName,
    required this.earnedAt,
  });

  Map<String, dynamic> toJson() => {
    'medalId': medalId,
    'medalName': medalName,
    'earnedAt': earnedAt.toIso8601String(),
  };

  factory EarnedMedal.fromJson(Map<String, dynamic> json) => EarnedMedal(
    medalId: json['medalId'] as String,
    medalName: json['medalName'] as String? ?? 'Unknown',
    earnedAt: DateTime.parse(json['earnedAt'] as String),
  );
}
