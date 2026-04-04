# Push Notifications (Meal Reminders) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add optional daily meal reminder notifications (breakfast 8 AM, lunch 12 PM, dinner 7 PM) toggled from the Settings screen, using `flutter_local_notifications` built-in permission APIs.

**Architecture:** A thin `lib/utils/notifications.dart` utility file holds the plugin singleton and three functions (`initNotifications`, `scheduleMealReminder`, `cancelReminder`). `SettingsNotifier` gains three reminder bool fields persisted to SharedPreferences; toggling a reminder in the Settings UI calls `setReminder` which writes to prefs and schedules/cancels via the util. No Riverpod provider is added for notifications.

**Tech Stack:** `flutter_local_notifications ^19.0.0` (already in pubspec), `flutter_timezone ^3.0.0`, `timezone ^0.9.0` (new), SharedPreferences for toggle persistence.

---

## File Map

| Action | File |
|--------|------|
| Modify | `pubspec.yaml` |
| Modify | `android/app/src/main/AndroidManifest.xml` |
| Create | `lib/utils/notifications.dart` |
| Modify | `lib/features/settings/notifier.dart` |
| Modify | `lib/features/settings/settings_screen.dart` |
| Create | `test/utils/notifications_state_test.dart` |

---

## Task 1: Add dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add flutter_timezone and timezone to pubspec.yaml**

In `pubspec.yaml`, add after the `flutter_local_notifications` line:

```yaml
  flutter_timezone: ^3.0.0
  timezone: ^0.9.0
```

The dependencies block should look like:

```yaml
  # Notifications
  flutter_local_notifications: ^19.0.0
  flutter_timezone: ^3.0.0
  timezone: ^0.9.0
```

- [ ] **Step 2: Fetch dependencies**

```bash
flutter pub get
```

Expected: Resolves successfully, no version conflicts.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add flutter_timezone and timezone dependencies"
```

---

## Task 2: Update Android manifest

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Add notification permissions**

In `android/app/src/main/AndroidManifest.xml`, add these three `<uses-permission>` lines directly after the existing `<uses-permission android:name="android.permission.CAMERA"/>` line:

```xml
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"
        android:maxSdkVersion="32"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

- [ ] **Step 2: Add notification receivers inside `<application>`**

Add these two `<receiver>` blocks inside the `<application>` tag, after the closing `</activity>` tag and before the `flutterEmbedding` `<meta-data>`:

```xml
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
```

- [ ] **Step 3: Verify the full manifest is valid XML**

```bash
xmllint --noout android/app/src/main/AndroidManifest.xml && echo "OK"
```

Expected: `OK` (or `xmllint: command not found` is acceptable — just ensure no syntax errors are visible).

- [ ] **Step 4: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "chore: add Android notification permissions and receivers"
```

---

## Task 3: Create notifications utility

**Files:**
- Create: `lib/utils/notifications.dart`

- [ ] **Step 1: Create the file**

Create `lib/utils/notifications.dart` with this exact content:

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const _channelId = 'meal_reminders';
const _channelName = 'Meal Reminders';

final _plugin = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  tz.initializeTimeZones();
  final timezoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timezoneName));

  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const settings =
      InitializationSettings(android: androidSettings, iOS: iosSettings);
  await _plugin.initialize(settings);

  await _plugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);

  await _plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  const channel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    importance: Importance.high,
  );
  await _plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> scheduleMealReminder(
    int id, int hour, int minute, String label) async {
  await _plugin.cancel(id);

  final now = tz.TZDateTime.now(tz.local);
  var scheduled =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }

  await _plugin.zonedSchedule(
    id,
    'Cal AI',
    label,
    scheduled,
    NotificationDetails(
      android: const AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

Future<void> cancelReminder(int id) => _plugin.cancel(id);
```

- [ ] **Step 2: Run static analysis**

```bash
flutter analyze lib/utils/notifications.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/utils/notifications.dart
git commit -m "feat: add notifications utility (initNotifications, scheduleMealReminder, cancelReminder)"
```

---

## Task 4: Extend SettingsState and SettingsNotifier

**Files:**
- Modify: `lib/features/settings/notifier.dart`
- Create: `test/utils/notifications_state_test.dart`

- [ ] **Step 1: Write the failing test first**

Create `test/utils/notifications_state_test.dart`:

```dart
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
      const state = SettingsState(
        themeMode: ThemeMode.dark,
        weightUnit: 'lbs',
      );
      final updated = state.copyWith(reminderDinner: true);
      expect(updated.themeMode, ThemeMode.dark);
      expect(updated.weightUnit, 'lbs');
      expect(updated.reminderDinner, true);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/utils/notifications_state_test.dart
```

Expected: FAIL — `The getter 'reminderBreakfast' isn't defined`.

- [ ] **Step 3: Update SettingsState in `lib/features/settings/notifier.dart`**

Replace the `SettingsState` class with:

```dart
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
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        weightUnit: weightUnit ?? this.weightUnit,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        reminderBreakfast: reminderBreakfast ?? this.reminderBreakfast,
        reminderLunch: reminderLunch ?? this.reminderLunch,
        reminderDinner: reminderDinner ?? this.reminderDinner,
      );
}
```

