# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A Flutter clone of **Cal AI** — an AI-powered calorie tracking app. Users complete a multi-step onboarding, then log meals via AI photo scanning (Gemini 2.0 Flash), food text search (USDA FoodData Central), exercise, and water. All data is stored locally on-device (no backend, no auth).

Reference design: `/home/sung/cal-ai-rn-clone/CLAUDE.md` (React Native version with full spec)  
UI reference screenshots: `.claude/screenshots/` (local copy; see `.claude/screenshots/README.md` for descriptions)

---

## Tech Stack

| Concern | Package | Notes |
|---|---|---|
| Framework | Flutter SDK (stable) | Dart, cross-platform iOS + Android |
| Navigation | `go_router` ^14.x | Declarative, shell routes for tabs |
| State management | `riverpod` + `flutter_riverpod` ^3.x | `AsyncNotifier` / `Notifier` providers; Riverpod 3.0 is current standard |
| Local DB | `drift` ^2.x (moor successor) | Type-safe SQLite ORM with codegen |
| Settings store | `shared_preferences` ^2.x | Theme, units, `onboarding_complete` flag — non-sensitive only |
| Secure store | `flutter_secure_storage` ^9.x | API keys (Gemini, USDA) — uses Keychain / EncryptedSharedPreferences |
| Camera | `camera` ^0.11.x | Requires native build, not hot-reload |
| AI food recognition | Google Gemini 2.0 Flash Vision API | REST via `http` or `dio` |
| Food text search | USDA FoodData Central API | REST, free with data.gov API key |
| Charts | `fl_chart` ^0.69.x | Line + Bar charts for Analytics |
| Push notifications | `flutter_local_notifications` ^19.x | Meal reminders |
| SVG / graphics | `flutter_svg` + custom `CustomPainter` | Donut rings |
| Animations | Flutter built-in `AnimationController` + `Lottie` | Ring fill animations |
| Image display | `cached_network_image` | Food photo thumbnails |
| Unit testing | `flutter_test` + `mocktail` | Built-in test framework |

---

## Commands

```bash
# Get dependencies
flutter pub get

# Run on connected device / emulator
flutter run

# Run on specific device
flutter run -d <device-id>

# List devices
flutter devices

# Build for iOS (release)
flutter build ios --release

# Build for Android (release)
flutter build apk --release
flutter build appbundle --release

# Run all tests
flutter test

# Run a single test file
flutter test test/utils/tdee_test.dart

# Type check / analyze (no compilation)
flutter analyze

# Format code
dart format lib/ test/

# Generate Drift DB code (run after schema changes)
dart run build_runner build --delete-conflicting-outputs

# Watch and re-generate on changes
dart run build_runner watch --delete-conflicting-outputs

# Clean build artifacts
flutter clean && flutter pub get
```

---

## Architecture

### Navigation (GoRouter — declarative, shell-based)

Three top-level route groups:

- **`/onboarding/*`** — stack of 10 screens with no bottom nav bar. Entry point for first-time users. Uses `GoRouter.go('/home')` after profile is saved.
- **`/`** — `ShellRoute` wrapping a `ScaffoldWithNavBar`; three tabs: Home (`/home`), Analytics (`/analytics`), Settings (`/settings`).
- **`/log/*`** — modal/fullscreen routes pushed over the shell: `/log/camera`, `/log/scan-result`, `/log/search`, `/log/exercise`, `/log/water`.

`main.dart` reads `SharedPreferences.onboarding_complete` synchronously before the first frame and sets the initial location to `/onboarding/goal` or `/home`.

### State Architecture

Two persistence layers:

- **SharedPreferences** — flags and settings: `onboarding_complete`, `theme`, `weight_unit`, API keys. Read/written via `SettingsNotifier`.
- **Drift (SQLite)** — all tracking data. Schema in `lib/db/database.dart`. Five tables: `Profiles`, `DailyLogs`, `FoodEntries`, `ExerciseEntries`, `WeightLogs`.

