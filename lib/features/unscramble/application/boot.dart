import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/image_assets.dart';
import '../data/word_repository.dart';
import '../domain/word_bank.dart';

@immutable
class BootData {
  const BootData({
    required this.bank,
    required this.issues,
    required this.missingImages,
  });

  final WordBank bank;
  final List<String> issues;
  final List<String> missingImages;
}

/// Splash work: load words.json, validate the 100/100/100 deck + category
/// coverage, and check every JSON image path is bundled.
///
/// Debug builds assert on problems so mapping mistakes surface immediately;
/// release builds log and fall back to the "missing picture" clay tile.
final bootProvider = FutureProvider<BootData>((ref) async {
  final bank = await ref.watch(wordBankProvider.future);
  final keys = await ref.watch(assetKeysProvider.future);
  final issues = bank.validate();
  final missing = missingImages(bank, keys);

  for (final issue in issues) {
    debugPrint('[words] $issue');
  }
  for (final path in missing) {
    debugPrint('[images] missing picture: $path');
  }
  assert(issues.isEmpty, 'words.json failed validation:\n${issues.join('\n')}');
  assert(
    missing.isEmpty,
    '${missing.length} word images are missing:\n${missing.join('\n')}\n'
    'Run `python3 tool/generate_placeholders.py` to create placeholders.',
  );
  return BootData(bank: bank, issues: issues, missingImages: missing);
});
