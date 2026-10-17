import 'dart:math';

import '../domain/word_entry.dart';

/// Deals every word once per pass, then reshuffles. Never deals the same
/// word twice in a row across a reshuffle (when the deck has > 1 word).
class WordDeck {
  WordDeck(List<WordEntry> words, {Random? random, this.easyFirst = false})
    : _words = List.unmodifiable(words),
      _random = random ?? Random();

  final List<WordEntry> _words;
  final Random _random;

  /// Order each pass easy → medium → hard (shuffled within a level).
  final bool easyFirst;

  final List<WordEntry> _queue = [];
  WordEntry? _last;
  int _passes = 0;

  bool get isEmpty => _words.isEmpty;
  int get size => _words.length;
  int get remainingInPass => _queue.length;
  int get passes => _passes;

  WordEntry next() {
    if (_words.isEmpty) throw StateError('Deck is empty');
    if (_queue.isEmpty) _refill();
    return _last = _queue.removeAt(0);
  }

  void _refill() {
    _passes++;
    final pass = [..._words]..shuffle(_random);
    if (easyFirst) {
      // List.sort is not stable, so sort on (difficulty, shuffled position).
      final order = {for (var i = 0; i < pass.length; i++) pass[i]: i};
      pass.sort((a, b) {
        final d = a.difficulty.index.compareTo(b.difficulty.index);
        return d != 0 ? d : order[a]!.compareTo(order[b]!);
      });
    }
    if (pass.length > 1 && pass.first == _last) {
      final swap = pass.indexWhere(
        (w) => w != _last && w.difficulty == pass.first.difficulty,
      );
      final j = swap > 0 ? swap : 1;
      final tmp = pass[0];
      pass[0] = pass[j];
      pass[j] = tmp;
    }
    _queue.addAll(pass);
  }
}

/// Shuffles letters so the tray never shows the answer already spelled out.
List<String> scrambleLetters(String word, Random random) {
  final letters = word.split('');
  if (letters.toSet().length < 2) return letters;
  for (var attempt = 0; attempt < 20; attempt++) {
    letters.shuffle(random);
    if (letters.join() != word) return letters;
  }
  // Fallback: rotate by one (always differs when ≥2 distinct letters).
  return [...word.substring(1).split(''), word[0]];
}
