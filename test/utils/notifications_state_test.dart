import 'package:cal_ai_flutter_clone/features/settings/notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsState reminders', () {
    test('defaults to all reminders off', () {
      const state = SettingsState();
      expect(state.reminderBreakfast, false);
      expect(state.reminderLunch, false);
      expect(state.reminderDinner, false);
    });

    test('copyWith updates individual reminder without touching others', () {
      const state = SettingsState();
      final updated = state.copyWith(reminderBreakfast: true);
      expect(updated.reminderBreakfast, true);
      expect(updated.reminderLunch, false);
      expect(updated.reminderDinner, false);
    });

    test('copyWith preserves existing theme and weightUnit', () {
      const state = SettingsState(themeMode: ThemeMode.dark, weightUnit: 'lbs');
      final updated = state.copyWith(reminderDinner: true);
      expect(updated.themeMode, ThemeMode.dark);
      expect(updated.weightUnit, 'lbs');
      expect(updated.reminderDinner, true);
    });
  });
}
