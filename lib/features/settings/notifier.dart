import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class SettingsState {
  final ThemeMode themeMode;

  /// 'kg' | 'lbs'
  final String weightUnit;
  final bool onboardingComplete;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.weightUnit = 'kg',
    this.onboardingComplete = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? weightUnit,
    bool? onboardingComplete,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        weightUnit: weightUnit ?? this.weightUnit,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
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
    );
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

  // ── API keys (flutter_secure_storage) ───────────────────────────────────────

  Future<String?> getGeminiApiKey() => _secure.read(key: 'gemini_api_key');
  Future<void> setGeminiApiKey(String key) =>
      _secure.write(key: 'gemini_api_key', value: key);

  Future<String?> getUsdaApiKey() => _secure.read(key: 'usda_api_key');
  Future<void> setUsdaApiKey(String key) =>
      _secure.write(key: 'usda_api_key', value: key);

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

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
