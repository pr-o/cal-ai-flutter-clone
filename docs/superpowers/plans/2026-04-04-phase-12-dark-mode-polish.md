# Phase 12 — Dark Mode Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate all hardcoded black/white colors across screens and widgets so the app renders correctly in both light and dark mode.

**Architecture:** Three categories of change — (1) fix the global `filledButtonTheme` in `app_theme.dart` so all FilledButtons adapt automatically, then (2) remove the now-redundant per-widget color overrides, and (3) fix FABs and chart colors that don't inherit from FilledButtonTheme. Brand/macro colors (`#FF5500`, `#FF6B35`, `#FFB800`, `#4A9EFF`) and camera-screen overlays are intentionally theme-fixed and must NOT be changed.

**Tech Stack:** Flutter `ThemeData`, `ColorScheme`, `SystemChrome`, `fl_chart`.

---

## File Map

| File | Change |
|---|---|
| `lib/theme/app_theme.dart` | Use `colorScheme.onSurface`/`colorScheme.surface` in filledButtonTheme + bottomNav |
| `lib/main.dart` | Add `AnnotatedRegion<SystemUiOverlayStyle>` for status/nav bar icons |
| `lib/widgets/onboarding_layout.dart` | Replace `AppColors.pillUnselected`/`AppColors.black` with `colorScheme` tokens |
| `lib/features/home/home_screen.dart` | Fix FAB colors + sheet drag handle |
| `lib/features/analytics/analytics_screen.dart` | Fix FAB colors + FilledButton override + LineChart line color |
| `lib/features/onboarding/screens/results_screen.dart` | Fix LineChart `Colors.black` line |
| `lib/features/log/exercise_screen.dart` | Remove FilledButton color override |
| `lib/features/log/water_screen.dart` | Remove FilledButton color override |
| `lib/features/log/search_screen.dart` | Remove FilledButton color override |
| `lib/features/log/scan_result_screen.dart` | Remove FilledButton color override |
| `lib/features/settings/settings_screen.dart` | Remove FilledButton color overrides |
| `lib/features/onboarding/screens/onboarding_widgets.dart` | Remove FilledButton color override |
| `lib/features/onboarding/screens/plan_screen.dart` | Remove FilledButton color override |
| `CLAUDE.md` | Mark Phase 12 complete |

---

### Task 1: Fix global FilledButton + BottomNav theme in app_theme.dart

**Files:**
- Modify: `lib/theme/app_theme.dart`

- [ ] **Step 1.1: Update `_base()` to use `colorScheme` in filledButtonTheme and bottomNavigationBarTheme**

Replace `lib/theme/app_theme.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  // Backgrounds
  static const bgPrimaryLight = Color(0xFFFFFFFF);
  static const bgSecondaryLight = Color(0xFFF5F5F5);
  static const bgPrimaryDark = Color(0xFF111111);
  static const bgSecondaryDark = Color(0xFF1E1E1E);

  // Accent
  static const accentOrange = Color(0xFFFF5500);

  // Macros
  static const macroProtein = Color(0xFFFF6B35);
  static const macroCarbs = Color(0xFFFFB800);
  static const macroFat = Color(0xFF4A9EFF);

  // UI
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
  static const pillUnselected = Color(0xFFF0F0F0);
  static const pillUnselectedDark = Color(0xFF2A2A2A);
}

ThemeData _base(ColorScheme colorScheme) {
  final textTheme = GoogleFonts.interTextTheme(
    ThemeData(brightness: colorScheme.brightness).textTheme,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      titleTextStyle: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.onSurface,
        foregroundColor: colorScheme.surface,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        side: BorderSide(color: colorScheme.outline),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.onSurface,
      unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.4),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.onSurface.withValues(alpha: 0.08),
      space: 1,
      thickness: 1,
    ),
  );
}

final lightTheme = _base(
  const ColorScheme.light(
    surface: AppColors.bgPrimaryLight,
    onSurface: AppColors.black,
    surfaceContainerHighest: AppColors.bgSecondaryLight,
    primary: AppColors.black,
    onPrimary: AppColors.white,
    outline: Color(0xFFE0E0E0),
  ),
);

final darkTheme = _base(
  const ColorScheme.dark(
    surface: AppColors.bgPrimaryDark,
    onSurface: AppColors.white,
    surfaceContainerHighest: AppColors.bgSecondaryDark,
    primary: AppColors.white,
    onPrimary: AppColors.black,
    outline: Color(0xFF333333),
  ),
);
```

