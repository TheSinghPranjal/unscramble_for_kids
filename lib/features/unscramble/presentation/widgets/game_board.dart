import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../shared/theme/kids_palette.dart';
import '../../../../shared/widgets/clay.dart';
import '../../../../shared/widgets/confetti.dart';
import '../../domain/game_state.dart';
import '../../domain/word_entry.dart';
import 'word_picture.dart';

/// Lives, timer and score.
class GameHud extends StatelessWidget {
  const GameHud({super.key, required this.state, required this.onPause});

  final GameState state;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final seconds = state.secondsLeft;
    return Row(
      children: [
        ClayIconButton(
          key: const Key('pause-button'),
          icon: Icons.pause_rounded,
          tooltip: 'Pause',
          onPressed: state.isPlaying ? onPause : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Shake(
            trigger: state.wrongTick,
            child: Semantics(
              label: '${state.lives} of ${GameState.maxLives} hearts left',
              excludeSemantics: true,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    for (var i = 0; i < GameState.maxLives; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (c, a) =>
                              ScaleTransition(scale: a, child: c),
                          child: Icon(
                            i < state.lives
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey(i < state.lives),
                            size: 32,
                            color: i < state.lives
                                ? KidsColors.wrong
                                : KidsColors.locked,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (seconds != null) ...[
          _Pill(
            key: const Key('timer-pill'),
            icon: Icons.timer_rounded,
            text:
                '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
            color: seconds <= 10 ? KidsColors.coral : KidsColors.sky,
            semantics: '$seconds seconds left',
          ),
          const SizedBox(width: 8),
        ],
        _Pill(
          icon: Icons.star_rounded,
          text: '${state.sessionScore}',
          color: KidsColors.yellow,
          semantics: 'Score ${state.sessionScore}',
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    required this.semantics,
  });

  final IconData icon;
  final String text;
  final Color color;
  final String semantics;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: clayDecoration(color, radius: 999, depth: 0.6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: KidsColors.ink),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Big picture clue in a clay frame + category / length chips + hint text.
class PictureClue extends StatelessWidget {
  const PictureClue({
    super.key,
    required this.entry,
    required this.size,
    required this.flash,
    required this.showHintText,
  });

  final WordEntry entry;
  final double size;
  final bool flash;
  final bool showHintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Bounce(
          trigger: flash ? 1 : 0,
          from: 0.9,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: flash
                  ? [
                      BoxShadow(
                        color: KidsColors.star.withValues(alpha: 0.8),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ]
                  : const [],
            ),
            child: ClayCard(
              key: const Key('picture-clue'),
              padding: const EdgeInsets.all(10),
              radius: 30,
              child: WordPicture(entry: entry, size: size, radius: 22),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            ClayChip(
              label: entry.category,
              color: KidsColors.forCategory(entry.category),
              leading: Text(
                KidsColors.categoryEmoji[entry.category] ?? '✨',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            ClayChip(
              label: '${entry.length} letters',
              leading: const Icon(Icons.abc_rounded, size: 20),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: (showHintText || flash) && entry.hintText.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    key: const Key('hint-text'),
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: clayInsetDecoration(
                      flash ? KidsColors.yellow : KidsColors.cream,
                      radius: 18,
                    ),
                    child: Text(
                      '💡 ${entry.hintText}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Empty answer slots. Accepts drops, or tap to select then tap a letter.
class AnswerSlots extends StatelessWidget {
  const AnswerSlots({
    super.key,
    required this.state,
    required this.tileSize,
    required this.onSelect,
    required this.onDrop,
  });

  final GameState state;
  final double tileSize;
  final ValueChanged<int> onSelect;
  final void Function(int tileId, int slot) onDrop;

  @override
  Widget build(BuildContext context) {
    final n = state.slots.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < n; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tileSize * 0.08),
            child: _Slot(
              index: i,
              count: n,
              letter: state.letterAt(i),
              selected: state.selectedSlot == i,
              size: tileSize,
              enabled: state.isPlaying,
              bounceTick: state.lastLockedSlot == i ? state.correctTick : 0,
              onTap: () => onSelect(i),
              onDrop: (tileId) => onDrop(tileId, i),
            ),
          ),
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.index,
    required this.count,
    required this.letter,
    required this.selected,
    required this.size,
    required this.enabled,
    required this.bounceTick,
    required this.onTap,
    required this.onDrop,
  });

  final int index;
  final int count;
  final String? letter;
  final bool selected;
  final double size;
  final bool enabled;
  final int bounceTick;
  final VoidCallback onTap;
  final ValueChanged<int> onDrop;

  @override
  Widget build(BuildContext context) {
    final filled = letter;
    if (filled != null) {
      return Semantics(
        label: 'Box ${index + 1} of $count: $filled, correct',
        excludeSemantics: true,
        child: Bounce(
          trigger: bounceTick,
          child: ClayLetterTile(
            key: Key('slot-$index'),
            letter: filled,
            size: size,
            color: KidsColors.mint,
            badge: const _CheckBadge(),
          ),
        ),
      );
    }
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => enabled,
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, candidates, _) {
        final hovering = candidates.isNotEmpty;
        return Semantics(
          button: true,
          selected: selected,
          label: 'Box ${index + 1} of $count, empty',
          excludeSemantics: true,
          onTap: onTap,
          child: GestureDetector(
            key: Key('slot-$index'),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: size,
              height: size,
              decoration:
                  clayInsetDecoration(
                    hovering
                        ? KidsColors.sky.withValues(alpha: 0.5)
                        : KidsColors.slot,
                    radius: size * 0.28,
                  ).copyWith(
                    border: Border.all(
                      color: selected || hovering
                          ? KidsColors.coral
                          : Colors.white.withValues(alpha: 0.85),
                      width: selected || hovering ? 4 : 2,
                    ),
                  ),
              alignment: Alignment.center,
              child: selected
                  ? Icon(
                      Icons.touch_app_rounded,
                      color: KidsColors.coral,
                      size: size * 0.4,
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: KidsColors.success,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: Colors.white, spreadRadius: 2)],
    ),
    padding: const EdgeInsets.all(2),
    child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
  );
}

/// Scrambled letters waiting to be placed. Tap → next/selected slot,
/// or drag onto a slot.
class LetterTray extends StatelessWidget {
  const LetterTray({
    super.key,
    required this.state,
    required this.tileSize,
    required this.onTap,
  });

  final GameState state;
  final double tileSize;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final placed = state.placedTileIds;
    final gap = tileSize * 0.16;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final tile in state.tiles)
          SizedBox(
            width: tileSize,
            height: tileSize,
            child: placed.contains(tile.id)
                ? _GhostSlot(size: tileSize)
                : Shake(
                    trigger: state.lastWrongTileId == tile.id
                        ? state.wrongTick
                        : 0,
                    child: _TrayTile(
                      tile: tile,
                      size: tileSize,
                      enabled: state.isPlaying,
                      onTap: () => onTap(tile.id),
                    ),
                  ),
          ),
      ],
    );
  }
}

class _TrayTile extends StatelessWidget {
  const _TrayTile({
    required this.tile,
    required this.size,
    required this.enabled,
    required this.onTap,
  });

  final LetterTile tile;
  final double size;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = KidsColors.tileFills[tile.id % KidsColors.tileFills.length];
    final face = ClayLetterTile(letter: tile.letter, size: size, color: color);
    return Semantics(
      button: true,
      label: 'Letter ${tile.letter}',
      excludeSemantics: true,
      onTap: enabled ? onTap : null,
      child: Draggable<int>(
        key: Key('tile-${tile.id}'),
        data: tile.id,
        maxSimultaneousDrags: enabled ? 1 : 0,
        feedback: Transform.scale(scale: 1.12, child: face),
        childWhenDragging: Opacity(opacity: 0.3, child: face),
        child: _Squish(onTap: enabled ? onTap : null, child: face),
      ),
    );
  }
}

class _Squish extends StatefulWidget {
  const _Squish({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  State<_Squish> createState() => _SquishState();
}

class _SquishState extends State<_Squish> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

class _GhostSlot extends StatelessWidget {
  const _GhostSlot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        color: Colors.white.withValues(alpha: 0.35),
      ),
    ),
  );
}

/// Friendly one-line feedback (icon + words, never color alone).
class FeedbackLine extends StatefulWidget {
  const FeedbackLine({
    super.key,
    required this.wrongTick,
    required this.correctTick,
  });

  final int wrongTick;
  final int correctTick;

  @override
  State<FeedbackLine> createState() => _FeedbackLineState();
}

class _FeedbackLineState extends State<FeedbackLine> {
  (IconData, String, Color)? _message;
  Timer? _clear;

  static const _cheers = ['Yay!', 'Great job!', 'You got it!', 'Super!'];

  @override
  void didUpdateWidget(FeedbackLine old) {
    super.didUpdateWidget(old);
    if (widget.wrongTick > old.wrongTick) {
      _show((
        Icons.replay_rounded,
        'Oops! Try another letter',
        KidsColors.wrong,
      ));
    } else if (widget.correctTick > old.correctTick) {
      _show((
        Icons.check_circle_rounded,
        _cheers[widget.correctTick % _cheers.length],
        KidsColors.success,
      ));
    }
  }

  void _show((IconData, String, Color) m) {
    _clear?.cancel();
    setState(() => _message = m);
    _clear = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _message = null);
    });
  }

  @override
  void dispose() {
    _clear?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = _message;
    return SizedBox(
      height: 34,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: m == null
            ? const SizedBox.shrink()
            : Semantics(
                liveRegion: true,
                child: Row(
                  key: ValueKey(m.$2),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(m.$1, color: m.$3, size: 26),
                    const SizedBox(width: 6),
                    Text(
                      m.$2,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: KidsColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class HintButton extends StatelessWidget {
  const HintButton({super.key, required this.state, required this.onHint});

  final GameState state;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    final String label;
    if (state.hintUsed) {
      label = 'Hint used';
    } else if (state.hintUnlocked) {
      label = 'Use a hint!';
    } else {
      final n = state.mistakesUntilHint;
      label = 'Hint after $n more ${n == 1 ? 'try' : 'tries'}';
    }
    return Bounce(
      trigger: state.hintUnlocked ? 1 : 0,
      child: ClayButton.label(
        key: const Key('hint-button'),
        onPressed: state.canUseHint ? onHint : null,
        label: label,
        icon: state.canUseHint
            ? Icons.lightbulb_rounded
            : state.hintUsed
            ? Icons.check_rounded
            : Icons.lock_rounded,
        color: KidsColors.yellow,
        fontSize: 18,
      ),
    );
  }
}
