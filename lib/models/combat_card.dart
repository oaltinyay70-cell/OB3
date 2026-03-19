import 'dart:typed_data';
import 'package:equatable/equatable.dart';

/// Combat card loaded from the database.
/// Card effects are interpreted by [CombatCardHandler].
/// Schema: id, card_number, card_type, card_name, instructions, attribute_effect, image
class CombatCard extends Equatable {
  const CombatCard({
    required this.cardNumber,
    required this.cardName,
    required this.instructions,
    this.attributeEffect,
    this.imageBytes,
  });

  final String cardNumber;
  final String cardName;
  final String instructions;

  /// JSON blob of structured gameplay effects (column shifts, DRM, altitude changes etc.)
  final String? attributeEffect;
  final Uint8List? imageBytes;

  /// Asset path for the card image (e.g. "assets/images/cards/combat/CC013.png").
  String get imagePath => 'assets/images/cards/combat/$cardNumber.png';

  /// Whether this card has no gameplay effect.
  bool get isNoEvent =>
      instructions.toUpperCase().contains('NO EVENT') ||
      cardName.toUpperCase().contains('NO EVENT');

  factory CombatCard.fromMap(Map<String, dynamic> map) {
    return CombatCard(
      cardNumber: map['card_number'] as String,
      cardName: map['card_name'] as String,
      instructions: (map['instructions'] as String?) ?? '',
      attributeEffect: map['attribute_effect'] as String?,
      imageBytes: map['image'] as Uint8List?,
    );
  }

  @override
  List<Object?> get props => [cardNumber];
}