Riverpod providers sit above the persistence layer:
- `profileProvider` (`AsyncNotifier`) — loaded once at startup from `Profiles` table
- `dailyProvider(date)` (`AsyncNotifier`) — reloaded on home screen focus for a given date
- `settingsProvider` (`Notifier`) — reads/writes `SharedPreferences` directly

### AI Food Scan Flow

`CameraScreen` (camera package) → capture image → base64 encode → `GeminiService.analyzeFood()` → Gemini 2.0 Flash Vision REST → JSON parse → `ScanResultScreen` (editable fields) → Drift `INSERT` → `dailyProvider` invalidate → navigate back to `/home`.

The Gemini API key is stored in `SharedPreferences` and entered once by the user in Settings. `GeminiService` reads it on each call.

### Food Text Search Flow

`SearchScreen` → `UsdaService.searchFoods()` → USDA FoodData Central `/fdc/v1/foods/search` → results list → confirm → Drift `INSERT` → `dailyProvider` invalidate.

### Onboarding

10 sequential screens under `lib/features/onboarding/`. Data accumulates in an `OnboardingNotifier` (Riverpod `Notifier`, not persisted). `PlanScreen` computes TDEE via `TdeeCalculator` (`lib/utils/tdee.dart`) and shows 4 editable donut rings. On "Let's get started!" → single `INSERT INTO profiles` → `SharedPreferences.set('onboarding_complete', true)` → `context.go('/home')`.

### Dark Mode

Flutter's `ThemeData` with `ThemeMode`. `SettingsNotifier.theme` (`'light' | 'dark' | 'system'`) is read from `SharedPreferences` and passed to `MaterialApp.themeMode`. All widgets use `Theme.of(context)` color tokens — no hardcoded colors.

---

## Project Structure

```
lib/
├── main.dart                    # App entry, ProviderScope, GoRouter init, theme setup
├── router.dart                  # GoRouter configuration (all routes)
├── db/
│   ├── database.dart            # Drift AppDatabase class + all table definitions
│   ├── database.g.dart          # Generated by build_runner (do not edit)
│   └── daos/                    # Data access objects per feature
│       ├── food_dao.dart
│       ├── exercise_dao.dart
│       └── weight_dao.dart
├── features/
│   ├── onboarding/
│   │   ├── notifier.dart        # OnboardingNotifier (temporary state)
│   │   └── screens/             # goal, gender, birthday, current_weight, height,
│   │                            # target_weight, activity, diet, results, plan
│   ├── home/
│   │   ├── notifier.dart        # DailyNotifier(date)
│   │   └── home_screen.dart
│   ├── analytics/
│   │   └── analytics_screen.dart
│   ├── settings/
│   │   ├── notifier.dart        # SettingsNotifier
│   │   └── settings_screen.dart
│   └── log/
│       ├── camera_screen.dart
│       ├── scan_result_screen.dart
│       ├── search_screen.dart
│       ├── exercise_screen.dart
│       └── water_screen.dart
├── services/
│   ├── gemini_service.dart      # Gemini 2.0 Flash Vision REST calls
│   └── usda_service.dart        # USDA FoodData Central food text search
├── utils/
│   ├── tdee.dart                # Mifflin-St Jeor TDEE + macro calculation
│   ├── streaks.dart             # Consecutive day streak logic
│   └── units.dart               # kg↔lbs, cm↔ft/in, ml↔oz conversions
├── widgets/
│   ├── calorie_ring.dart        # CustomPainter SVG-style donut ring
│   ├── macro_pill.dart          # Protein / Carbs / Fat remaining pill
│   ├── food_entry_card.dart     # Dismissible card with photo thumbnail
│   ├── ruler_picker.dart        # Horizontal scroll ruler for numeric input
│   ├── onboarding_layout.dart   # Back arrow + LinearProgressIndicator wrapper
│   └── week_strip.dart          # 7-day row with active day highlight
└── theme/
    └── app_theme.dart           # ThemeData light + dark, color tokens

test/
├── utils/
│   ├── tdee_test.dart
│   ├── streaks_test.dart
│   └── units_test.dart
└── widgets/                     # Widget tests
```

---

## UI Design Reference (from screenshots)

### Onboarding screens (`screen_01`, `screen_03`, `screen_04`)

