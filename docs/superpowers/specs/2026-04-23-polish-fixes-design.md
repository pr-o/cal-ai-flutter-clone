# Polish Fixes Design

**Date:** 2026-04-23
**Scope:** Three small, independent UX polish fixes — hide dead back button, add weight-logging shortcut on Home, add haptic feedback on primary CTAs.

---

## Fix 1: Hide back button on GoalScreen

**Problem:** `OnboardingLayout`'s back button renders on every onboarding screen, including `GoalScreen` (the first one). Its default handler is `if (context.canPop()) context.pop()`, which is a no-op on screen 1 — so the button invites a tap and does nothing.

**Fix:**
- Add `hideBack: bool = false` prop to `OnboardingLayout`.
- When `hideBack: true`, render a `SizedBox(width: 40, height: 40)` in the back button's slot so the `LinearProgressIndicator` alignment is preserved (the balancing `SizedBox(width: 48)` at the end of the Row already handles symmetry; the 40-wide placeholder + the existing 8 spacer + 48 balancer keeps the progress bar centered).
- `GoalScreen` passes `hideBack: true` and removes the now-redundant `onBack: null`.

**Files:**
- `lib/widgets/onboarding_layout.dart` — new prop, conditional render
- `lib/features/onboarding/screens/goal_screen.dart` — pass `hideBack: true`, drop `onBack: null`

---

## Fix 2: Weight-logging shortcut on Home FAB

**Problem:** Logging weight is a daily action but requires tabbing to Analytics. Adds friction.

**Fix:** Extract the existing `_showLogWeightSheet` helper from `analytics_screen.dart` into a shared function, and add a 5th tile to Home's FAB bottom sheet that invokes it.

**Shared helper:**
```dart
// lib/widgets/log_weight_sheet.dart
void showLogWeightSheet(BuildContext context, WidgetRef ref);
```

The function signature takes `WidgetRef` so callers can pass their own scope. The helper reads `analyticsProvider.notifier.logWeight(kg)` — this provider is global and works from any screen.

**Home FAB sheet:** Add a 5th `ListTile` after "Log water":
- `leading: Icon(Icons.monitor_weight_outlined)`
- `title: Text('Log weight')`
- `onTap`: pop the bottom sheet, then call `showLogWeightSheet(context, ref)`.

**Analytics:** Replace the inline `_showLogWeightSheet(context, ref)` call site with `showLogWeightSheet(context, ref)`. Delete the now-unused private method.

**Files:**
- Create: `lib/widgets/log_weight_sheet.dart`
- Modify: `lib/features/analytics/analytics_screen.dart` (delete private method, update call site)
- Modify: `lib/features/home/home_screen.dart` (add 5th `ListTile`, convert `_showLogSheet` to accept `WidgetRef` since the tile needs it)

---

## Fix 3: Haptic feedback on primary CTAs

**Problem:** No tactile confirmation on any tap. Makes the app feel inert.

**Fix:** Add `HapticFeedback` calls inline in existing callbacks. No new widgets.

| Site | Feedback | Rationale |
|---|---|---|
| `OnboardingOptionPill.onTap` | `selectionClick` | Light, frequent |
| `OnboardingNextButton.onPressed` | `selectionClick` | Progression |
| Home FAB bottom-sheet `ListTile` taps (5×) | `selectionClick` | Menu selection |
| `CameraScreen` shutter button | `mediumImpact` | Commit action (photo capture) |
| `ScanResultScreen` "Done" button | `mediumImpact` | Commit (log food) |
| `SearchScreen` confirm-sheet "Add to log" | `mediumImpact` | Commit (log food) |

Import `package:flutter/services.dart` where missing. Each call is one line inside the existing `onPressed`/`onTap` callback.

**Not included:** Macro pills (display-only), week-strip day tiles (pure nav), log-sheet tiles inside Analytics FAB (covered by the shared helper — add inside `showLogWeightSheet` "Save" button, same `mediumImpact` tier).

**Files:**
- `lib/features/onboarding/screens/onboarding_widgets.dart` — `OnboardingOptionPill`, `OnboardingNextButton`
- `lib/features/home/home_screen.dart` — 5× tile taps
- `lib/features/log/camera_screen.dart` — shutter
- `lib/features/log/scan_result_screen.dart` — "Done"
- `lib/features/log/search_screen.dart` — "Add to log"
- `lib/widgets/log_weight_sheet.dart` — "Save" button (new file, fold into its creation)

---

## Out of Scope

- Direction-aware back-navigation animation (back currently slides right like forward — separate feature)
- Reminders device testing (physical device only)
- Animating the FAB sheet entry (already handled by default `showModalBottomSheet`)
- Theming for haptics (iOS/Android both support the APIs used; no-op on platforms that don't)

---

## Testing

- `flutter analyze` — zero issues
- `flutter test` — all existing tests pass (no new tests; haptics and visual fixes aren't unit-testable)
- Manual: on-device verification that haptics fire and GoalScreen has no back button
