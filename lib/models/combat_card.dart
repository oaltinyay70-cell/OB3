import 'dart:typed_data';
import 'package:equatable/equatable.dart';

/// Combat card loaded from the database.
/// Effects are interpreted by the CombatCardHandler engine component.
class CombatCard extends Equatable {
  const CombatCard({
    required this.cardNumber,
    required this.cardType,
    required this.cardName,
    required this.instruction,
    this.imageBytes,
  });

  final String cardNumber;
  final String cardType;
  final String cardName;
  final String instruction;
  final Uint8List? imageBytes;

  /// Asset path for the UX-designed card visual (e.g. "assets/images/cards/combat/CC001.png").
  /// Returns null if no matching asset exists.
  String get imagePath => 'assets/images/cards/combat/$cardNumber.png';

  /// Whether this card has no gameplay effect.
  bool get isNoEvent =>
      instruction.toUpperCase().contains('NO EVENT') ||
      cardName.toUpperCase().contains('NO EVENT');

  factory CombatCard.fromMap(Map<String, dynamic> map) {
    return CombatCard(
      cardNumber: map['card_number'] as String,
      cardType: map['card_type'] as String? ?? 'Combat Card',
      cardName: map['card_name'] as String,
      instruction: (map['instructions'] as String?) ??
          (map['instruction'] as String?) ??
          '',
      imageBytes: map['image'] as Uint8List?,
    );
  }

  @override
  List<Object?> get props => [cardNumber];
}