- [ ] **Step 1.2: Run analyze**

```bash
flutter analyze lib/theme/app_theme.dart
```

Expected: `No issues found!`

- [ ] **Step 1.3: Run tests**

```bash
flutter test
```

Expected: `All tests passed!`

- [ ] **Step 1.4: Commit**

```bash
git add lib/theme/app_theme.dart
git commit -m "fix: use colorScheme in filledButtonTheme and bottomNav for dark mode"
```

---

### Task 2: Fix onboarding_layout.dart hardcoded colors

**Files:**
- Modify: `lib/widgets/onboarding_layout.dart`

- [ ] **Step 2.1: Replace hardcoded `AppColors` with `Theme.of(context).colorScheme` tokens**

Replace `lib/widgets/onboarding_layout.dart` with:

```dart
import 'package:flutter/material.dart';

/// Wraps onboarding screen content with a back arrow, thin progress bar,
/// and safe-area padding matching the Cal AI onboarding design.
class OnboardingLayout extends StatelessWidget {
  const OnboardingLayout({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.child,
    this.onBack,
  });

  /// Current step index (1-based).
  final int step;
  final int totalSteps;
  final Widget child;

  /// Override back behaviour; defaults to [Navigator.pop].
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final progress = step / totalSteps;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header: back button + progress bar ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  _BackButton(onBack: onBack ?? () => Navigator.of(context).pop()),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(cs.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // balance the back button
                ],
              ),
            ),
            // ── Content ─────────────────────────────────────────────────────
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onBack,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.arrow_back, size: 20, color: cs.onSurface),
      ),
    );
  }
}
```

- [ ] **Step 2.2: Run analyze**

```bash
flutter analyze lib/widgets/onboarding_layout.dart
```

Expected: `No issues found!`

- [ ] **Step 2.3: Run tests**

```bash
flutter test
```

Expected: `All tests passed!`

- [ ] **Step 2.4: Commit**

```bash
git add lib/widgets/onboarding_layout.dart
git commit -m "fix: use colorScheme tokens in OnboardingLayout for dark mode"
```

---

### Task 3: Fix FABs in home + analytics + drag handle

**Files:**
- Modify: `lib/features/home/home_screen.dart`
- Modify: `lib/features/analytics/analytics_screen.dart`

- [ ] **Step 3.1: Fix FAB and drag handle in home_screen.dart**

In `lib/features/home/home_screen.dart`, make these two changes:

**Change 1** — FAB (find `floatingActionButton: FloatingActionButton(`):
```dart
// BEFORE:
floatingActionButton: FloatingActionButton(
  onPressed: () => _showLogSheet(context),
  backgroundColor: Colors.black,
  foregroundColor: Colors.white,
  child: const Icon(Icons.add_rounded, size: 28),
),

// AFTER:
floatingActionButton: FloatingActionButton(
  onPressed: () => _showLogSheet(context),
  backgroundColor: Theme.of(context).colorScheme.onSurface,
  foregroundColor: Theme.of(context).colorScheme.surface,
  child: const Icon(Icons.add_rounded, size: 28),
),
```

**Change 2** — Bottom sheet drag handle (find `color: Colors.grey.shade300`):
```dart
// BEFORE:
color: Colors.grey.shade300,

// AFTER:
color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.2),
```

- [ ] **Step 3.2: Fix FAB in analytics_screen.dart**

In `lib/features/analytics/analytics_screen.dart`, change the `FloatingActionButton.extended`:
```dart
// BEFORE:
floatingActionButton: FloatingActionButton.extended(
  onPressed: () => _showLogWeightSheet(context, ref),
  backgroundColor: Colors.black,
  foregroundColor: Colors.white,
  icon: const Icon(Icons.monitor_weight_outlined),
  label: const Text('Log Weight'),
),

// AFTER:
floatingActionButton: FloatingActionButton.extended(
  onPressed: () => _showLogWeightSheet(context, ref),
  backgroundColor: Theme.of(context).colorScheme.onSurface,
  foregroundColor: Theme.of(context).colorScheme.surface,
  icon: const Icon(Icons.monitor_weight_outlined),
  label: const Text('Log Weight'),
),
```

