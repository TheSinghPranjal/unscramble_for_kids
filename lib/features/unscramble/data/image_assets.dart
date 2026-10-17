import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/word_bank.dart';
import 'word_repository.dart';

enum ImageStatus {
  /// Final artwork is bundled.
  ok,

  /// A generated clay placeholder is bundled (replace with real art).
  placeholder,

  /// No file at the JSON path.
  missing,
}

/// Every asset key Flutter bundled into the app.
final assetKeysProvider = FutureProvider<Set<String>>((ref) async {
  final manifest = await AssetManifest.loadFromAssetBundle(
    ref.watch(assetBundleProvider),
  );
  return manifest.listAssets().toSet();
});

final imageInspectorProvider = Provider<ImageInspector>(
  (ref) => ImageInspector(ref.watch(assetBundleProvider)),
);

final imageStatusProvider = FutureProvider.family<ImageStatus, String>((
  ref,
  path,
) async {
  final keys = await ref.watch(assetKeysProvider.future);
  return ref.watch(imageInspectorProvider).statusOf(path, keys);
});

/// Status of every word image, keyed by asset path (Settings library).
final imageAuditProvider = FutureProvider<Map<String, ImageStatus>>((
  ref,
) async {
  final bank = await ref.watch(wordBankProvider.future);
  final keys = await ref.watch(assetKeysProvider.future);
  final inspector = ref.watch(imageInspectorProvider);
  return {
    for (final w in bank.words)
      w.imagePath: await inspector.statusOf(w.imagePath, keys),
  };
});

/// Detects the `unscramble-placeholder` PNG text chunk written by
/// `tool/generate_placeholders.py`. Real art never carries it, so dropping a
/// final image in with the same filename flips the status to [ImageStatus.ok].
class ImageInspector {
  ImageInspector(this._bundle);

  static const marker = 'unscramble-placeholder';

  final AssetBundle _bundle;
  final _cache = <String, bool>{};

  Future<ImageStatus> statusOf(String path, Set<String> bundled) async {
    if (!bundled.contains(path)) {
      debugPrint('[images] missing picture: $path');
      return ImageStatus.missing;
    }
    return await isPlaceholder(path) ? ImageStatus.placeholder : ImageStatus.ok;
  }

  Future<bool> isPlaceholder(String path) async {
    final cached = _cache[path];
    if (cached != null) return cached;
    try {
      final data = await _bundle.load(path);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes > 8192 ? 8192 : data.lengthInBytes,
      );
      return _cache[path] = latin1
          .decode(bytes, allowInvalid: true)
          .contains(marker);
    } catch (_) {
      return _cache[path] = false;
    }
  }
}

/// Paths in [bank] that are not bundled.
List<String> missingImages(WordBank bank, Set<String> bundled) => [
  for (final w in bank.words)
    if (!bundled.contains(w.imagePath)) w.imagePath,
];
