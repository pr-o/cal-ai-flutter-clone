# Push Notifications (Meal Reminders) — Design Spec

**Date:** 2026-04-05  
**Phase:** 13  
**Status:** Approved

---

## Overview

Add optional daily meal reminder notifications (breakfast, lunch, dinner) to the Cal AI Flutter clone. Users toggle each reminder on/off in the Settings screen. All scheduling uses `flutter_local_notifications` built-in APIs only — no `permission_handler` package.

---

## Architecture

### `lib/utils/notifications.dart`

Plain Dart file with a `FlutterLocalNotificationsPlugin` singleton and three exported functions:

```dart
Future<void> initNotifications()
Future<void> scheduleMealReminder(int id, int hour, int minute, String label)
Future<void> cancelReminder(int id)
```

**Fixed notification IDs:**
| Meal      | ID |
|-----------|----|
| Breakfast | 0  |
| Lunch     | 1  |
| Dinner    | 2  |

**`initNotifications()`**
- Initializes the plugin with `AndroidInitializationSettings` and `DarwinInitializationSettings`
- Requests iOS permission via `requestPermission(alert: true, badge: true, sound: true)`
- Creates Android notification channel `meal_reminders` with importance `High`

**`scheduleMealReminder(id, hour, minute, label)`**
- Cancels any existing notification with the same ID first
- Schedules a daily repeating notification using `zonedSchedule` with `RepeatInterval` via `TZDateTime` set to the next occurrence of `hour:minute` in local timezone
- Uses `flutter_timezone` + `timezone` packages to resolve local `TZDateTime`

**`cancelReminder(id)`**
- Calls `plugin.cancel(id)`

---

## State & Persistence

### `SettingsState` additions

```dart
final bool reminderBreakfast;  // default: false
final bool reminderLunch;      // default: false
final bool reminderDinner;     // default: false
```

### `SettingsNotifier` additions

```dart
Future<void> setReminder(String meal, bool enabled)
```

- Writes `reminder_<meal>` bool to `SharedPreferences`
- If `enabled`: calls `scheduleMealReminder` with the meal's fixed ID, time, and label
- If `!enabled`: calls `cancelReminder` with the meal's fixed ID
- Updates state via `copyWith`

**Hydration:** `_hydrate()` reads all 3 reminder bools from SharedPreferences on startup. It does **not** reschedule — `flutter_local_notifications` persists scheduled alarms natively across app restarts.

---

## Platform Configuration

### Android (`android/app/src/main/AndroidManifest.xml`)

Add permissions:
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

Add receiver/service entries inside `<application>` as required by `flutter_local_notifications` for exact alarms and boot persistence.

### iOS (`ios/Runner/Info.plist`)

No changes needed. Permission is requested at runtime via `initNotifications()`.

---

## New Dependencies (`pubspec.yaml`)

```yaml
flutter_timezone: ^3.0.0
timezone: ^0.9.0
```

`flutter_local_notifications: ^19.0.0` is already present.

---

## Settings UI

New **Reminders** section added to `settings_screen.dart` between the Weight Unit tile and API Keys section.

```
─── Reminders ──────────────────────────────────
  🌅  Breakfast reminder   [switch]   8:00 AM
  ☀️   Lunch reminder       [switch]  12:00 PM
  🌙  Dinner reminder      [switch]   7:00 PM
────────────────────────────────────────────────
```

- Each row: `SwitchListTile` with meal emoji + name (title), time (subtitle)
- Toggle calls `ref.read(settingsProvider.notifier).setReminder(meal, value)`
- On first toggle-on, `initNotifications()` is called before scheduling (triggers iOS permission dialog at opt-in moment, not app launch)
- Switch is briefly disabled (`_loading` bool per tile) during async `setReminder` to prevent double-taps

---

## `main.dart` change

Remove any `initNotifications()` call from app startup — permission is requested lazily on first toggle-on in Settings.

---

## Meal Reminder Schedule

| Meal      | Hour | Minute | Label               |
|-----------|------|--------|---------------------|
| Breakfast | 8    | 0      | "Breakfast reminder"|
| Lunch     | 12   | 0      | "Lunch reminder"    |
| Dinner    | 19   | 0      | "Dinner reminder"   |

---

## Out of Scope

- Custom reminder times (fixed times only)
- Snooze / action buttons on notifications
- Notification history or logs
- Re-scheduling on boot (handled natively by the plugin)