- [ ] **Step 3.3: Run analyze**

```bash
flutter analyze lib/features/home/home_screen.dart lib/features/analytics/analytics_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 3.4: Run tests**

```bash
flutter test
```

Expected: `All tests passed!`

- [ ] **Step 3.5: Commit**

```bash
git add lib/features/home/home_screen.dart lib/features/analytics/analytics_screen.dart
git commit -m "fix: use colorScheme for FABs and sheet drag handle"
```

---

### Task 4: Remove explicit FilledButton color overrides

Now that `app_theme.dart` provides correct colors for both themes, remove the redundant `backgroundColor: Colors.black` / `foregroundColor: Colors.white` overrides from FilledButton instances. Keep all `minimumSize`, `shape`, and other non-color properties.

**Files:**
- Modify: `lib/features/log/exercise_screen.dart`
- Modify: `lib/features/log/water_screen.dart`
- Modify: `lib/features/log/search_screen.dart`
- Modify: `lib/features/log/scan_result_screen.dart`
- Modify: `lib/features/analytics/analytics_screen.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `lib/features/onboarding/screens/onboarding_widgets.dart`
- Modify: `lib/features/onboarding/screens/plan_screen.dart`

- [ ] **Step 4.1: Fix `lib/features/log/exercise_screen.dart`**

```dart
// BEFORE:
style: FilledButton.styleFrom(
  backgroundColor: Colors.black,
  minimumSize: const Size.fromHeight(52),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  ),
),
child: _saving
    ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: Colors.white),
      )
    : const Text('Log Exercise',
        style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600)),

// AFTER:
style: FilledButton.styleFrom(
  minimumSize: const Size.fromHeight(52),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  ),
),
child: _saving
    ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
    : const Text('Log Exercise',
        style: TextStyle(fontWeight: FontWeight.w600)),
```

- [ ] **Step 4.2: Fix `lib/features/log/water_screen.dart`**

```dart
// BEFORE:
style: FilledButton.styleFrom(
  backgroundColor: Colors.black,
  minimumSize: const Size(80, 52),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
),
child: const Text('Add',
    style: TextStyle(color: Colors.white)),

// AFTER:
style: FilledButton.styleFrom(
  minimumSize: const Size(80, 52),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
),
child: const Text('Add'),
```

- [ ] **Step 4.3: Fix `lib/features/log/search_screen.dart`**

```dart
// BEFORE:
style: FilledButton.styleFrom(
  backgroundColor: Colors.black,
  minimumSize: const Size.fromHeight(52),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  ),
),
child: const Text('Add to log',
    style: TextStyle(
        color: Colors.white, fontWeight: FontWeight.w600)),

// AFTER:
style: FilledButton.styleFrom(
  minimumSize: const Size.fromHeight(52),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  ),
),
child: const Text('Add to log',
    style: TextStyle(fontWeight: FontWeight.w600)),
```

- [ ] **Step 4.4: Fix `lib/features/log/scan_result_screen.dart`**

```dart
// BEFORE:
style: FilledButton.styleFrom(
  backgroundColor: Colors.black,
  minimumSize: const Size.fromHeight(50),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  ),
),
child: const Text('Done',
    style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600)),

// AFTER:
style: FilledButton.styleFrom(
  minimumSize: const Size.fromHeight(50),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  ),
),
child: const Text('Done',
    style: TextStyle(fontWeight: FontWeight.w600)),
```

- [ ] **Step 4.5: Fix `lib/features/analytics/analytics_screen.dart` log weight sheet FilledButton**

```dart
// BEFORE:
style: FilledButton.styleFrom(
  backgroundColor: Colors.black,
  minimumSize: const Size.fromHeight(52),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
),
child: const Text('Save',
    style: TextStyle(
        color: Colors.white, fontWeight: FontWeight.w600)),

// AFTER:
style: FilledButton.styleFrom(
  minimumSize: const Size.fromHeight(52),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
),
child: const Text('Save',
    style: TextStyle(fontWeight: FontWeight.w600)),
```

- [ ] **Step 4.6: Fix `lib/features/settings/settings_screen.dart`**

Two FilledButtons to fix.

**API key Save button** (in `_ApiKeyFieldState.build()`):
```dart
// BEFORE:
FilledButton(
  onPressed: widget.onSave,
  style: FilledButton.styleFrom(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
  child: const Text('Save'),
),

// AFTER:
FilledButton(
  onPressed: widget.onSave,
  style: FilledButton.styleFrom(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
  child: const Text('Save'),
),
```

