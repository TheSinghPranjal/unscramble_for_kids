import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/kids_palette.dart';
import '../../data/image_assets.dart';
import '../../domain/word_entry.dart';

/// The picture clue for a word, resolved from its JSON `image` path.
///
/// * final art → shown as-is
/// * generated placeholder → clay tile + the word's emoji on top
/// * missing file → friendly "picture coming soon" clay tile (never a crash)
class WordPicture extends ConsumerWidget {
  const WordPicture({
    super.key,
    required this.entry,
    required this.size,
    this.radius = 22,
  });

  final WordEntry entry;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(imageStatusProvider(entry.imagePath));
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2;
    final cache = (size * dpr).round();

    Widget image() => Image.asset(
      entry.imagePath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      cacheWidth: cache,
      gaplessPlayback: true,
      errorBuilder: (context, error, _) {
        debugPrint('[images] failed to load ${entry.imagePath}: $error');
        return MissingPicture(entry: entry, size: size);
      },
    );

    final child = switch (status) {
      AsyncData(value: ImageStatus.ok) => image(),
      AsyncData(value: ImageStatus.placeholder) => Stack(
        fit: StackFit.expand,
        children: [
          image(),
          Center(
            child: Text(
              entry.emoji ?? KidsColors.categoryEmoji[entry.category] ?? '❓',
              style: TextStyle(fontSize: size * 0.4, height: 1),
            ),
          ),
        ],
      ),
      AsyncData(value: ImageStatus.missing) ||
      AsyncError() => MissingPicture(entry: entry, size: size),
      _ => ColoredBox(
        color: KidsColors.forCategory(entry.category).withValues(alpha: 0.4),
      ),
    };

    return Semantics(
      image: true,
      label: entry.pictureLabel,
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(width: size, height: size, child: child),
        ),
      ),
    );
  }
}

class MissingPicture extends StatelessWidget {
  const MissingPicture({super.key, required this.entry, required this.size});

  final WordEntry entry;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = KidsColors.forCategory(entry.category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.55), color],
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.emoji ?? KidsColors.categoryEmoji[entry.category] ?? '🖼️',
            style: TextStyle(fontSize: size * 0.36, height: 1),
          ),
          if (size >= 120) ...[
            const SizedBox(height: 8),
            const Text(
              'Picture coming soon!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KidsColors.inkSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