- **Header:** Round gray back-arrow button (left) + thin `LinearProgressIndicator` (center, black filled) — no native app bar.
- **Heading typography:** Font weight 800–900, ~32px. Subtitle below in regular weight ~14px gray.
- **Option pills:** Full-width, `BorderRadius.circular(16)`, `#F0F0F0` background unselected → `#000000` background + white text selected. Generous vertical padding (~20px).
- **"Next" / CTA button:** Full-width black pill (`BorderRadius.circular(30)`) pinned to the bottom above the home indicator.
- **Ruler picker (`screen_03`):** Goal label ("Lose weight") in small gray text above the value. Selected value: ~48px bold. The active/center tick zone has a subtle light-gray rectangle highlight behind the ticks. Tick marks vary in height (major / minor marks).
- **Plan screen (`screen_04`):**
  - Top: checkmark circle icon, then "Congratulations your custom plan is ready!" heading.
  - Dynamic goal line: "You should lose: X kg by [date]" (calculated from TDEE + target weight).
  - Section label: "Daily recommendation / You can edit this anytime" (gray subtitle).
  - 2×2 `GridView` of donut ring cells: each cell shows ring + value + unit. Pencil `IconButton` sits in the **bottom-right corner** of each cell to open an edit dialog.
  - Ring values: Calories (no unit suffix inside ring), Carbs/Protein/Fats in grams ("99g").

### Home screen — light mode (`screen_06`)

- **App bar:** `🍎 Cal AI` title (left) + streak badge (right): flame emoji + count in a rounded pill.
- **Week strip:** Day letter (S/M/T…) above date number. The **current day** has a **dashed circle** outline, not a filled pill. Past logged days use a solid filled style.
- **Calorie card:** Large white `Card` with rounded corners. Left: calorie count (large bold) + "Calories left" label. Right: large `CalorieRing` (`CustomPainter` donut) with a flame icon centered. The ring is nearly empty/outline-only when no food has been logged.
- **Macro row:** Three equal-width cards in a row. Each card: gram value (bold) + label ("Protein left") + small colored circular ring icon (same `CalorieRing` widget, smaller size).
- **Empty state:** Centered multi-line text + a hand-drawn sketch icon (pen/pencil illustration).
- **FAB:** Black circle `FloatingActionButton` (`+`) anchored bottom-right, above bottom nav.

### Home screen — dark mode (`dark_iphone_preview.png`)

- Background: `#1A1A1A`. Cards: `#242424`.
- Macro cards in dark mode each contain a **larger circular progress ring** (not just an icon) — protein = orange ring, carbs = yellow-orange ring, fat = blue ring.
- Food log entries: square rounded thumbnail (left) + food name (truncated, bold) + time (top-right) + `🔥 X kcal` row + macro emoji row (`⚡ Xg 🥕 Xg 💧 Xg`).
- Streak badge uses an **orange pill** (`#FF5500` background) with flame emoji + number.

### Food scan result (`analyzed_food_scan.png`)

- Full-bleed `Image.file` header (~45% screen height). "Nutrition" white text centered (overlaid). Back `IconButton` (left) + share + overflow `IconButton`s (right) overlaid.
- Below the photo: bookmark `Icon` + timestamp string ("12:46PM") on the same row.
- Food name as large bold `Text` (left) + servings picker as a bordered rounded box `"1 ✏️"` (right, `OutlinedButton` style).
- Calories: `🔥 Calories` label then `621` in ~40px bold on the next line.
- Macros row: protein / carbs / fats each with a small emoji icon prefix and gram value.
- Health score row: heart icon + "Health Score" label + green `LinearProgressIndicator` + "7/10" (right-aligned).
- Bottom action row: `"✦ Fix Results"` `OutlinedButton` (left, with sparkle prefix) + `"Done"` black `FilledButton` (right).

### Results / motivation screen (`screen_02`)

- Two-line bold heading: "Cal AI creates / long-term results".
- Chart inside a light-gray rounded `Card`: two `fl_chart` `LineChart` curves — **black** (Cal AI, trending down) and **pink/salmon** (Traditional Diet, trending up + filled area beneath).
- Legend: apple emoji + "Cal AI" label + a black "Weight" badge pill. "Traditional Diet" label inline on chart.
- Stat below chart (inside the card): centered italic gray text "80% of Cal AI users maintain their weight loss even 6 months later".

