import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'game_enums.dart';

/// Threat card loaded from the database.
class ThreatCard extends Equatable {
  const ThreatCard({
    required this.cardNumber,
    required this.cardType,
    required this.subCategory,
    required this.threatType,
    required this.cardName,
    this.instruction,
    this.altitudeRestriction,
    this.columnShiftDirection,
    this.columnShiftBy,
    this.imageBytes,
  });

  final String cardNumber;
  final String cardType;
  final String subCategory;
  final ThreatType threatType;
  final String cardName;
  final String? instruction;
  final String? altitudeRestriction;

  /// Direction of column shift in counterfire CRT (LEFT or RIGHT).
  final String? columnShiftDirection;

  /// Number of columns to shift.
  final int? columnShiftBy;
  final Uint8List? imageBytes;

  /// Asset path for the UX-designed card visual.
  String get imagePath => 'assets/images/cards/threats/$cardNumber.png';

  /// Whether this threat has altitude restriction.
  bool get hasAltitudeRestriction =>
      altitudeRestriction != null && altitudeRestriction!.isNotEmpty;

  /// Altitudes where this threat is active (empty = all).
  List<Altitude> get activeAltitudes =>
      hasAltitudeRestriction
          ? Altitude.parseFromDb(altitudeRestriction)
          : Altitude.values.toList();

  /// Whether this threat is a SAM (for SAM special counterfire rules).
  bool get isSam => threatType == ThreatType.sam;

  factory ThreatCard.fromMap(Map<String, dynamic> map) {
    final subCat = map['sub_category'] as String? ?? 'SMALL ARMS';
    return ThreatCard(
      cardNumber: map['card_number'] as String,
      cardType: map['card_type'] as String? ?? 'Threat Card',
      subCategory: subCat,
      threatType: ThreatType.fromDb(subCat),
      cardName: map['card_name'] as String,
      instruction: (map['instructions'] as String?) ??
          (map['instruction'] as String?),
      altitudeRestriction: map['altitude_restriction'] as String?,
      columnShiftDirection: map['column_shift'] as String?,
      columnShiftBy: map['cshift_by'] as int?,
      imageBytes: map['image'] as Uint8List?,
    );
  }

  @override
  List<Object?> get props => [cardNumber];
}
