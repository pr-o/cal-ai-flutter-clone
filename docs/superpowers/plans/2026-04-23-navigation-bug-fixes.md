# Navigation Bug Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix two navigation bugs — broken onboarding back button and unsafe `state.extra` cast on the scan-result route.

**Architecture:** Fix 1 changes all 9 onboarding "Next" calls from `context.go()` to `context.push()` so the Navigator stack is built up and `context.pop()` can unwind it; `OnboardingLayout`'s default back handler is updated to use `context.canPop() ? context.pop() : null`. Fix 2 guards the `/log/scan-result` route's `state.extra` cast against null with `as String? ?? ''`.

**Tech Stack:** Flutter, `go_router` (`context.push`, `context.pop`, `context.canPop`)

---

## Files

| File | Change |
|---|---|
| `lib/widgets/onboarding_layout.dart` | Default back handler: `Navigator.pop` → `context.canPop() ? context.pop() : null`; add `go_router` import |
| `lib/features/onboarding/screens/goal_screen.dart` | `context.go` → `context.push` |
| `lib/features/onboarding/screens/gender_screen.dart` | `context.go` → `context.push` |
| `lib/features/onboarding/screens/birthday_screen.dart` | `context.go` → `context.push` |
| `lib/features/onboarding/screens/current_weight_screen.dart` | `context.go` → `context.push` |
| `lib/features/onboarding/screens/height_screen.dart` | `context.go` → `context.push` |
| `lib/features/onboarding/screens/target_weight_screen.dart` | `context.go` → `context.push` |
| `lib/features/onboarding/screens/activity_screen.dart` | `context.go` → `context.push` |
| `lib/features/onboarding/screens/diet_screen.dart` | `context.go` → `context.push` |
| `lib/features/onboarding/screens/results_screen.dart` | `context.go` → `context.push` |
| `lib/router.dart` | `state.extra as String` → `state.extra as String? ?? ''` |

`plan_screen.dart` is **not** changed — its `context.go('/home')` correctly ends onboarding.

---

## Task 1: Fix OnboardingLayout default back handler

**Files:**
- Modify: `lib/widgets/onboarding_layout.dart`

> Navigation flow is visual — no unit test applies. Verification is `flutter analyze` + `flutter test`.

- [ ] **Step 1: Add `go_router` import and fix the default back handler**

In `lib/widgets/onboarding_layout.dart`, add the import and update line 39:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
```

Change line 39 from:
```dart
onBack: onBack ?? () => Navigator.of(context).pop(),
```
to:
```dart
onBack: onBack ?? () { if (context.canPop()) context.pop(); },
```

- [ ] **Step 2: Run `flutter analyze`**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Run tests**

```bash
flutter test
```

Expected: `+50: All tests passed!`

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/onboarding_layout.dart
git commit -m "fix: use context.canPop/pop in OnboardingLayout back handler"
```

---

## Task 2: Change all onboarding Next buttons from context.go to context.push

**Files:**
- Modify: all 9 onboarding screen files listed below

Each file has exactly one `context.go('/onboarding/...')` call inside its "Next" button handler. Change each to `context.push(...)` with the same path.

- [ ] **Step 1: Update `goal_screen.dart`**

`lib/features/onboarding/screens/goal_screen.dart` — change:
```dart
onPressed: () => context.go('/onboarding/gender'),
```
to:
```dart
onPressed: () => context.push('/onboarding/gender'),
```

- [ ] **Step 2: Update `gender_screen.dart`**

`lib/features/onboarding/screens/gender_screen.dart` — change:
```dart
onPressed: () => context.go('/onboarding/birthday'),
```
to:
```dart
onPressed: () => context.push('/onboarding/birthday'),
```

- [ ] **Step 3: Update `birthday_screen.dart`**

`lib/features/onboarding/screens/birthday_screen.dart` — change:
```dart
onPressed: () => context.go('/onboarding/current-weight'),
```
to:
```dart
onPressed: () => context.push('/onboarding/current-weight'),
```

- [ ] **Step 4: Update `current_weight_screen.dart`**

`lib/features/onboarding/screens/current_weight_screen.dart` — change:
```dart
onPressed: () => context.go('/onboarding/height'),
```
to:
```dart
onPressed: () => context.push('/onboarding/height'),
```

- [ ] **Step 5: Update `height_screen.dart`**

`lib/features/onboarding/screens/height_screen.dart` — change:
```dart
onPressed: () => context.go('/onboarding/target-weight'),
```
to:
```dart
onPressed: () => context.push('/onboarding/target-weight'),
```

- [ ] **Step 6: Update `target_weight_screen.dart`**

`lib/features/onboarding/screens/target_weight_screen.dart` — change:
```dart
onPressed: () => context.go('/onboarding/activity'),
```
to:
```dart
onPressed: () => context.push('/onboarding/activity'),
```

- [ ] **Step 7: Update `activity_screen.dart`**

`lib/features/onboarding/screens/activity_screen.dart` — change:
```dart
onPressed: () => context.go('/onboarding/diet'),
```
to:
```dart
onPressed: () => context.push('/onboarding/diet'),
```

- [ ] **Step 8: Update `diet_screen.dart`**

`lib/features/onboarding/screens/diet_screen.dart` — change:
```dart
onPressed: () => context.go('/onboarding/results'),
```
to:
```dart
onPressed: () => context.push('/onboarding/results'),
```

- [ ] **Step 9: Update `results_screen.dart`**

`lib/features/onboarding/screens/results_screen.dart` — change:
```dart
onPressed: () => context.go('/onboarding/plan'),
```
to:
```dart
onPressed: () => context.push('/onboarding/plan'),
```

- [ ] **Step 10: Run `flutter analyze`**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 11: Run tests**

```bash
flutter test
```

Expected: `+50: All tests passed!`

- [ ] **Step 12: Commit**

```bash
git add \
  lib/features/onboarding/screens/goal_screen.dart \
  lib/features/onboarding/screens/gender_screen.dart \
  lib/features/onboarding/screens/birthday_screen.dart \
  lib/features/onboarding/screens/current_weight_screen.dart \
  lib/features/onboarding/screens/height_screen.dart \
  lib/features/onboarding/screens/target_weight_screen.dart \
  lib/features/onboarding/screens/activity_screen.dart \
  lib/features/onboarding/screens/diet_screen.dart \
  lib/features/onboarding/screens/results_screen.dart
git commit -m "fix: use context.push for onboarding Next buttons so back navigation works"
```

---

## Task 3: Guard state.extra cast in scan-result route

**Files:**
- Modify: `lib/router.dart`

- [ ] **Step 1: Fix the unsafe cast**

In `lib/router.dart`, find the `/log/scan-result` pageBuilder (around line 90):

```dart
pageBuilder: (context, state) => _slideUpPage(
  state.pageKey,
  ScanResultScreen(photoPath: state.extra as String),
),
```

Change to:
```dart
pageBuilder: (context, state) => _slideUpPage(
  state.pageKey,
  ScanResultScreen(photoPath: state.extra as String? ?? ''),
),
```

- [ ] **Step 2: Run `flutter analyze`**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Run tests**

```bash
flutter test
```

Expected: `+50: All tests passed!`

- [ ] **Step 4: Commit**

```bash
git add lib/router.dart
git commit -m "fix: guard state.extra null cast on scan-result route"
```

---

## Task 4: Format

- [ ] **Step 1: Format**

```bash
dart format lib/ test/ --set-exit-if-changed
```

Expected: exit 0. If files were reformatted, commit:
```bash
git add -u && git commit -m "style: dart format"
```
