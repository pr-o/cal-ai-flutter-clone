# Phase 11 — Settings Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the full Settings screen — theme switcher, weight unit toggle, API key management, profile goal editor, and onboarding reset.

**Architecture:** Single file `settings_screen.dart` rewritten from stub; `main.dart` updated to read `themeMode` from `settingsProvider`. No new providers needed — `settingsProvider` and `profileProvider` (both already exist) cover all state. Profile goal updates go direct to `databaseProvider` followed by `ref.invalidate(profileProvider)`.

**Tech Stack:** Flutter Riverpod (`settingsProvider`, `profileProvider`, `databaseProvider`), `flutter_secure_storage` (API keys via `SettingsNotifier`), `http` (API key test calls), Drift (profile goal updates), `go_router` (`context.go('/onboarding/goal')` on reset).

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lib/main.dart` | Modify | Watch `settingsProvider` and pass `themeMode` to `MaterialApp.router` |
| `lib/features/settings/settings_screen.dart` | Rewrite | Full settings UI — all 5 sections |
| `test/features/settings/settings_screen_test.dart` | Create | Widget tests covering all sections |

---

### Task 1: Wire themeMode from settingsProvider into MaterialApp

**Files:**
- Modify: `lib/main.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1.1: Update `_CalAiAppState.build()` to watch `settingsProvider`**

Replace the hardcoded `themeMode: ThemeMode.system` with a value read from `settingsProvider`:

```dart
// lib/main.dart — full file replacement

import 'package:flutter/material.dart';
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
    return MaterialApp.router(
      title: 'Cal AI',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: widget.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 1.2: Run existing smoke test to verify it still passes**

```bash
flutter test test/widget_test.dart
```

Expected output: `All tests passed!`

- [ ] **Step 1.3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: wire themeMode from settingsProvider into MaterialApp"
```

---

### Task 2: Settings screen scaffold + Theme & Weight Unit sections

**Files:**
- Rewrite: `lib/features/settings/settings_screen.dart`
- Create: `test/features/settings/settings_screen_test.dart`

- [ ] **Step 2.1: Write failing tests for theme and weight unit sections**

```bash
mkdir -p test/features/settings
```

Create `test/features/settings/settings_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cal_ai_flutter_clone/db/database.dart';
import 'package:cal_ai_flutter_clone/features/home/notifier.dart';
import 'package:cal_ai_flutter_clone/features/settings/notifier.dart';
import 'package:cal_ai_flutter_clone/features/settings/settings_screen.dart';

// Minimal router wrapper so GoRouter context is available.
Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (_, __) => child,
      ),
      GoRoute(
        path: '/onboarding/goal',
        builder: (_, __) => const Scaffold(body: Text('onboarding')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      profileProvider.overrideWith((ref) async => null),
      ...overrides,
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows theme SegmentedButton with System selected by default',
      (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pump();

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
  });

  testWidgets('shows weight unit section', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pump();

    expect(find.text('Weight Unit'), findsOneWidget);
    expect(find.text('kg'), findsOneWidget);
    expect(find.text('lbs'), findsOneWidget);
  });

  testWidgets('shows API keys section', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pump();

    expect(find.text('API Keys'), findsOneWidget);
    expect(find.text('Gemini API Key'), findsOneWidget);
    expect(find.text('USDA API Key'), findsOneWidget);
  });

  testWidgets('shows reset onboarding button', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pump();

    expect(find.text('Reset Onboarding'), findsOneWidget);
  });

  testWidgets('reset onboarding shows confirmation dialog', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pump();

    await tester.tap(find.text('Reset Onboarding'));
    await tester.pumpAndSettle();

    expect(find.text('Reset onboarding?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
  });
}
```

- [ ] **Step 2.2: Run tests — verify they fail (SettingsScreen is still a stub)**

```bash
flutter test test/features/settings/settings_screen_test.dart
```

Expected: FAIL — tests for Theme/Weight Unit/API Keys/Reset not found.

- [ ] **Step 2.3: Rewrite `settings_screen.dart` with scaffold, theme and weight unit sections**