**Edit Goals Save button** (in `_EditGoalsSheetState.build()`):
```dart
// BEFORE:
FilledButton(
  onPressed: _save,
  style: FilledButton.styleFrom(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(52),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
  ),
  child: const Text('Save Goals'),
),

// AFTER:
FilledButton(
  onPressed: _save,
  style: FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(52),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
  ),
  child: const Text('Save Goals'),
),
```

- [ ] **Step 4.7: Fix `lib/features/onboarding/screens/onboarding_widgets.dart`**

```dart
// BEFORE:
style: FilledButton.styleFrom(
  backgroundColor: Colors.black,
  foregroundColor: Colors.white,
  minimumSize: const Size.fromHeight(56),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(30),
  ),
),

// AFTER:
style: FilledButton.styleFrom(
  minimumSize: const Size.fromHeight(56),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(30),
  ),
),
```

- [ ] **Step 4.8: Fix `lib/features/onboarding/screens/plan_screen.dart`**

```dart
// BEFORE:
style: FilledButton.styleFrom(
  backgroundColor: Colors.black,
  foregroundColor: Colors.white,
  minimumSize: const Size.fromHeight(56),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(30),
  ),
),
child: _saving
    ? const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: Colors.white),
      )
    : const Text('Let\'s get started!',
        style: TextStyle(fontWeight: FontWeight.w600)),

// AFTER:
style: FilledButton.styleFrom(
  minimumSize: const Size.fromHeight(56),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(30),
  ),
),
child: _saving
    ? const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
    : const Text('Let\'s get started!',
        style: TextStyle(fontWeight: FontWeight.w600)),
```

- [ ] **Step 4.9: Run analyze on all changed files**

```bash
flutter analyze lib/features/log/exercise_screen.dart lib/features/log/water_screen.dart lib/features/log/search_screen.dart lib/features/log/scan_result_screen.dart lib/features/analytics/analytics_screen.dart lib/features/settings/settings_screen.dart lib/features/onboarding/screens/onboarding_widgets.dart lib/features/onboarding/screens/plan_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 4.10: Run tests**

```bash
flutter test
```

Expected: `All tests passed!`

- [ ] **Step 4.11: Commit**

```bash
git add lib/features/log/exercise_screen.dart lib/features/log/water_screen.dart lib/features/log/search_screen.dart lib/features/log/scan_result_screen.dart lib/features/analytics/analytics_screen.dart lib/features/settings/settings_screen.dart lib/features/onboarding/screens/onboarding_widgets.dart lib/features/onboarding/screens/plan_screen.dart
git commit -m "fix: remove hardcoded FilledButton color overrides, use global theme"
```

---

### Task 5: Fix chart Colors.black → colorScheme.onSurface

**Files:**
- Modify: `lib/features/analytics/analytics_screen.dart`
- Modify: `lib/features/onboarding/screens/results_screen.dart`

- [ ] **Step 5.1: Fix `_WeightChart` in analytics_screen.dart**

`_WeightChart` is a `StatelessWidget` with a `build(BuildContext context)` method. Locate the `lineBarsData` block and change:

```dart
// BEFORE:
LineChartBarData(
  spots: spots,
  isCurved: true,
  color: Colors.black,
  barWidth: 2.5,
  dotData: FlDotData(
    show: spots.length < 10,
  ),
  belowBarData: BarAreaData(
    show: true,
    color: Colors.black.withValues(alpha: 0.06),
  ),
),

// AFTER:
LineChartBarData(
  spots: spots,
  isCurved: true,
  color: Theme.of(context).colorScheme.onSurface,
  barWidth: 2.5,
  dotData: FlDotData(
    show: spots.length < 10,
  ),
  belowBarData: BarAreaData(
    show: true,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
  ),
),
```

- [ ] **Step 5.2: Fix `results_screen.dart` LineChart**

In `lib/features/onboarding/screens/results_screen.dart`, locate the Cal AI `LineChartBarData` with `color: Colors.black` and change:

```dart
// BEFORE:
LineChartBarData(
  spots: calAiSpots,
  isCurved: true,
  color: Colors.black,
  barWidth: 3,
  dotData: const FlDotData(show: false),
),