---

## Key Conventions

- **Drift schema changes** always require running `dart run build_runner build --delete-conflicting-outputs`. Never edit `.g.dart` files manually.
- **API keys** are never hardcoded. `gemini_api_key` and `usda_api_key` are stored in `flutter_secure_storage` (Keychain on iOS, EncryptedSharedPreferences on Android). Non-sensitive settings (`theme`, `weight_unit`, `onboarding_complete`) use `shared_preferences`.
- **Units:** Internal storage is always metric (kg, cm, ml). `lib/utils/units.dart` handles display conversion when `weight_unit == 'lbs'`.
- **Dates:** All dates stored as `'YYYY-MM-DD'` strings in SQLite. All timestamps as ISO 8601 strings. No `DateTime` objects in the DB layer.
- **Camera** requires a physical device or properly configured emulator and does not work in hot-reload-only flows. Use `flutter run` on a real device for camera testing.
- **Color tokens** (from Cal AI design system):
  - `bgPrimary` light: `#FFFFFF`, dark: `#111111`
  - `bgSecondary` light: `#F5F5F5`, dark: `#1E1E1E`
  - `accentOrange`: `#FF5500` (streak flame)
  - `macroProtein`: `#FF6B35`, `macroCarbs`: `#FFB800`, `macroFat`: `#4A9EFF`
- **Primary font:** Inter (via `google_fonts` package, fallback: system sans-serif).
- **Date string formatting:** Use manual `padLeft(2, '0')` formatting — `'${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'`. No `intl`/`DateFormat` package in the project.
- **Color opacity:** Use `.withValues(alpha: x)` not the deprecated `.withOpacity(x)` (Flutter 3.x).

---

## Learnings & Gotchas

### Drift

- **Full import required for joins and column ops:** Use `import 'package:drift/drift.dart';` (not just `drift_flutter`) whenever you need `innerJoin`, `equalsExp`, `isBiggerOrEqualValue`, `selectOnly`, `addColumns`. The narrower import omits these symbols and causes confusing "undefined" errors.
- **Reading typed rows from joins:** After a `.join([innerJoin(...)])` query, extract rows with `row.readTable(db.tableName)` — not `.read(db.columnName)` directly on the row.
- **Distinct values via `selectOnly`:** To fetch a single column (e.g., distinct dates) without loading full rows:
  ```dart
  db.selectOnly(db.dailyLogs)
    ..addColumns([db.dailyLogs.date])
    ..join([innerJoin(db.foodEntries, db.foodEntries.dailyLogId.equalsExp(db.dailyLogs.id))])
  ```

### fl_chart

- **Stacked bar chart values are cumulative:** `BarChartRodStackItem(from, to, color)` — `from` is the sum of all previous segments, `to` is that sum plus the current value. Not individual segment heights.
- **Dashed reference line:** Use `dashArray: [6, 4]` on a `LineChartBarData` with two `FlSpot`s spanning the full x range.
- **Always fill all N days:** When charting weekly data, use `List.generate(7, ...)` to produce a slot for every day even if no food was logged, so the chart has no gaps.

---

## Implementation Plan

Phases are sequential. Complete every checkbox in a phase before starting the next. Each checkbox is one discrete, testable unit of work.

---

### Phase 0 — Project Scaffolding

- [x] Run `flutter create cal_ai_flutter_clone --org com.example --platforms ios,android` in the project root
- [x] Add all dependencies to `pubspec.yaml`: `go_router`, `flutter_riverpod`, `riverpod_annotation`, `drift`, `drift_flutter`, `shared_preferences`, `camera`, `http`, `fl_chart`, `flutter_local_notifications`, `flutter_svg`, `cached_network_image`, `google_fonts`, `lottie`
- [x] Add dev dependencies: `build_runner`, `drift_dev`, `riverpod_generator`, `mocktail`, `flutter_test`
- [x] Run `flutter pub get` and confirm zero resolution errors
- [x] Create `lib/theme/app_theme.dart` with `ThemeData` for light and dark modes using the Cal AI color tokens above
- [x] Create minimal `lib/main.dart` with `ProviderScope`, `MaterialApp.router`, and `themeMode` wired to a placeholder `ValueNotifier`
- [x] Create `lib/router.dart` with a single `/` route rendering a placeholder `Scaffold`
- [x] Verify `flutter analyze` passes with zero errors on the empty scaffold
- [ ] Verify `flutter run` boots without errors on a connected device/emulator

