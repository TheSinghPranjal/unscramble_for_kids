import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/prefs/app_settings.dart';
import '../../../shared/theme/kids_palette.dart';
import '../../../shared/widgets/clay.dart';
import '../application/rewards_controller.dart';
import '../application/unscramble_controller.dart';
import '../domain/game_state.dart';
import 'how_to_play_screen.dart';
import 'rewards_screen.dart';
import 'widgets/game_board.dart';
import 'widgets/game_dialogs.dart';

/// The puzzle. Start a session with
/// `unscrambleControllerProvider.notifier.start(config)` before pushing.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final UnscrambleController _controller;
  late final AppLifecycleListener _lifecycle;
  Timer? _hintFlashTimer;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(unscrambleControllerProvider.notifier);
    // Backgrounding the app pauses the clock.
    _lifecycle = AppLifecycleListener(
      onHide: _controller.pause,
      onPause: _controller.pause,
    );
  }

  @override
  void dispose() {
    _hintFlashTimer?.cancel();
    _lifecycle.dispose();
    _controller.leave();
    super.dispose();
  }

  void _onStateChange(GameState? prev, GameState next) {
    if (prev?.status != RoundStatus.won && next.status == RoundStatus.won) {
      _showWin(next);
    } else if (prev?.status != RoundStatus.lost &&
        next.status == RoundStatus.lost) {
      _showLose(next);
    }
    if (next.hintFlash && !(prev?.hintFlash ?? false)) {
      _hintFlashTimer?.cancel();
      _hintFlashTimer = Timer(
        const Duration(milliseconds: 2500),
        _controller.dismissHintFlash,
      );
    }
  }

  Future<void> _showWin(GameState s) async {
    final reward = s.lastWin;
    final entry = s.entry;
    if (reward == null || entry == null) return;
    // Let the last tile's bounce land before the dialog pops in.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    final action = await showWinDialog(context, entry: entry, reward: reward);
    if (!mounted) return;
    switch (action) {
      case WinAction.next || null:
        _controller.nextWord();
      case WinAction.rewards:
        _controller
          ..nextWord()
          ..pause();
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const RewardsScreen()));
        _controller.resume();
      case WinAction.home:
        Navigator.of(context).pop();
    }
  }

  Future<void> _showLose(GameState s) async {
    final entry = s.entry;
    if (entry == null) return;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final action = await showLoseDialog(
      context,
      entry: entry,
      reason: s.loseReason ?? LoseReason.outOfLives,
    );
    if (!mounted) return;
    switch (action) {
      case LoseAction.retry || null:
        _controller.retry();
      case LoseAction.newWord:
        _controller.nextWord();
      case LoseAction.home:
        Navigator.of(context).pop();
    }
  }

  Future<void> _quit() async {
    if (await confirmQuit(context) && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(unscrambleControllerProvider, _onStateChange);
    final state = ref.watch(unscrambleControllerProvider);
    final palette = ref.watch(activePaletteProvider);
    final showHintText = ref.watch(settingsProvider).showHintText;
    final entry = state.entry;

    return PopScope(
      canPop: !state.isPlaying,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _controller.pause();
      },
      child: Scaffold(
        body: KidsBackground(
          palette: palette,
          child: SafeArea(
            child: entry == null
                ? _EmptyDeck(onHome: () => Navigator.of(context).pop())
                : Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Column(
                          children: [
                            GameHud(state: state, onPause: _controller.pause),
                            const SizedBox(height: 8),
                            Expanded(
                              child: _Board(
                                state: state,
                                showHintText: showHintText,
                                controller: _controller,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (state.status == RoundStatus.paused)
                        _PausedOverlay(
                          onResume: _controller.resume,
                          onHelp: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const HowToPlayScreen(),
                            ),
                          ),
                          onHome: _quit,
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Picture on top in portrait, side by side in landscape. Sizes are derived
/// from the available space so the picture always stays visible.
class _Board extends StatelessWidget {
  const _Board({
    required this.state,
    required this.showHintText,
    required this.controller,
  });

  final GameState state;
  final bool showHintText;
  final UnscrambleController controller;

  @override
  Widget build(BuildContext context) {
    final entry = state.entry!;
    return LayoutBuilder(
      builder: (context, c) {
        final landscape = c.maxWidth > c.maxHeight * 1.15;
        final boardWidth = landscape ? c.maxWidth * 0.55 : c.maxWidth;
        final n = entry.length;
        final tile = ((boardWidth - 24) / (n * 1.2)).clamp(44.0, 80.0);

        final board = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnswerSlots(
              state: state,
              tileSize: tile,
              onSelect: controller.selectSlot,
              onDrop: (id, slot) => controller.placeTile(id, slot: slot),
            ),
            FeedbackLine(
              wrongTick: state.wrongTick,
              correctTick: state.correctTick,
            ),
            const SizedBox(height: 4),
            LetterTray(
              state: state,
              tileSize: tile,
              onTap: (id) => controller.placeTile(id),
            ),
            const SizedBox(height: 16),
            HintButton(state: state, onHint: controller.useHint),
          ],
        );

        // Room left for the picture after the board, its clay frame (40),
        // the chips row and the optional hint text.
        final boardHeight = tile * 2 + 34 + 16 + 64 + 24;
        final extras = 40 + 52 + (showHintText || state.hintFlash ? 64.0 : 0);
        final picture = landscape
            ? (c.maxHeight - extras - 8).clamp(96.0, c.maxWidth * 0.4)
            : (c.maxHeight - boardHeight - extras - 20).clamp(
                110.0,
                (c.maxWidth * 0.75).clamp(110.0, 360.0),
              );

        final clue = PictureClue(
          entry: entry,
          size: picture.toDouble(),
          flash: state.hintFlash,
          showHintText: showHintText,
        );

        if (landscape) {
          return Row(
            children: [
              Expanded(
                child: Center(child: SingleChildScrollView(child: clue)),
              ),
              SizedBox(width: boardWidth, child: board),
            ],
          );
        }
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [clue, const SizedBox(height: 12), board],
            ),
          ),
        );
      },
    );
  }
}

class _PausedOverlay extends StatelessWidget {
  const _PausedOverlay({
    required this.onResume,
    required this.onHelp,
    required this.onHome,
  });

  final VoidCallback onResume;
  final VoidCallback onHelp;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: KidsColors.ink.withValues(alpha: 0.3),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: ClayCard(
                key: const Key('paused-overlay'),
                padding: const EdgeInsets.all(24),
                radius: 32,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('😴', style: TextStyle(fontSize: 56)),
                    Text(
                      'Taking a break',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 20),
                    ClayButton.label(
                      key: const Key('resume-button'),
                      onPressed: onResume,
                      label: 'Keep playing',
                      icon: Icons.play_arrow_rounded,
                      color: KidsColors.mint,
                      expand: true,
                      fontSize: 22,
                    ),
                    const SizedBox(height: 12),
                    ClayButton.label(
                      onPressed: onHelp,
                      label: 'How to Play',
                      icon: Icons.help_rounded,
                      color: KidsColors.sky,
                      expand: true,
                    ),
                    const SizedBox(height: 12),
                    ClayButton.label(
                      onPressed: onHome,
                      label: 'Home',
                      icon: Icons.home_rounded,
                      color: KidsColors.cream,
                      expand: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyDeck extends StatelessWidget {
  const _EmptyDeck({required this.onHome});

  final VoidCallback onHome;

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
              const Text('🔍', style: TextStyle(fontSize: 56)),
              Text(
                'No words here yet!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Pick another topic or word size.',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ClayButton.label(
                onPressed: onHome,
                label: 'Home',
                icon: Icons.home_rounded,
                color: KidsColors.mint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
