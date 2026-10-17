import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unscramble_for_kids/features/unscramble/application/rewards_controller.dart';
import 'package:unscramble_for_kids/features/unscramble/application/unscramble_controller.dart';
import 'package:unscramble_for_kids/features/unscramble/data/word_repository.dart';
import 'package:unscramble_for_kids/features/unscramble/domain/game_state.dart';
import 'package:unscramble_for_kids/features/unscramble/domain/word_bank.dart';
import 'package:unscramble_for_kids/features/unscramble/domain/word_entry.dart';
import 'package:unscramble_for_kids/shared/prefs/prefs.dart';

WordBank loadRealBank() =>
    WordBank.parse(File('assets/words/words.json').readAsStringSync());

WordEntry word(String w, String category, {String hint = 'hint'}) => WordEntry(
  id: '${w.toLowerCase()}_${w.length}',
  word: w,
  category: category,
  hintText: hint,
  imagePath: WordEntry.expectedImagePath(w),
);

/// Small deterministic bank for gameplay mechanics.
WordBank smallBank(List<WordEntry> words) => WordBank(
  version: 2,
  categories: const ['Animals', 'Food', 'Toys'],
  words: words,
);

class TestClock {
  DateTime now = DateTime(2026, 10, 16, 9);
}

Future<SharedPreferences> mockPrefs([Map<String, Object> values = const {}]) {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

Future<ProviderContainer> makeContainer({
  WordBank? bank,
  SharedPreferences? prefs,
  TestClock? clock,
}) async {
  final p = prefs ?? await mockPrefs();
  final c = ProviderContainer.test(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(p),
      wordBankProvider.overrideWith((ref) async => bank ?? loadRealBank()),
      randomProvider.overrideWithValue(Random(42)),
      if (clock != null) clockProvider.overrideWithValue(() => clock.now),
    ],
  );
  await c.read(wordBankProvider.future);
  return c;
}

/// Taps the correct tray tile for every empty slot.
void solve(UnscrambleController ctrl, GameState Function() read) {
  while (read().isPlaying && read().nextEmptySlot != null) {
    final s = read();
    final want = s.entry!.word[s.nextEmptySlot!];
    ctrl.placeTile(s.trayTiles.firstWhere((t) => t.letter == want).id);
  }
}

/// Taps a tray tile that is wrong for the next empty slot.
void tapWrong(UnscrambleController ctrl, GameState s) {
  final want = s.entry!.word[s.nextEmptySlot!];
  ctrl.placeTile(s.trayTiles.firstWhere((t) => t.letter != want).id);
}