- [ ] **Step 4: Update `_hydrate()` in `SettingsNotifier` to read reminder prefs**

Replace the `_hydrate` method body with:

```dart
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
  }
```

- [ ] **Step 5: Add `setReminder` method to `SettingsNotifier`**

Add this method to `SettingsNotifier` after `clearOnboarding()`:

```dart
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
```

- [ ] **Step 6: Add the missing imports to `notifier.dart`**

Add at the top of `lib/features/settings/notifier.dart`, after the existing imports:

```dart
import '../../utils/notifications.dart';
```

- [ ] **Step 7: Run the test to verify it passes**

```bash
flutter test test/utils/notifications_state_test.dart
```

Expected: All 3 tests PASS.

- [ ] **Step 8: Run full test suite**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 9: Commit**

```bash
git add lib/features/settings/notifier.dart test/utils/notifications_state_test.dart
git commit -m "feat: add reminder state to SettingsNotifier with setReminder method"
```

---

## Task 5: Add Reminders section to Settings screen

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: Add Reminders section to the ListView in `_SettingsScreenState.build()`**

In `settings_screen.dart`, find this block in the `ListView` children:

```dart
          _WeightUnitTile(unit: settings.weightUnit),
          const SizedBox(height: 20),
          _SectionHeader('API Keys'),
```

Replace it with:

```dart
          _WeightUnitTile(unit: settings.weightUnit),
          const SizedBox(height: 20),
          _SectionHeader('Reminders'),
          const SizedBox(height: 8),
          _RemindersTile(),
          const SizedBox(height: 20),
          _SectionHeader('API Keys'),
```

- [ ] **Step 2: Add the `_RemindersTile` widget class at the bottom of `settings_screen.dart`**

Add this class after the `_NumField` class at the bottom of the file:

```dart
class _RemindersTile extends ConsumerStatefulWidget {
  const _RemindersTile();

  @override
  ConsumerState<_RemindersTile> createState() => _RemindersTileState();
}

class _RemindersTileState extends ConsumerState<_RemindersTile> {
  bool _breakfastLoading = false;
  bool _lunchLoading = false;
  bool _dinnerLoading = false;

  Future<void> _toggle(String meal, bool value) async {
    setState(() {
      if (meal == 'breakfast') _breakfastLoading = true;
      if (meal == 'lunch') _lunchLoading = true;
      if (meal == 'dinner') _dinnerLoading = true;
    });
    // Request permission on first enable
    if (value) await initNotifications();
    await ref.read(settingsProvider.notifier).setReminder(meal, value);
    if (mounted) {
      setState(() {
        if (meal == 'breakfast') _breakfastLoading = false;
        if (meal == 'lunch') _lunchLoading = false;
        if (meal == 'dinner') _dinnerLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _ReminderRow(
            emoji: '🌅',
            label: 'Breakfast',
            time: '8:00 AM',
            value: settings.reminderBreakfast,
            loading: _breakfastLoading,
            onChanged: (v) => _toggle('breakfast', v),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _ReminderRow(
            emoji: '☀️',
            label: 'Lunch',
            time: '12:00 PM',
            value: settings.reminderLunch,
            loading: _lunchLoading,
            onChanged: (v) => _toggle('lunch', v),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _ReminderRow(
            emoji: '🌙',
            label: 'Dinner',
            time: '7:00 PM',
            value: settings.reminderDinner,
            loading: _dinnerLoading,
            onChanged: (v) => _toggle('dinner', v),
          ),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.emoji,
    required this.label,
    required this.time,
    required this.value,
    required this.loading,
    required this.onChanged,
  });

  final String emoji;
  final String label;
  final String time;
  final bool value;
  final bool loading;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Text(emoji, style: const TextStyle(fontSize: 22)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(time,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              )),
      value: value,
      onChanged: loading ? null : onChanged,
    );
  }
}
```

- [ ] **Step 3: Add the import for notifications at the top of `settings_screen.dart`**

Add after the existing imports in `settings_screen.dart`:

```dart
import '../../utils/notifications.dart';
```

- [ ] **Step 4: Run static analysis**

```bash
flutter analyze lib/features/settings/settings_screen.dart
```

Expected: No errors.

- [ ] **Step 5: Run full test suite**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/settings_screen.dart
git commit -m "feat: add Reminders section to Settings screen with meal reminder toggles"
```

---

## Task 6: Final analysis and cleanup

**Files:**
- No new files

- [ ] **Step 1: Run full static analysis**

```bash
flutter analyze
```

Expected: Zero errors, zero warnings.

- [ ] **Step 2: Format check**

```bash
dart format lib/ test/ --set-exit-if-changed
```

Expected: Exit code 0 (no formatting changes needed). If files are reformatted, stage and amend:

```bash
dart format lib/ test/
git add -p
git commit -m "style: format notifications code"
```

- [ ] **Step 3: Run all tests**

```bash
flutter test
```

Expected: All tests pass, including the 3 new reminder state tests.

- [ ] **Step 4: Final commit**

```bash
git add .
git commit -m "feat: Phase 13 complete — meal reminder push notifications"
```
