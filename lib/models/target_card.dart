import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'game_enums.dart';

/// Target card loaded from the database.
class TargetCard extends Equatable {
  const TargetCard({
    required this.cardNumber,
    required this.cardType,
    required this.subCategory,
    required this.targetType,
    required this.cardName,
    required this.vp,
    this.instruction,
    this.altitudeRestriction,
    this.weaponType,
    this.imageBytes,
  });

  final String cardNumber;
  final String cardType;
  final String subCategory;
  final TargetType targetType;
  final String cardName;
  final double vp;
  final String? instruction;
  final String? altitudeRestriction;
  final String? weaponType;
  final Uint8List? imageBytes;

  /// Asset path for the UX-designed card visual.
  String get imagePath => 'assets/images/cards/targets/$cardNumber.png';

  /// Whether this target has an altitude restriction.
  bool get hasAltitudeRestriction =>
      altitudeRestriction != null && altitudeRestriction!.isNotEmpty;

  /// Allowed attack altitudes (empty = all allowed).
  List<Altitude> get allowedAltitudes =>
      hasAltitudeRestriction
          ? Altitude.parseFromDb(altitudeRestriction)
          : Altitude.values.toList();

  factory TargetCard.fromMap(Map<String, dynamic> map) {
    final subCat = map['sub_category'] as String? ?? 'TRUCK';
    return TargetCard(
      cardNumber: map['card_number'] as String,
      cardType: map['card_type'] as String? ?? 'Target Card',
      subCategory: subCat,
      targetType: TargetType.fromDb(subCat),
      cardName: map['card_name'] as String,
      vp: (map['vp'] as num?)?.toDouble() ?? 0.0,
      instruction: (map['instructions'] as String?) ??
          (map['instruction'] as String?),
      altitudeRestriction: map['altitude_restriction'] as String?,
      weaponType: map['weapon_type'] as String?,
      imageBytes: map['image'] as Uint8List?,
    );
  }

  @override
  List<Object?> get props => [cardNumber];
}