---

### Phase 1 — Database & Storage Layer

- [x] Create `lib/db/database.dart` — define all five Drift tables: `Profiles`, `DailyLogs`, `FoodEntries`, `ExerciseEntries`, `WeightLogs` with exact columns (see RN spec for column names and types)
- [x] Run `dart run build_runner build --delete-conflicting-outputs` to generate `database.g.dart`
- [x] Create `lib/db/daos/food_dao.dart`, `exercise_dao.dart`, `weight_dao.dart` — each as a `DatabaseAccessor` with typed query methods
- [x] Create a `databaseProvider` (`Provider<AppDatabase>`) in `lib/db/database.dart` that exposes the singleton `AppDatabase` instance via Riverpod
- [x] Create `lib/features/settings/notifier.dart` — `SettingsNotifier extends Notifier<SettingsState>` backed by `SharedPreferences`; exposes `theme`, `weightUnit`, all API key getters/setters, `onboardingComplete` flag
- [x] Create a `settingsProvider` that reads from `SharedPreferences` in `build()` and exposes `SettingsNotifier`
- [ ] Verify SharedPreferences reads/writes with a quick manual scratch test in `main.dart`, then revert

---

### Phase 2 — Shared Utilities & Widgets

- [x] Create `lib/utils/tdee.dart` — implement Mifflin-St Jeor formula; export `TdeeResult calculateTdee(ProfileData profile)` returning `{ calories, proteinG, carbsG, fatG }`
- [x] Create `lib/utils/units.dart` — export `kgToLbs`, `lbsToKg`, `cmToFtIn`, `ftInToCm`, `mlToOz`, `ozToMl`
- [x] Create `lib/utils/streaks.dart` — export `int calculateStreak(List<String> dates)` counting consecutive days ending today
- [x] Write unit tests for all three utils (`test/utils/`); run `flutter test test/utils/` and confirm all pass
- [x] Create `lib/widgets/onboarding_layout.dart` — `StatelessWidget` wrapping children with: back `IconButton` (leading), `LinearProgressIndicator` (driven by `step` / `total` props), safe-area padding, white/dark-mode background
- [x] Create `lib/widgets/ruler_picker.dart` — `ScrollController`-based horizontal `ListView` of evenly spaced tick marks (`CustomPainter`); center-pinned selected value displayed large above the ruler; accepts `value`, `min`, `max`, `step`, `unit`, `onChanged` callbacks
- [x] Create `lib/widgets/calorie_ring.dart` — `CustomPainter` donut ring accepting `consumed`, `goal`, `size`; flame `Icon` centered; animated arc fill on mount via `AnimationController` + `CurvedAnimation`
- [x] Create `lib/widgets/macro_pill.dart` — `Container` with remaining grams + label + colored icon; accepts `type` (`protein` | `carbs` | `fat`), `remaining`, `goal`
- [x] Create `lib/widgets/food_entry_card.dart` — `Dismissible` card with optional `CachedNetworkImage` thumbnail (left), food name (bold), kcal + P/C/F row (right); `onDismissed` calls a delete callback
- [x] Create `lib/widgets/week_strip.dart` — `Row` of 7 `GestureDetector` day tiles; active day wrapped in a black `DecoratedBox` (pill shape); tapping a past day calls `onDaySelected(String date)`

---

### Phase 3 — Onboarding Screens