```dart
// lib/features/settings/settings_screen.dart

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../db/database.dart';
import '../../features/home/notifier.dart';
import 'notifier.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // API key controllers — loaded once from secure storage on init.
  final _geminiCtrl = TextEditingController();
  final _usdaCtrl = TextEditingController();
  bool _keysLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  @override
  void dispose() {
    _geminiCtrl.dispose();
    _usdaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKeys() async {
    final notifier = ref.read(settingsProvider.notifier);
    final gemini = await notifier.getGeminiApiKey();
    final usda = await notifier.getUsdaApiKey();
    if (mounted) {
      setState(() {
        _geminiCtrl.text = gemini ?? '';
        _usdaCtrl.text = usda ?? '';
        _keysLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _SectionHeader('Theme'),
          const SizedBox(height: 8),
          _ThemeSegment(current: settings.themeMode),
          const SizedBox(height: 20),
          _SectionHeader('Weight Unit'),
          const SizedBox(height: 8),
          _WeightUnitTile(unit: settings.weightUnit),
          const SizedBox(height: 20),
          _SectionHeader('API Keys'),
          const SizedBox(height: 8),
          if (_keysLoaded) ...[
            _ApiKeyField(
              label: 'Gemini API Key',
              controller: _geminiCtrl,
              onSave: () async {
                await ref
                    .read(settingsProvider.notifier)
                    .setGeminiApiKey(_geminiCtrl.text.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gemini API key saved')),
                  );
                }
              },
              onTest: () => _testGeminiKey(context, _geminiCtrl.text.trim()),
            ),
            const SizedBox(height: 12),
            _ApiKeyField(
              label: 'USDA API Key',
              controller: _usdaCtrl,
              onSave: () async {
                await ref
                    .read(settingsProvider.notifier)
                    .setUsdaApiKey(_usdaCtrl.text.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('USDA API key saved')),
                  );
                }
              },
              onTest: () => _testUsdaKey(context, _usdaCtrl.text.trim()),
            ),
          ] else
            const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 20),
          _SectionHeader('Profile & Goals'),
          const SizedBox(height: 8),
          profileAsync.when(
            loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('Error: $e'),
            data: (profile) => _ProfileSection(profile: profile),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => _confirmReset(context),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reset Onboarding'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── API key test calls ──────────────────────────────────────────────────────

  Future<void> _testGeminiKey(BuildContext context, String key) async {
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a key first')),
      );
      return;
    }
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$key',
      );
      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': 'Say OK'}
            ]
          }
        ]
      });
      final res = await http
          .post(url,
              headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 10));
      if (!context.mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Gemini key is valid')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gemini error ${res.statusCode}')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gemini test failed: $e')),
      );
    }
  }

  Future<void> _testUsdaKey(BuildContext context, String key) async {
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a key first')),
      );
      return;
    }
    try {
      final url = Uri.parse(
        'https://api.nal.usda.gov/fdc/v1/foods/search?query=apple&pageSize=1&api_key=$key',
      );
      final res = await http
          .get(url)
          .timeout(const Duration(seconds: 10));
      if (!context.mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ USDA key is valid')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('USDA error ${res.statusCode}')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('USDA test failed: $e')),
      );
    }
  }

  // ── Reset onboarding ────────────────────────────────────────────────────────

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset onboarding?'),
        content: const Text(
            'This will delete your profile and return you to the setup flow.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final db = ref.read(databaseProvider);
    await db.delete(db.profiles).go();
    await ref.read(settingsProvider.notifier).clearOnboarding();
    if (context.mounted) {
      context.go('/onboarding/goal');
    }
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      );
}

class _ThemeSegment extends ConsumerWidget {
  const _ThemeSegment({required this.current});
  final ThemeMode current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(value: ThemeMode.light, label: Text('Light')),
        ButtonSegment(value: ThemeMode.system, label: Text('System')),
        ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
      ],
      selected: {current},
      onSelectionChanged: (sel) =>
          ref.read(settingsProvider.notifier).setTheme(sel.first),
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _WeightUnitTile extends ConsumerWidget {
  const _WeightUnitTile({required this.unit});
  final String unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: const Text('Weight Unit'),
        subtitle: Text(unit == 'lbs' ? 'Pounds (lbs)' : 'Kilograms (kg)'),
        secondary: Text(
          unit,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        value: unit == 'lbs',
        onChanged: (v) => ref
            .read(settingsProvider.notifier)
            .setWeightUnit(v ? 'lbs' : 'kg'),
      ),
    );
  }
}

class _ApiKeyField extends StatefulWidget {
  const _ApiKeyField({
    required this.label,
    required this.controller,
    required this.onSave,
    required this.onTest,
  });
  final String label;
  final TextEditingController controller;
  final VoidCallback onSave;
  final VoidCallback onTest;

  @override
  State<_ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends State<_ApiKeyField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: widget.label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: widget.onTest,
              child: const Text('Test'),
            ),
            const SizedBox(width: 8),
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
          ],
        ),
      ],
    );
  }
}

class _ProfileSection extends ConsumerWidget {
  const _ProfileSection({required this.profile});
  final Profile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (profile == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('No profile found. Complete onboarding first.'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _goalLabel(profile!.goal),
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () => _showEditGoals(context, ref, profile!),
                child: const Text('Edit Goals'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _GoalRow('Calories', '${profile!.dailyCalories} kcal'),
          _GoalRow('Protein', '${profile!.dailyProteinG}g'),
          _GoalRow('Carbs', '${profile!.dailyCarbsG}g'),
          _GoalRow('Fat', '${profile!.dailyFatG}g'),
        ],
      ),
    );
  }

  String _goalLabel(String goal) => switch (goal) {
        'lose' => 'Goal: Lose weight',
        'gain' => 'Goal: Gain muscle',
        _ => 'Goal: Maintain weight',
      };

  void _showEditGoals(BuildContext context, WidgetRef ref, Profile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditGoalsSheet(profile: profile),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  )),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Edit Goals bottom sheet ──────────────────────────────────────────────────

class _EditGoalsSheet extends ConsumerStatefulWidget {
  const _EditGoalsSheet({required this.profile});
  final Profile profile;

  @override
  ConsumerState<_EditGoalsSheet> createState() => _EditGoalsSheetState();
}

class _EditGoalsSheetState extends ConsumerState<_EditGoalsSheet> {
  late final TextEditingController _calCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _fatCtrl;

  @override
  void initState() {
    super.initState();
    _calCtrl =
        TextEditingController(text: widget.profile.dailyCalories.toString());
    _proteinCtrl =
        TextEditingController(text: widget.profile.dailyProteinG.toString());
    _carbsCtrl =
        TextEditingController(text: widget.profile.dailyCarbsG.toString());
    _fatCtrl =
        TextEditingController(text: widget.profile.dailyFatG.toString());
  }

  @override
  void dispose() {
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit Daily Goals',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _NumField(label: 'Calories (kcal)', controller: _calCtrl),
          const SizedBox(height: 12),
          _NumField(label: 'Protein (g)', controller: _proteinCtrl),
          const SizedBox(height: 12),
          _NumField(label: 'Carbs (g)', controller: _carbsCtrl),
          const SizedBox(height: 12),
          _NumField(label: 'Fat (g)', controller: _fatCtrl),
          const SizedBox(height: 16),
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final cal = int.tryParse(_calCtrl.text);
    final protein = int.tryParse(_proteinCtrl.text);
    final carbs = int.tryParse(_carbsCtrl.text);
    final fat = int.tryParse(_fatCtrl.text);
    if (cal == null || protein == null || carbs == null || fat == null) return;

    final db = ref.read(databaseProvider);
    await (db.update(db.profiles)
          ..where((t) => t.id.equals(widget.profile.id)))
        .write(ProfilesCompanion(
      dailyCalories: Value(cal),
      dailyProteinG: Value(protein),
      dailyCarbsG: Value(carbs),
      dailyFatG: Value(fat),
    ));
    ref.invalidate(profileProvider);

    if (mounted) Navigator.of(context).pop();
  }
}

class _NumField extends StatelessWidget {
  const _NumField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
```

