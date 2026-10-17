import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main()` (and in tests) with a loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

abstract final class PrefKeys {
  static const defaultLength = 'settings.defaultLength';
  static const timerPrefix = 'settings.timer.'; // + length
  static const sound = 'settings.sound';
  static const haptics = 'settings.haptics';
  static const showHintText = 'settings.showHintText';
  static const easyFirst = 'settings.easyFirst';
  static const defaultCategory = 'settings.defaultCategory';
  static const coachSeen = 'settings.coachSeen';
  static const progress = 'progress.v1';
}
