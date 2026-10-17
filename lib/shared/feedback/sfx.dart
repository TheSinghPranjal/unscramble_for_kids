import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prefs/app_settings.dart';

/// Sound + haptic feedback. Uses platform system sounds/haptics only, so a
/// missing audio asset can never crash a round; every call is a safe no-op
/// when the matching setting is off or the platform has no support.
final sfxProvider = Provider<Sfx>((ref) => Sfx(ref));

class Sfx {
  Sfx(this._ref);

  final Ref _ref;

  bool get _sound => _ref.read(settingsProvider).sound;
  bool get _haptics => _ref.read(settingsProvider).haptics;

  void tap() => _run(HapticFeedback.selectionClick, sound: false);

  void correct() => _run(HapticFeedback.lightImpact);

  void wrong() => _run(HapticFeedback.mediumImpact, sound: false);

  void win() => _run(HapticFeedback.heavyImpact);

  void _run(Future<void> Function() haptic, {bool sound = true}) {
    // Feedback is decorative; never let it break gameplay (sync or async).
    void ignore(Object _) {}
    try {
      if (_haptics) haptic().catchError(ignore);
      if (sound && _sound) {
        SystemSound.play(SystemSoundType.click).catchError(ignore);
      }
    } catch (_) {}
  }
}
