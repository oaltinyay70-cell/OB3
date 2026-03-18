import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../utils/constants.dart';

abstract class Card extends Equatable {
  final String cardId;
  final String description;
  final DateTime timestamp;
  final Uint8List? imageData;
  final String? imageUrl;

  Card({
    required this.cardId, 
    required this.description, 
    this.imageData,
    this.imageUrl,
  }) : timestamp = DateTime.now();

  @override
  List<Object?> get props => [cardId];

  Map<String, dynamic> toJson();
}

class TargetCard extends Card {
  final TargetCardType targetType;
  final int vpValue;
  final String? specialRules;
  TargetCard({
    required super.cardId,
    required this.targetType,
    required this.vpValue,
    required super.description,
    this.specialRules,
    super.imageUrl,
    super.imageData,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    targetType,
    vpValue,
    specialRules,
    imageUrl,
  ];

  @override
  Map<String, dynamic> toJson() => {
    'cardId': cardId,
    'targetType': targetType.name,
    'vpValue': vpValue,
    'description': description,
    'specialRules': specialRules,
    'imageUrl': imageUrl,
    'imageData': imageData,
  };

  factory TargetCard.fromJson(Map<String, dynamic> json) => TargetCard(
    cardId: json['cardId'] as String,
    targetType: TargetCardType.values.byName(json['targetType'] as String),
    vpValue: json['vpValue'] as int,
    description: json['description'] as String,
    specialRules: json['specialRules'] as String?,
    imageUrl: json['imageUrl'] as String?,
    imageData: json['imageData'] as Uint8List?,
  );
}

class ThreatCard extends Card {
  final ThreatCardType threatType;
  final int drmModifier;

  /// Missile damage weight for SAM counter-attacks (US-6.2).
  /// Missiles ignore drone armor. Typical value: 3-4 for SAM, 0 for others.
  final int missileWeight;

  final String? specialRules;

  /// Altitude restriction for this threat (e.g. "LOW", "LOW,MEDIUM").
  /// Null means threat fires at any altitude.
  final String? altitudeRestriction;

  /// Display name for the threat card.
  final String? cardName;

  ThreatCard({
    required super.cardId,
    required this.threatType,
    required this.drmModifier,
    required super.description,
    this.missileWeight = 0,
    this.specialRules,
    super.imageUrl,
    this.altitudeRestriction,
    this.cardName,
    super.imageData,
  });

  /// Returns true if this threat is active at the given [droneAltitude].
  /// NULL altitude means threat fires at ANY altitude.
  bool isActiveAt(String droneAltitude) {
    if (cardId.startsWith('THCAP')) return true;
    if (altitudeRestriction == null || altitudeRestriction!.isEmpty) return true;
    final altitudes = altitudeRestriction!.toUpperCase().split(',').map((s) => s.trim()).toList();
    return altitudes.contains(droneAltitude.toUpperCase());
  }

  @override
  List<Object?> get props => [
    ...super.props,
    threatType,
    drmModifier,
    missileWeight,
    specialRules,
    imageUrl,
    altitudeRestriction,
    cardName,
  ];

  @override
  Map<String, dynamic> toJson() => {
    'cardId': cardId,
    'threatType': threatType.name,
    'drmModifier': drmModifier,
    'missileWeight': missileWeight,
    'description': description,
    'specialRules': specialRules,
    'imageUrl': imageUrl,
    'altitudeRestriction': altitudeRestriction,
    'cardName': cardName,
    'imageData': imageData,
  };

  factory ThreatCard.fromJson(Map<String, dynamic> json) => ThreatCard(
    cardId: json['cardId'] as String,
    threatType: ThreatCardType.values.byName(json['threatType'] as String),
    drmModifier: json['drmModifier'] as int,
    missileWeight: json['missileWeight'] as int? ?? 0,
    description: json['description'] as String,
    specialRules: json['specialRules'] as String?,
    imageUrl: json['imageUrl'] as String?,
    altitudeRestriction: json['altitudeRestriction'] as String?,
    cardName: json['cardName'] as String?,
    imageData: json['imageData'] as Uint8List?,
  );
}


/// Per BA spec §Step 1: combat cards can modify exactly 4 mechanics.
/// Null means no modification to that mechanic.
class CombatCard extends Card {
  final String? effect;
  final String? specialRulesOverride;
  final bool isNoEvent;

  // ── Structured modifiers (BA spec §Step 1) ──────────────────────────────
  /// Additive DRM on hit probability for this cycle (e.g. +1, -2).
  final int? hitProbabilityDRM;

  /// Additive DRM on evasion probability for this cycle.
  final int? evasionDRM;

  /// Multiplicative modifier on damage received this cycle (e.g. 1.5 = 50% more damage).
  final double? damageMultiplier;

  /// Multiplicative modifier on fuel consumption this cycle (e.g. 2.0 = double fuel).
  final double? fuelRateMultiplier;

  CombatCard({
    required super.cardId,
    required super.description,
    this.effect,
    this.specialRulesOverride,
    this.isNoEvent = false,
    super.imageUrl,
    super.imageData,
    this.hitProbabilityDRM,
    this.evasionDRM,
    this.damageMultiplier,
    this.fuelRateMultiplier,
  });

  /// True if this card has any active mechanical modifier.
  bool get hasModifier =>
      hitProbabilityDRM != null ||
      evasionDRM != null ||
      damageMultiplier != null ||
      fuelRateMultiplier != null;

  @override
  List<Object?> get props => [
    ...super.props,
    effect,
    specialRulesOverride,
    isNoEvent,
    imageUrl,
    hitProbabilityDRM,
    evasionDRM,
    damageMultiplier,
    fuelRateMultiplier,
  ];

  @override
  Map<String, dynamic> toJson() => {
    'cardId': cardId,
    'description': description,
    'effect': effect,
    'specialRulesOverride': specialRulesOverride,
    'isNoEvent': isNoEvent,
    'imageUrl': imageUrl,
    'imageData': imageData,
    'hitProbabilityDRM': hitProbabilityDRM,
    'evasionDRM': evasionDRM,
    'damageMultiplier': damageMultiplier,
    'fuelRateMultiplier': fuelRateMultiplier,
  };

  factory CombatCard.fromJson(Map<String, dynamic> json) => CombatCard(
    cardId: json['cardId'] as String,
    description: json['description'] as String,
    effect: json['effect'] as String?,
    specialRulesOverride: json['specialRulesOverride'] as String?,
    isNoEvent: json['isNoEvent'] as bool? ?? false,
    imageUrl: json['imageUrl'] as String?,
    imageData: json['imageData'] as Uint8List?,
    hitProbabilityDRM: json['hitProbabilityDRM'] as int?,
    evasionDRM: json['evasionDRM'] as int?,
    damageMultiplier: (json['damageMultiplier'] as num?)?.toDouble(),
    fuelRateMultiplier: (json['fuelRateMultiplier'] as num?)?.toDouble(),
  );
}
