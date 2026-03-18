import 'dart:math';

/// Dice rolling service with injectable Random for testability.
class DiceService {
  DiceService({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Roll a single D6 (returns 1-6).
  int rollD6() => _random.nextInt(6) + 1;

  /// Roll 2D10 for target/threat acquisition.
  ///
  /// First die = ones digit (0-9), second die = tens digit (0-9).
  /// Returns combined result 0-99.
  /// Example: first=2, second=5 → 52 ; first=0, second=9 → 90 ; first=2, second=0 → 02.
  TwoD10Result roll2D10() {
    final ones = _random.nextInt(10); // 0-9
    final tens = _random.nextInt(10); // 0-9
    return TwoD10Result(ones: ones, tens: tens);
  }
}

/// Result of rolling 2D10.
class TwoD10Result {
  const TwoD10Result({required this.ones, required this.tens});

  final int ones;
  final int tens;

  /// Combined value: tens*10 + ones. Range: 0-99.
  int get value => tens * 10 + ones;

  @override
  String toString() => 'TwoD10Result(ones=$ones, tens=$tens, value=$value)';
}