// AFTER:
LineChartBarData(
  spots: calAiSpots,
  isCurved: true,
  color: Theme.of(context).colorScheme.onSurface,
  barWidth: 3,
  dotData: const FlDotData(show: false),
),
```

Note: `results_screen.dart` builds this chart in a method that has `BuildContext context` available (check the parent build method signature — pass `context` down if it's in a sub-method).

- [ ] **Step 5.3: Run analyze**

```bash
flutter analyze lib/features/analytics/analytics_screen.dart lib/features/onboarding/screens/results_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 5.4: Run tests**

```bash
flutter test
```

Expected: `All tests passed!`

- [ ] **Step 5.5: Commit**

```bash
git add lib/features/analytics/analytics_screen.dart lib/features/onboarding/screens/results_screen.dart
git commit -m "fix: use colorScheme.onSurface for chart line colors"
```

---

### Task 6: Add SystemChrome overlay style + fix CircularProgressIndicator colors

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 6.1: Wrap MaterialApp with AnnotatedRegion for system UI overlay**

Replace `lib/main.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/home/notifier.dart';
import 'features/settings/notifier.dart';
import 'router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final router = await buildRouter();
  runApp(ProviderScope(child: CalAiApp(router: router)));
}

class CalAiApp extends ConsumerStatefulWidget {
  const CalAiApp({super.key, required this.router});
  final GoRouter router;

  @override
  ConsumerState<CalAiApp> createState() => _CalAiAppState();
}

class _CalAiAppState extends ConsumerState<CalAiApp> {
  @override
  void initState() {
    super.initState();
    ref.read(profileProvider);
    ref.read(dailyProvider);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));

    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            platformBrightness == Brightness.dark);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: MaterialApp.router(
        title: 'Cal AI',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        routerConfig: widget.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
```

- [ ] **Step 6.2: Run analyze**

```bash
flutter analyze lib/main.dart
```

Expected: `No issues found!`

- [ ] **Step 6.3: Run tests**

```bash
flutter test
```

Expected: `All tests passed!`

- [ ] **Step 6.4: Commit**

```bash
git add lib/main.dart
git commit -m "fix: add SystemChrome overlay style via AnnotatedRegion for status bar icons"
```

---

### Task 7: Dark mode widget tests + CLAUDE.md

**Files:**
- Create: `test/widgets/dark_mode_test.dart`
- Modify: `CLAUDE.md`

- [ ] **Step 7.1: Write dark mode rendering tests**

