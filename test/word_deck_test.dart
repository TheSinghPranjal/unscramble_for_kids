import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:unscramble_for_kids/features/unscramble/application/word_deck.dart';
import 'package:unscramble_for_kids/features/unscramble/domain/word_entry.dart';

import 'helpers.dart';

void main() {
  final bank = loadRealBank();

  test('deals every word once per pass', () {
    final words = bank.wordsFor(length: 3, category: 'Animals');
    final deck = WordDeck(words, random: Random(1));
    final dealt = [for (var i = 0; i < words.length; i++) deck.next()];
    expect(dealt.toSet(), words.toSet());
    expect(deck.passes, 1);
  });

  test('reshuffles after exhaustion without an immediate repeat', () {
    final words = bank.wordsFor(length: 4, category: 'Toys');
    for (var seed = 0; seed < 50; seed++) {
      final deck = WordDeck(words, random: Random(seed));
      WordEntry? last;
      for (var i = 0; i < words.length * 3; i++) {
        final w = deck.next();
        expect(w, isNot(equals(last)), reason: 'seed $seed, deal $i');
        last = w;
      }
      expect(deck.passes, 3);
    }
  });

  test('single-word deck keeps dealing that word', () {
    final deck = WordDeck([word('CAT', 'Animals')]);
    expect(deck.next().word, 'CAT');
    expect(deck.next().word, 'CAT');
  });

  test('easyFirst orders each pass easy → medium → hard', () {
    final words = bank.wordsFor(length: 5);
    final deck = WordDeck(words, random: Random(3), easyFirst: true);
    final pass = [for (var i = 0; i < words.length; i++) deck.next()];
    final levels = pass.map((w) => w.difficulty.index).toList();
    expect(levels, [...levels]..sort());
  });

  test('empty deck throws instead of dealing nothing', () {
    expect(() => WordDeck(const []).next(), throwsStateError);
  });

  test('scramble never shows the answer (when it can differ)', () {
    final rnd = Random(9);
    for (final w in bank.words) {
      for (var i = 0; i < 5; i++) {
        final letters = scrambleLetters(w.word, rnd);
        expect(letters.join(), isNot(w.word));
        expect([...letters]..sort(), [...w.word.split('')]..sort());
      }
    }
  });
}
