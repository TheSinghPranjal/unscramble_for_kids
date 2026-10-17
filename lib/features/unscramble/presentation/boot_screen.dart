import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/kids_palette.dart';
import '../../../shared/widgets/clay.dart';
import '../application/boot.dart';
import '../application/rewards_controller.dart';
import '../data/image_assets.dart';
import '../data/word_repository.dart';
import 'home_screen.dart';

/// Splash: loads + validates words, then hands off to Home. Load failures
/// show a friendly retry card instead of a blank screen.
class BootScreen extends ConsumerWidget {
  const BootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(activePaletteProvider);
    final boot = ref.watch(bootProvider);
    return Scaffold(
      body: KidsBackground(
        palette: palette,
        child: SafeArea(
          child: switch (boot) {
            AsyncData() => const HomeScreen(),
            AsyncError(:final error) => _BootError(
              error: error,
              onRetry: () {
                ref.invalidate(wordBankProvider);
                ref.invalidate(assetKeysProvider);
                ref.invalidate(bootProvider);
              },
            ),
            _ => const _Splash(),
          },
        ),
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, l) in 'ABC'.split('').indexed)
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: ClayLetterTile(
                    letter: l,
                    size: 64,
                    color: KidsColors.tileFills[i],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Getting your words ready…',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

class _BootError extends StatelessWidget {
  const _BootError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ClayCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🙈', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(
                'Oops! The words are hiding.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Let’s try that again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: KidsColors.inkSoft),
              ),
              const SizedBox(height: 20),
              ClayButton.label(
                onPressed: onRetry,
                label: 'Try again',
                icon: Icons.refresh_rounded,
                color: KidsColors.mint,
              ),
              const SizedBox(height: 12),
              // Grown-up detail, small and soft.
              Text(
                '$error',
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: KidsColors.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
