import 'dart:math';

/// Generic card deck manager supporting shuffle, draw, discard, and reshuffle.
///
/// Type [T] is the card type (CombatCard, TargetCard, ThreatCard).
class DeckManager<T> {
  DeckManager({
    required List<T> cards,
    Random? random,
  })  : _drawPile = List<T>.from(cards),
        _discardPile = <T>[],
        _destroyedPile = <T>[],
        _random = random ?? Random() {
    shuffle();
  }

  final List<T> _drawPile;
  final List<T> _discardPile;
  final List<T> _destroyedPile;
  final Random _random;

  /// Number of cards remaining in the draw pile.
  int get drawPileSize => _drawPile.length;

  /// Number of cards in the discard pile.
  int get discardPileSize => _discardPile.length;

  /// Number of cards in the destroyed pile.
  int get destroyedPileSize => _destroyedPile.length;

  /// Total cards in circulation (draw + discard, NOT destroyed).
  int get totalInPlay => _drawPile.length + _discardPile.length;

  /// Whether the deck is completely exhausted (draw + discard = 0).
  bool get isExhausted => _drawPile.isEmpty && _discardPile.isEmpty;

  /// All destroyed cards (e.g., destroyed targets for VP scoring).
  List<T> get destroyedCards => List.unmodifiable(_destroyedPile);

  /// Shuffle the draw pile.
  void shuffle() {
    _drawPile.shuffle(_random);
  }

  /// Draw the top card from the draw pile.
  ///
  /// If draw pile is empty, reshuffles the discard pile back in.
  /// Returns null if completely exhausted.
  T? draw() {
    if (_drawPile.isEmpty) {
      if (_discardPile.isEmpty) return null;
      reshuffleDiscards();
    }
    if (_drawPile.isEmpty) return null;
    return _drawPile.removeLast();
  }

  /// Discard a card to the discard pile.
  void discard(T card) {
    _discardPile.add(card);
  }

  /// Move a card to the destroyed pile (e.g., destroyed target).
  void destroy(T card) {
    _destroyedPile.add(card);
  }

  /// Reshuffle discards back into the draw pile.
  void reshuffleDiscards() {
    _drawPile.addAll(_discardPile);
    _discardPile.clear();
    shuffle();
  }

  /// Return all discards + draw pile, reshuffle everything.
  /// Used when threat cards need to be recycled.
  void recycleAll() {
    _drawPile.addAll(_discardPile);
    _discardPile.clear();
    shuffle();
  }
}