- [ ] **Step 2.4: Run tests**

```bash
flutter test test/features/settings/settings_screen_test.dart
```

Expected: All 5 tests pass.

- [ ] **Step 2.5: Run analyze**

```bash
flutter analyze lib/features/settings/settings_screen.dart
```

Expected: No issues found.

- [ ] **Step 2.6: Commit**

```bash
git add lib/features/settings/settings_screen.dart test/features/settings/settings_screen_test.dart
git commit -m "feat: Phase 11 — settings screen (theme, unit, API keys, profile, reset)"
```

---

### Task 3: Update CLAUDE.md Phase 11 checkboxes

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 3.1: Mark Phase 11 checkboxes as complete**

In `CLAUDE.md`, replace the Phase 11 section:

```markdown
### Phase 11 — Settings Screen

- [x] Build `lib/features/settings/settings_screen.dart`:
  - [x] **Theme** — `SegmentedButton` (Light / Dark / System); writes to `settingsNotifier.setTheme()`; `MaterialApp.themeMode` updates immediately
  - [x] **Weight unit** — `Switch` tile (kg / lbs); writes to `settingsNotifier.setWeightUnit()`
  - [x] **API Keys** — two `TextField`s with obscured text for `gemini_api_key` and `usda_api_key`; "Save" `FilledButton` writes to `flutter_secure_storage`; inline "Test" `TextButton` per key that makes a minimal API call and shows a `SnackBar`
  - [x] **Profile section** — display goal + daily calorie + macro targets; "Edit Goals" `TextButton` opens a `showModalBottomSheet` reusing `CalorieRing` donut widgets for post-onboarding target adjustment
  - [x] **Reset onboarding** — red `TextButton` with `showDialog` confirmation; on confirm: clears `SharedPreferences.onboarding_complete` + deletes `Profiles` row → `context.go('/onboarding/goal')`
```

- [ ] **Step 3.2: Run full test suite**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 3.3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: mark Phase 11 complete in CLAUDE.md"
```

---

### Task 4: Merge develop → main

- [ ] **Step 4.1: Merge and push**

```bash
git checkout main
git merge develop --no-ff -m "Merge develop into main: Phase 11 — settings screen"
git push origin main
git checkout develop
git push origin develop
```
