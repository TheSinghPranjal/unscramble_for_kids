import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/word_bank.dart';

/// Bundle used for all asset reads; overridable in tests.
final assetBundleProvider = Provider<AssetBundle>((ref) => rootBundle);

final wordRepositoryProvider = Provider<WordRepository>(
  (ref) => WordRepository(ref.watch(assetBundleProvider)),
);

/// Loaded once at boot; the game and screens read it synchronously after.
final wordBankProvider = FutureProvider<WordBank>(
  (ref) => ref.watch(wordRepositoryProvider).load(),
);

class WordRepository {
  WordRepository(this._bundle);

  static const path = 'assets/words/words.json';

  final AssetBundle _bundle;

  Future<WordBank> load() async {
    final raw = await _bundle.loadString(path, cache: false);
    return WordBank.parse(raw);
  }
}