- [x] Create `lib/features/onboarding/notifier.dart` — `OnboardingState` data class + `OnboardingNotifier extends Notifier<OnboardingState>` holding all fields (`goal`, `gender`, `birthday`, `currentWeightKg`, `heightCm`, `targetWeightKg`, `activityLevel`, `dietaryPreferences`); not persisted until final step
- [x] Add all 10 onboarding routes to `lib/router.dart` under a `/onboarding` prefix using `GoRoute` stack (no `ShellRoute`)
- [x] Build `lib/features/onboarding/screens/goal_screen.dart` — 3 option `GestureDetector` pills; tapping sets `onboardingNotifier.goal` and calls `context.go('/onboarding/gender')`
- [x] Build `gender_screen.dart` — 3 option pills (Male / Female / Other)
- [x] Build `birthday_screen.dart` — `showDatePicker` (platform-native); stores ISO date string to `OnboardingNotifier`
- [x] Build `current_weight_screen.dart` — `RulerPicker` (40–200 kg, step 0.1); unit label from `settingsProvider`
- [x] Build `height_screen.dart` — `RulerPicker` (100–250 cm); displays ft/in label when `weightUnit == 'lbs'`
- [x] Build `target_weight_screen.dart` — `RulerPicker` with goal label ("Lose weight") above the value
- [x] Build `activity_screen.dart` — 4 option pills (Sedentary / Lightly active / Active / Very active)
- [x] Build `diet_screen.dart` — multi-select pills (None / Vegetarian / Vegan / Keto / Gluten-free); `Set<String>` selection
- [x] Build `results_screen.dart` — static motivational screen; `fl_chart` `LineChart` comparing "Cal AI" vs "Traditional Diet" weight curves; "80% of users maintain weight loss 6 months later" stat; "Next" `FilledButton`
- [x] Build `plan_screen.dart` — call `calculateTdee(onboardingState)` on init; display 4 macro target cells in a 2×2 `GridView`; each cell has a pencil `IconButton` that opens an `AlertDialog` with a `TextField` for inline editing; "Let's get started!" `FilledButton` at bottom
- [x] Wire "Let's get started!" in `plan_screen.dart`: `INSERT INTO Profiles` via Drift → `settingsProvider.setOnboardingComplete(true)` → `context.go('/home')`
- [ ] Manually walk through all 10 onboarding steps on simulator and confirm `Profiles` row is inserted into DB

---

### Phase 4 — Root Layout & Navigation Shell

- [x] Update `lib/router.dart` — add `ShellRoute` for `/(home|analytics|settings)` that wraps a `ScaffoldWithNavBar` (`BottomNavigationBar` with Home / Analytics / Settings tabs, black active color)
- [x] Update `lib/main.dart` — `WidgetsFlutterBinding.ensureInitialized()`, await `buildRouter()` which reads `onboarding_complete` from SharedPreferences to set initial location
- [x] Create `lib/features/home/home_screen.dart` stub
- [x] Create `lib/features/analytics/analytics_screen.dart` stub
- [x] Create `lib/features/settings/settings_screen.dart` stub
- [ ] Verify full navigation shell: fresh install → onboarding → plan → home tab; re-launch → goes directly to home tab

---

### Phase 5 — Riverpod Providers & Daily Data Layer

- [x] Create `lib/features/home/notifier.dart` — `DailyNotifier extends AsyncNotifier<DailyState>`; watches `selectedDateProvider`; `build()` upserts `DailyLogs`, loads `FoodEntries`+`ExerciseEntries`, derives calorie/macro totals; exposes `addFoodEntry`, `deleteFoodEntry`, `addExerciseEntry`, `deleteExerciseEntry`, `updateWater` mutators; `selectedDateProvider` backed by `SelectedDateNotifier` (Riverpod 3.0 — `StateProvider` removed)
- [x] Create `profileProvider` — `FutureProvider<Profile?>` querying `SELECT * FROM Profiles LIMIT 1`
- [x] Pre-warm `profileProvider` and `dailyProvider` in `CalAiApp.initState()`

---

### Phase 6 — Home Dashboard Screen