Create `test/widgets/dark_mode_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cal_ai_flutter_clone/features/home/notifier.dart';
import 'package:cal_ai_flutter_clone/widgets/calorie_ring.dart';
import 'package:cal_ai_flutter_clone/widgets/macro_pill.dart';
import 'package:cal_ai_flutter_clone/widgets/food_entry_card.dart';
import 'package:cal_ai_flutter_clone/widgets/week_strip.dart';
import 'package:cal_ai_flutter_clone/widgets/ruler_picker.dart';
import 'package:cal_ai_flutter_clone/widgets/onboarding_layout.dart';
import 'package:cal_ai_flutter_clone/theme/app_theme.dart';

Widget _dark(Widget child) => MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      home: Scaffold(body: child),
    );

Widget _light(Widget child) => MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('CalorieRing renders in dark mode without error', (tester) async {
    await tester.pumpWidget(
        _dark(const CalorieRing(consumed: 800, goal: 2000, size: 120)));
    await tester.pump();
    expect(find.byType(CalorieRing), findsOneWidget);
  });

  testWidgets('CalorieRing renders in light mode without error', (tester) async {
    await tester.pumpWidget(
        _light(const CalorieRing(consumed: 800, goal: 2000, size: 120)));
    await tester.pump();
    expect(find.byType(CalorieRing), findsOneWidget);
  });

  testWidgets('MacroPill renders in dark mode without error', (tester) async {
    await tester.pumpWidget(_dark(const MacroPill(
        type: MacroType.protein, remaining: 80, goal: 150)));
    await tester.pump();
    expect(find.byType(MacroPill), findsOneWidget);
  });

  testWidgets('MacroPill renders in light mode without error', (tester) async {
    await tester.pumpWidget(_light(const MacroPill(
        type: MacroType.protein, remaining: 80, goal: 150)));
    await tester.pump();
    expect(find.byType(MacroPill), findsOneWidget);
  });

  testWidgets('WeekStrip renders in dark mode without error', (tester) async {
    await tester.pumpWidget(_dark(WeekStrip(
      selectedDate: '2026-04-04',
      loggedDates: const {},
      onDaySelected: (_) {},
    )));
    await tester.pump();
    expect(find.byType(WeekStrip), findsOneWidget);
  });

  testWidgets('WeekStrip renders in light mode without error', (tester) async {
    await tester.pumpWidget(_light(WeekStrip(
      selectedDate: '2026-04-04',
      loggedDates: const {},
      onDaySelected: (_) {},
    )));
    await tester.pump();
    expect(find.byType(WeekStrip), findsOneWidget);
  });

  testWidgets('RulerPicker renders in dark mode without error', (tester) async {
    await tester.pumpWidget(_dark(RulerPicker(
      value: 70,
      min: 40,
      max: 200,
      step: 0.5,
      unit: 'kg',
      onChanged: (_) {},
    )));
    await tester.pump();
    expect(find.byType(RulerPicker), findsOneWidget);
  });

  testWidgets('RulerPicker renders in light mode without error', (tester) async {
    await tester.pumpWidget(_light(RulerPicker(
      value: 70,
      min: 40,
      max: 200,
      step: 0.5,
      unit: 'kg',
      onChanged: (_) {},
    )));
    await tester.pump();
    expect(find.byType(RulerPicker), findsOneWidget);
  });

  testWidgets('OnboardingLayout renders in dark mode without error',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      home: const OnboardingLayout(
        step: 3,
        totalSteps: 10,
        child: SizedBox(),
      ),
    ));
    await tester.pump();
    expect(find.byType(OnboardingLayout), findsOneWidget);
  });

  testWidgets('OnboardingLayout renders in light mode without error',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,
      home: const OnboardingLayout(
        step: 3,
        totalSteps: 10,
        child: SizedBox(),
      ),
    ));
    await tester.pump();
    expect(find.byType(OnboardingLayout), findsOneWidget);
  });

  testWidgets('FoodEntryCard renders in dark mode without error', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        profileProvider.overrideWith((ref) async => null),
      ],
      child: _dark(FoodEntryCard(
        entry: FoodEntry(
          id: 1,
          dailyLogId: 1,
          name: 'Chicken',
          calories: 300,
          proteinG: 30,
          carbsG: 0,
          fatG: 10,
          servings: 1,
          source: 'search',
          loggedAt: '2026-04-04T12:00:00',
        ),
        onDelete: () {},
      )),
    ));
    await tester.pump();
    expect(find.byType(FoodEntryCard), findsOneWidget);
  });
}
```

- [ ] **Step 7.2: Run tests to verify they pass**

```bash
flutter test test/widgets/dark_mode_test.dart
```

Expected: All tests pass.

- [ ] **Step 7.3: Run full test suite**

```bash
flutter test
```

Expected: `All tests passed!`

- [ ] **Step 7.4: Update CLAUDE.md — mark Phase 12 complete**

In `CLAUDE.md`, find the Phase 12 section and change all `- [ ]` to `- [x]`:

```markdown
### Phase 12 — Dark Mode Polish

- [x] Audit every screen and widget for hardcoded `Color` values — every color must reference `Theme.of(context).colorScheme` or `app_theme.dart` tokens
- [x] Verify `CalorieRing`, `MacroPill`, `FoodEntryCard`, `WeekStrip`, `RulerPicker`, `OnboardingLayout` render correctly in both `ThemeMode.light` and `ThemeMode.dark`
- [x] Test theme switching in Settings — confirm `MaterialApp.themeMode` update rebuilds the full widget tree without restart
- [x] Verify `SystemChrome.setSystemUIOverlayStyle` matches the active theme (dark icons on light, light icons on dark)
```

- [ ] **Step 7.5: Commit**

```bash
git add test/widgets/dark_mode_test.dart CLAUDE.md
git commit -m "test: dark mode widget tests; docs: mark Phase 12 complete"
```

---

### Task 8: Merge develop → main

- [ ] **Step 8.1: Merge and push**

```bash
git checkout main
git merge develop --no-ff -m "Merge develop into main: Phase 12 — dark mode polish"
git push origin main
git checkout develop
git push origin develop
```
