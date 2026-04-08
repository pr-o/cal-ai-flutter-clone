import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/notifications.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class SettingsState {
  final ThemeMode themeMode;

  /// 'kg' | 'lbs'
  final String weightUnit;
  final bool onboardingComplete;
  final bool reminderBreakfast;
  final bool reminderLunch;
  final bool reminderDinner;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.weightUnit = 'kg',
    this.onboardingComplete = false,
    this.reminderBreakfast = false,
    this.reminderLunch = false,
    this.reminderDinner = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? weightUnit,
    bool? onboardingComplete,
    bool? reminderBreakfast,
    bool? reminderLunch,
    bool? reminderDinner,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    weightUnit: weightUnit ?? this.weightUnit,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    reminderBreakfast: reminderBreakfast ?? this.reminderBreakfast,
    reminderLunch: reminderLunch ?? this.reminderLunch,
    reminderDinner: reminderDinner ?? this.reminderDinner,
  );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class SettingsNotifier extends Notifier<SettingsState> {
  static const _secure = FlutterSecureStorage();

  @override
  SettingsState build() {
    _hydrate();
    return const SettingsState();
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      themeMode: _modeFrom(prefs.getString('theme') ?? 'system'),
      weightUnit: prefs.getString('weight_unit') ?? 'kg',
      onboardingComplete: prefs.getBool('onboarding_complete') ?? false,
      reminderBreakfast: prefs.getBool('reminder_breakfast') ?? false,
      reminderLunch: prefs.getBool('reminder_lunch') ?? false,
      reminderDinner: prefs.getBool('reminder_dinner') ?? false,
    );
    await _seedApiKeysFromEnv(prefs);
  }

  /// Seeds API keys from the .env file (loaded by flutter_dotenv at startup).
  /// On Linux, SharedPreferences is used instead of the keyring because
  /// flutter_secure_storage throws an uncatchable PlatformException on
  /// WSL2 / headless Linux where no keyring daemon is running.
  Future<void> _seedApiKeysFromEnv(SharedPreferences prefs) async {
    if (Platform.isLinux) {
      if ((prefs.getString('gemini_api_key') ?? '').isEmpty) {
        final v = _dotenvGet('GEMINI_API_KEY');
        if (v.isNotEmpty) await prefs.setString('gemini_api_key', v);
      }
      if ((prefs.getString('usda_api_key') ?? '').isEmpty) {
        final v = _dotenvGet('USDA_API_KEY');
        if (v.isNotEmpty) await prefs.setString('usda_api_key', v);
      }
      return;
    }
    // Non-Linux: use secure storage (Keychain / EncryptedSharedPrefs).
    final gemini = await _secure.read(key: 'gemini_api_key');
    if (gemini == null || gemini.isEmpty) {
      final v = _dotenvGet('GEMINI_API_KEY');
      if (v.isNotEmpty) await _secure.write(key: 'gemini_api_key', value: v);
    }
    final usda = await _secure.read(key: 'usda_api_key');
    if (usda == null || usda.isEmpty) {
      final v = _dotenvGet('USDA_API_KEY');
      if (v.isNotEmpty) await _secure.write(key: 'usda_api_key', value: v);
    }
  }

  String _dotenvGet(String key) {
    try {
      return dotenv.maybeGet(key) ?? '';
    } catch (_) {
      return '';
    }
  }

  // ── Non-sensitive settings (SharedPreferences) ──────────────────────────────

  Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', _modeToString(mode));
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setWeightUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weight_unit', unit);
    state = state.copyWith(weightUnit: unit);
  }

  Future<void> setOnboardingComplete(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', value);
    state = state.copyWith(onboardingComplete: value);
  }

  Future<void> clearOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_complete');
    state = state.copyWith(onboardingComplete: false);
  }

  Future<void> setReminder(String meal, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_$meal', enabled);

    final ids = <String, int>{'breakfast': 0, 'lunch': 1, 'dinner': 2};
    final times = <String, (int, int, String)>{
      'breakfast': (8, 0, 'Time for breakfast! Log your meal.'),
      'lunch': (12, 0, 'Lunchtime! Don\'t forget to log your meal.'),
      'dinner': (19, 0, 'Dinner time! Log your evening meal.'),
    };

    if (enabled) {
      final (hour, minute, label) = times[meal]!;
      await scheduleMealReminder(ids[meal]!, hour, minute, label);
    } else {
      await cancelReminder(ids[meal]!);
    }

    state = switch (meal) {
      'breakfast' => state.copyWith(reminderBreakfast: enabled),
      'lunch' => state.copyWith(reminderLunch: enabled),
      'dinner' => state.copyWith(reminderDinner: enabled),
      _ => state,
    };
  }

  // ── API keys (flutter_secure_storage) ───────────────────────────────────────

  Future<String?> getGeminiApiKey() async {
    if (Platform.isLinux) {
      final p = await SharedPreferences.getInstance();
      return p.getString('gemini_api_key');
    }
    return _secure.read(key: 'gemini_api_key');
  }

  Future<void> setGeminiApiKey(String key) async {
    if (Platform.isLinux) {
      final p = await SharedPreferences.getInstance();
      await p.setString('gemini_api_key', key);
      return;
    }
    await _secure.write(key: 'gemini_api_key', value: key);
  }

  Future<String?> getUsdaApiKey() async {
    if (Platform.isLinux) {
      final p = await SharedPreferences.getInstance();
      return p.getString('usda_api_key');
    }
    return _secure.read(key: 'usda_api_key');
  }

  Future<void> setUsdaApiKey(String key) async {
    if (Platform.isLinux) {
      final p = await SharedPreferences.getInstance();
      await p.setString('usda_api_key', key);
      return;
    }
    await _secure.write(key: 'usda_api_key', value: key);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  ThemeMode _modeFrom(String s) => switch (s) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  String _modeToString(ThemeMode m) => switch (m) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    _ => 'system',
  };
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