- [x] Build `lib/features/home/home_screen.dart` fully:
  - [x] `WeekStrip` at top — tapping a day calls `ref.read(selectedDateProvider.notifier).select(date)`
  - [x] Streak badge (orange pill, top right) from `calculateStreak`
  - [x] `_CalorieCard` with `CalorieRing` (large), calories remaining, eaten, burned stats
  - [x] `Row` of three `MacroPill` widgets (Protein, Carbs, Fat) with remaining/goal
  - [x] "Recently logged" section header
  - [x] `SliverList` of `FoodEntryCard` items; swipe-to-delete calls `deleteFoodEntry`; empty state with icon
  - [x] FAB (black) opens `showModalBottomSheet` with Camera / Search / Exercise / Water options
  - [x] Log routes added to router (`/log/camera`, `/log/search`, `/log/exercise`, `/log/water`) with stub screens
  - [x] Widget smoke test updated to override DB providers (avoids pending-timer failure)

---

### Phase 7 — AI Food Scan (Camera + Gemini)

- [x] Add camera permission entries to `ios/Runner/Info.plist` (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`) and `android/app/src/main/AndroidManifest.xml` (`CAMERA`)
- [x] Create `lib/features/log/camera_screen.dart` — `CameraController(ResolutionPreset.high)`; fullscreen `CameraPreview`; circular shutter button; on tap → `takePicture()` → `context.push('/log/scan-result', extra: path)`; lifecycle-safe disposal
- [x] Create `lib/services/gemini_service.dart` — POSTs base64 image to Gemini 2.0 Flash; parses JSON `{name, calories, protein_g, carbs_g, fat_g, serving_size, health_score, ingredients}`; strips markdown fences; throws `GeminiParseException` on failure; supports `correctionHint` for re-analysis
- [x] Create `lib/features/log/scan_result_screen.dart`: full-bleed photo header, editable name TextField, servings stepper (scales macros), calories/macros rows, health score LinearProgressIndicator, Ingredients ExpansionTile, "✦ Fix Results" dialog → re-calls Gemini, "Done" → `dailyProvider.addFoodEntry` → `/home`
- [x] Add `/log/scan-result` route with `state.extra as String` for photo path
- [ ] Test full scan flow on device with a food photo

---

### Phase 8 — Food Text Search (USDA FoodData Central)

- [x] Create `lib/services/usda_service.dart` — GETs USDA FoodData Central `/foods/search`; maps `foodNutrients[]` to `FoodSearchResult {fdcId, name, brandOwner, calories, proteinG, carbsG, fatG, servingSize}`; reads kcal from `Energy` nutrient entry
- [x] Create `lib/features/log/search_screen.dart`:
  - [x] `TextField` in AppBar auto-focused on mount; clear button when query non-empty
  - [x] 300ms debounce via `Timer`; shows `SnackBar` when USDA key missing
  - [x] `ListView` of `ListTile`s with food icon, name, kcal + serving size + brand
  - [x] Tapping opens `_ConfirmSheet` (bottom sheet) with servings stepper + full macro badges
  - [x] "Add to log" `FilledButton` — inserts `FoodEntriesCompanion(source: 'search')` → `dailyProvider.addFoodEntry` → `/home`
  - [x] Empty/no-results/loading states

---

### Phase 9 — Exercise & Water Logging

- [x] Create `lib/utils/exercise.dart` — MET values for 15 exercises; `estimateCaloriesBurned(name, durationMinutes, weightKg)` using MET formula; `kExerciseSuggestions` list
- [x] Create `lib/features/log/exercise_screen.dart`: `Autocomplete<String>` with 15 suggestions; duration TextField auto-recalculates calories via MET; calories TextField overrideable; "Log Exercise" writes `ExerciseEntriesCompanion` via `dailyProvider.addExerciseEntry` → `context.pop()`
- [x] Create `lib/features/log/water_screen.dart`: progress card with `LinearProgressIndicator` toward 2500 ml goal; 2×2 grid of quick-add buttons (250/500/750/1000 ml); custom amount TextField + "Add" button; all amounts call `dailyProvider.updateWater` → `context.pop()`

---

### Phase 10 — Analytics Screen

- [x] Build `lib/features/analytics/analytics_screen.dart`:
  - [x] **Weight trend** — query `WeightLogs` last 90 days via `weightDao`; render `fl_chart` `LineChart`; target weight as dashed horizontal reference line
  - [x] **Weekly macros** — query `FoodEntries` last 7 days grouped by date; render `fl_chart` `BarChart` with stacked protein/carbs/fat bars per day
  - [x] **BMI card** — calculate from `profileState.heightCm` + latest `WeightLogs` entry; `Color`-coded label
  - [x] **Streak card** — call `calculateStreak` on dates from `FoodEntries`; display count + flame icon
  - [x] **Log weight** `FloatingActionButton` — `showModalBottomSheet` with a `TextField` + "Save" `FilledButton` that inserts into `WeightLogs` via `weightDao` and invalidates `analyticsProvider`

---

### Phase 11 — Settings Screen

- [ ] Build `lib/features/settings/settings_screen.dart`:
  - [ ] **Theme** — `SegmentedButton` (Light / Dark / System); writes to `settingsNotifier.setTheme()`; `MaterialApp.themeMode` updates immediately
  - [ ] **Weight unit** — `Switch` tile (kg / lbs); writes to `settingsNotifier.setWeightUnit()`
  - [ ] **API Keys** — two `TextField`s with obscured text for `gemini_api_key` and `usda_api_key`; "Save" `FilledButton` writes to `flutter_secure_storage`; inline "Test" `TextButton` per key that makes a minimal API call and shows a `SnackBar`
  - [ ] **Profile section** — display goal + daily calorie + macro targets; "Edit Goals" `TextButton` opens a `showModalBottomSheet` reusing `CalorieRing` donut widgets for post-onboarding target adjustment
  - [ ] **Reset onboarding** — red `TextButton` with `showDialog` confirmation; on confirm: clears `SharedPreferences.onboarding_complete` + deletes `Profiles` row → `context.go('/onboarding/goal')`

---

### Phase 12 — Dark Mode Polish

- [ ] Audit every screen and widget for hardcoded `Color` values — every color must reference `Theme.of(context).colorScheme` or `app_theme.dart` tokens
- [ ] Verify `CalorieRing`, `MacroPill`, `FoodEntryCard`, `WeekStrip`, `RulerPicker`, `OnboardingLayout` render correctly in both `ThemeMode.light` and `ThemeMode.dark`
- [ ] Test theme switching in Settings — confirm `MaterialApp.themeMode` update rebuilds the full widget tree without restart
- [ ] Verify `SystemChrome.setSystemUIOverlayStyle` matches the active theme (dark icons on light, light icons on dark)

---

### Phase 13 — Push Notifications (Meal Reminders)

- [ ] Request notification permissions using `flutter_local_notifications` + `permission_handler` on both platforms
- [ ] Create `lib/utils/notifications.dart` — export `requestPermissions()`, `scheduleMealReminder(int hour, int minute, String label)`, `cancelAllReminders()`
- [ ] Add a **Reminders** section to the Settings screen with three `SwitchListTile`s for breakfast (8:00), lunch (12:00), dinner (19:00); each toggle calls `scheduleMealReminder` or `cancelAllReminders`
- [ ] Persist reminder toggle states to `SharedPreferences` (`reminder_breakfast`, `reminder_lunch`, `reminder_dinner`)
- [ ] Test notifications fire correctly on a physical device

---

### Phase 14 — Final Testing & Cleanup

- [ ] Run `flutter analyze` — zero warnings or errors
- [ ] Run `dart format lib/ test/ --set-exit-if-changed` — zero formatting issues
- [ ] Run `flutter test` — all unit tests pass
- [ ] Walk through the full happy path end-to-end: fresh install → onboarding → home → scan food → confirm → home updates → search food → add → home updates → log exercise → log water → analytics shows data → settings theme toggle → dark mode correct
- [ ] Test edge cases: no API key set (graceful error `SnackBar`), Gemini returns unparseable JSON ("Fix Results" shown), empty food log (empty state shown), first day (streak = 0)
- [ ] Remove all `debugPrint` / `print` statements from production code paths
- [ ] Confirm no API keys are hardcoded anywhere in `lib/` — all reads go through `SharedPreferences` via `SettingsNotifier`
