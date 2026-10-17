import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs.dart';

@immutable
class AppSettings {
  const AppSettings({
    this.defaultLength = 3,
    this.timerByLength = defaultTimers,
    this.sound = true,
    this.haptics = true,
    this.showHintText = true,
    this.easyFirst = true,
    this.defaultCategory,
    this.coachSeen = false,
  });

  /// Timer defaults: OFF for 3 letters (youngest kids), ON for 4 and 5.
  static const defaultTimers = {3: false, 4: true, 5: true};

  final int defaultLength;
  final Map<int, bool> timerByLength;
  final bool sound;
  final bool haptics;
  final bool showHintText;
  final bool easyFirst;

  /// `null` means "All Categories".
  final String? defaultCategory;
  final bool coachSeen;

  bool timerFor(int length) =>
      timerByLength[length] ?? defaultTimers[length] ?? false;

  AppSettings copyWith({
    int? defaultLength,
    Map<int, bool>? timerByLength,
    bool? sound,
    bool? haptics,
    bool? showHintText,
    bool? easyFirst,
    String? Function()? defaultCategory,
    bool? coachSeen,
  }) {
    return AppSettings(
      defaultLength: defaultLength ?? this.defaultLength,
      timerByLength: timerByLength ?? this.timerByLength,
      sound: sound ?? this.sound,
      haptics: haptics ?? this.haptics,
      showHintText: showHintText ?? this.showHintText,
      easyFirst: easyFirst ?? this.easyFirst,
      defaultCategory: defaultCategory != null
          ? defaultCategory()
          : this.defaultCategory,
      coachSeen: coachSeen ?? this.coachSeen,
    );
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final p = ref.watch(sharedPreferencesProvider);
    final length = p.getInt(PrefKeys.defaultLength) ?? 3;
    return AppSettings(
      defaultLength: const {3, 4, 5}.contains(length) ? length : 3,
      timerByLength: {
        for (final n in const [3, 4, 5])
          n:
              p.getBool('${PrefKeys.timerPrefix}$n') ??
              AppSettings.defaultTimers[n]!,
      },
      sound: p.getBool(PrefKeys.sound) ?? true,
      haptics: p.getBool(PrefKeys.haptics) ?? true,
      showHintText: p.getBool(PrefKeys.showHintText) ?? true,
      easyFirst: p.getBool(PrefKeys.easyFirst) ?? true,
      defaultCategory: p.getString(PrefKeys.defaultCategory),
      coachSeen: p.getBool(PrefKeys.coachSeen) ?? false,
    );
  }

  void setDefaultLength(int length) {
    ref.read(sharedPreferencesProvider).setInt(PrefKeys.defaultLength, length);
    state = state.copyWith(defaultLength: length);
  }

  void setTimer(int length, bool on) {
    ref
        .read(sharedPreferencesProvider)
        .setBool('${PrefKeys.timerPrefix}$length', on);
    state = state.copyWith(timerByLength: {...state.timerByLength, length: on});
  }

  void setSound(bool on) {
    ref.read(sharedPreferencesProvider).setBool(PrefKeys.sound, on);
    state = state.copyWith(sound: on);
  }

  void setHaptics(bool on) {
    ref.read(sharedPreferencesProvider).setBool(PrefKeys.haptics, on);
    state = state.copyWith(haptics: on);
  }

  void setShowHintText(bool on) {
    ref.read(sharedPreferencesProvider).setBool(PrefKeys.showHintText, on);
    state = state.copyWith(showHintText: on);
  }

  void setEasyFirst(bool on) {
    ref.read(sharedPreferencesProvider).setBool(PrefKeys.easyFirst, on);
    state = state.copyWith(easyFirst: on);
  }

  void setDefaultCategory(String? category) {
    final p = ref.read(sharedPreferencesProvider);
    if (category == null) {
      p.remove(PrefKeys.defaultCategory);
    } else {
      p.setString(PrefKeys.defaultCategory, category);
    }
    state = state.copyWith(defaultCategory: () => category);
  }

  void setCoachSeen(bool seen) {
    ref.read(sharedPreferencesProvider).setBool(PrefKeys.coachSeen, seen);
    state = state.copyWith(coachSeen: seen);
  }
}
