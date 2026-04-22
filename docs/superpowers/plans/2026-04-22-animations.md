# Animations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add subtle, polished route transitions and tab crossfade to the Cal AI Flutter app.

**Architecture:** Three `CustomTransitionPage` helper functions in `router.dart` replace all plain `builder:` entries (slide-right for onboarding, slide-up+fade for log modals, fade for shell tabs). `ScaffoldWithNavBar` wraps its `child` in an `AnimatedSwitcher` keyed on the current tab path for a 200ms fade when switching tabs.

**Tech Stack:** Flutter built-ins — `CustomTransitionPage`, `SlideTransition`, `FadeTransition`, `AnimatedSwitcher`, `KeyedSubtree`. No new dependencies.

---

## Files

| File | Change |
|---|---|
| `lib/router.dart` | Add `_slidePage`, `_slideUpPage`, `_fadePage` helpers; switch all `builder:` to `pageBuilder:` |
| `lib/widgets/scaffold_with_nav_bar.dart` | Wrap `child` in `AnimatedSwitcher` + `KeyedSubtree` |

---

## Task 1: Add transition helper functions to router.dart

**Files:**
- Modify: `lib/router.dart`

> Animation helpers are purely visual — no unit test applies. Verification is `flutter analyze` + manual run.

- [ ] **Step 1: Add three helper functions at the bottom of `lib/router.dart`**

Append after the closing `}` of `buildRouter()`:

```dart
CustomTransitionPage<void> _slidePage(Widget child) =>
    CustomTransitionPage<void>(
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: child,
          ),
    );

CustomTransitionPage<void> _slideUpPage(Widget child) =>
    CustomTransitionPage<void>(
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.fastOutSlowIn,
                ),
              ),
              child: child,
            ),
          ),
    );

CustomTransitionPage<void> _fadePage(Widget child) =>
    CustomTransitionPage<void>(
      child: child,
      transitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeIn,
            ),
            child: child,
          ),
    );
```

- [ ] **Step 2: Run `flutter analyze` to confirm no errors**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/router.dart
git commit -m "feat: add route transition helpers (slide, slideUp, fade)"
```

---

## Task 2: Switch all GoRoute entries to pageBuilder

**Files:**
- Modify: `lib/router.dart`

Replace every `builder: (context, state) => const SomeScreen()` with `pageBuilder: (context, state) => _helperFn(const SomeScreen())` according to the table below.

- [ ] **Step 1: Update all onboarding routes to use `_slidePage`**

Replace the 10 onboarding `GoRoute` entries so they read:

```dart
GoRoute(
  path: '/onboarding/goal',
  pageBuilder: (context, state) => _slidePage(const GoalScreen()),
),
GoRoute(
  path: '/onboarding/gender',
  pageBuilder: (context, state) => _slidePage(const GenderScreen()),
),
GoRoute(
  path: '/onboarding/birthday',
  pageBuilder: (context, state) => _slidePage(const BirthdayScreen()),
),
GoRoute(
  path: '/onboarding/current-weight',
  pageBuilder: (context, state) => _slidePage(const CurrentWeightScreen()),
),
GoRoute(
  path: '/onboarding/height',
  pageBuilder: (context, state) => _slidePage(const HeightScreen()),
),
GoRoute(
  path: '/onboarding/target-weight',
  pageBuilder: (context, state) => _slidePage(const TargetWeightScreen()),
),
GoRoute(
  path: '/onboarding/activity',
  pageBuilder: (context, state) => _slidePage(const ActivityScreen()),
),
GoRoute(
  path: '/onboarding/diet',
  pageBuilder: (context, state) => _slidePage(const DietScreen()),
),
GoRoute(
  path: '/onboarding/results',
  pageBuilder: (context, state) => _slidePage(const ResultsScreen()),
),
GoRoute(
  path: '/onboarding/plan',
  pageBuilder: (context, state) => _slidePage(const PlanScreen()),
),
```

- [ ] **Step 2: Update all log routes to use `_slideUpPage`**

```dart
GoRoute(
  path: '/log/camera',
  pageBuilder: (context, state) => _slideUpPage(const CameraScreen()),
),
GoRoute(
  path: '/log/scan-result',
  pageBuilder: (context, state) =>
      _slideUpPage(ScanResultScreen(photoPath: state.extra as String)),
),
GoRoute(
  path: '/log/search',
  pageBuilder: (context, state) => _slideUpPage(const SearchScreen()),
),
GoRoute(
  path: '/log/exercise',
  pageBuilder: (context, state) => _slideUpPage(const ExerciseScreen()),
),
GoRoute(
  path: '/log/water',
  pageBuilder: (context, state) => _slideUpPage(const WaterScreen()),
),
```

- [ ] **Step 3: Update shell tab routes inside ShellRoute to use `_fadePage`**

```dart
ShellRoute(
  builder: (context, state, child) => ScaffoldWithNavBar(child: child),
  routes: [
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => _fadePage(const HomeScreen()),
    ),
    GoRoute(
      path: '/analytics',
      pageBuilder: (context, state) => _fadePage(const AnalyticsScreen()),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => _fadePage(const SettingsScreen()),
    ),
  ],
),
```

- [ ] **Step 4: Run `flutter analyze`**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 5: Run the smoke test**

```bash
flutter test test/widget_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/router.dart
git commit -m "feat: wire route transitions (onboarding slide, log slideUp, tabs fade)"
```

---

## Task 3: Add AnimatedSwitcher tab crossfade to ScaffoldWithNavBar

**Files:**
- Modify: `lib/widgets/scaffold_with_nav_bar.dart`

- [ ] **Step 1: Wrap `child` in `AnimatedSwitcher` + `KeyedSubtree`**

In the `build` method of `ScaffoldWithNavBar`, replace:

```dart
body: child,
```

with:

```dart
body: AnimatedSwitcher(
  duration: const Duration(milliseconds: 200),
  child: KeyedSubtree(
    key: ValueKey(GoRouterState.of(context).uri.path),
    child: child,
  ),
),
```

`ValueKey` on the tab path triggers the fade only when the tab changes. Log modal pushes over the shell don't change the shell's rebuild context, so they are unaffected.

- [ ] **Step 2: Run `flutter analyze`**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Run all tests**

```bash
flutter test
```

Expected: `All tests passed!`

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/scaffold_with_nav_bar.dart
git commit -m "feat: crossfade tab content on switch via AnimatedSwitcher"
```

---

## Task 4: Format and final verification

- [ ] **Step 1: Format**

```bash
dart format lib/ test/ --set-exit-if-changed
```

Expected: exit 0 (no formatting changes, since we matched project style). If any files are reformatted, stage and amend the previous commit or add a new format commit.

- [ ] **Step 2: Full test run**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 3: Analyze**

```bash
flutter analyze
```

Expected: `No issues found!`
