# Navigation Bug Fixes Design

**Date:** 2026-04-23  
**Scope:** Two targeted bug fixes — onboarding back navigation and unsafe route extra cast

---

## Fix 1: Onboarding Back Navigation

**Problem:** All onboarding "Next" buttons use `context.go()`, which replaces the entire GoRouter stack. `OnboardingLayout`'s default back handler calls `Navigator.of(context).pop()`, but there is nothing on the stack to pop, so the back button is silently broken on all screens.

**Fix:**
- Change all 9 `context.go('/onboarding/...')` calls in Next buttons to `context.push('/onboarding/...')` — push adds to the stack so `pop()` can unwind it
- Change `OnboardingLayout` default back handler from `Navigator.of(context).pop()` to `context.canPop() ? context.pop() : null` — on the first screen (goal) there is no previous screen, so the button becomes a graceful no-op

**Files:**
- `lib/widgets/onboarding_layout.dart` — fix default back handler, add `go_router` import
- `lib/features/onboarding/screens/goal_screen.dart` — `context.go` → `context.push`
- `lib/features/onboarding/screens/gender_screen.dart` — same
- `lib/features/onboarding/screens/birthday_screen.dart` — same
- `lib/features/onboarding/screens/current_weight_screen.dart` — same
- `lib/features/onboarding/screens/height_screen.dart` — same
- `lib/features/onboarding/screens/target_weight_screen.dart` — same
- `lib/features/onboarding/screens/activity_screen.dart` — same
- `lib/features/onboarding/screens/diet_screen.dart` — same
- `lib/features/onboarding/screens/results_screen.dart` — same

`plan_screen.dart` is excluded — it ends onboarding with `context.go('/home')` which is correct.

---

## Fix 2: Unsafe `state.extra` Cast

**Problem:** In `lib/router.dart`, the `/log/scan-result` route does `state.extra as String`. If the route is ever reached without `extra` set (deep link, hot restart, developer error), this throws a `TypeError` with no recovery.

**Fix:** Change to `state.extra as String? ?? ''`. An empty string passed to `ScanResultScreen` means the image won't load, but the screen renders without crashing.

**File:** `lib/router.dart` — one character change on one line

---

## Out of Scope

- Changing the onboarding progress bar behavior on back (it already uses `step/totalSteps` which is correct per screen)
- Adding back-navigation tests (visual flow, not unit-testable)
