import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/prefs/prefs.dart';
import '../domain/rewards.dart';

final rewardRepositoryProvider = Provider<RewardRepository>(
  (ref) => RewardRepository(ref.watch(sharedPreferencesProvider)),
);

/// Local-only progress (stars, badges, high score, theme) as one JSON blob.
class RewardRepository {
  RewardRepository(this._prefs);

  final SharedPreferences _prefs;

  PlayerProgress load() {
    final raw = _prefs.getString(PrefKeys.progress);
    if (raw == null) return const PlayerProgress();
    try {
      return PlayerProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[rewards] corrupt progress, starting fresh: $e');
      return const PlayerProgress();
    }
  }

  Future<void> save(PlayerProgress progress) =>
      _prefs.setString(PrefKeys.progress, jsonEncode(progress.toJson()));

  Future<void> clear() => _prefs.remove(PrefKeys.progress);
}
