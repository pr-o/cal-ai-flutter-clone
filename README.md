# Cal AI 클론

AI 기반 칼로리 추적 앱 Cal AI를 재현한 크로스플랫폼 모바일 클론 프로젝트

---

# Cal AI 클론

Cal AI의 핵심 경험을 재현한 Flutter 기반 모바일 앱 클론 프로젝트

사진 촬영으로 음식을 인식해 즉시 칼로리와 영양소를 파악하는 AI 기반 칼로리 추적 앱이다. 10단계 온보딩을 통해 사용자 맞춤 목표를 설정하고, Gemini 2.0 Flash Vision API로 음식 사진을 분석하며, USDA FoodData Central API로 음식을 텍스트 검색한다. 별도 백엔드나 로그인 없이 모든 데이터를 기기 내 SQLite에 저장하는 로컬 전용 앱이다.

## 기술 스택

| 역할 | 패키지 | 버전 |
|---|---|---|
| 프레임워크 | Flutter (stable) + Dart | 최신 stable |
| 내비게이션 | go_router | ^14.x |
| 상태 관리 | flutter_riverpod + riverpod_annotation | ^3.x |
| 로컬 DB | drift (SQLite ORM) | ^2.x |
| 설정 저장소 | shared_preferences | ^2.x |
| 보안 저장소 | flutter_secure_storage | ^9.x |
| 카메라 | camera | ^0.11.x |
| AI 음식 인식 | Google Gemini 2.0 Flash Vision API | REST |
| 음식 텍스트 검색 | USDA FoodData Central API | REST |
| 차트 | fl_chart | ^0.69.x |
| 푸시 알림 | flutter_local_notifications | ^19.x |
| 테스트 | flutter_test + mocktail | 내장 / latest |

## 프로젝트 구조

```
lib/
├── main.dart                    # 앱 진입점, ProviderScope, GoRouter, 테마 설정
├── router.dart                  # GoRouter 전체 라우트 정의
├── db/
│   ├── database.dart            # Drift AppDatabase + 전체 테이블 정의
│   ├── database.g.dart          # build_runner 자동 생성 (수정 금지)
│   └── daos/                    # 기능별 Data Access Object
│       ├── food_dao.dart
│       ├── exercise_dao.dart
│       └── weight_dao.dart
├── features/
│   ├── onboarding/
│   │   ├── notifier.dart        # OnboardingNotifier (임시 상태, SQLite 미저장)
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
│   ├── gemini_service.dart      # Gemini 2.0 Flash Vision REST 호출
│   └── usda_service.dart        # USDA FoodData Central 음식 텍스트 검색
├── utils/
│   ├── tdee.dart                # Mifflin-St Jeor TDEE + 영양소 계산
│   ├── streaks.dart             # 연속 기록 스트릭 계산
│   └── units.dart               # kg↔lbs, cm↔ft/in, ml↔oz 단위 변환
├── widgets/
│   ├── calorie_ring.dart        # CustomPainter 도넛 링
│   ├── macro_pill.dart          # 단백질 / 탄수화물 / 지방 남은 양 필
│   ├── food_entry_card.dart     # Dismissible 음식 기록 카드 (썸네일 포함)
│   ├── ruler_picker.dart        # 숫자 입력용 수평 스크롤 룰러
│   ├── onboarding_layout.dart   # 뒤로가기 화살표 + LinearProgressIndicator 래퍼
│   └── week_strip.dart          # 7일 주간 스트립 (활성 날짜 하이라이트)
└── theme/
    └── app_theme.dart           # ThemeData 라이트 + 다크, 컬러 토큰

test/
├── utils/
│   ├── tdee_test.dart
│   ├── streaks_test.dart
│   └── units_test.dart
└── widgets/
```

## 스크린 및 온보딩 흐름

### 온보딩 (10단계)

| 단계 | 스크린 | 입력 방식 | 비고 |
|---|---|---|---|
| 1 | goal | 3개 옵션 필 | 감량 / 유지 / 근육 증량 |
| 2 | gender | 3개 옵션 필 | 남성 / 여성 / 기타 |
| 3 | birthday | 날짜 휠 피커 (showDatePicker) | TDEE 나이 계산에 사용 |
| 4 | current_weight | 룰러 피커 | 설정 단위에 따라 kg 또는 lbs |
| 5 | height | 룰러 피커 | cm 또는 ft/in |
| 6 | target_weight | 룰러 피커 | 목표 라벨 + 동적 달성 날짜 표시 |
| 7 | activity | 4개 옵션 필 | 비활동적 / 가볍게 / 활동적 / 매우 활동적 |
| 8 | diet | 복수 선택 필 | 없음 / 채식 / 비건 / 키토 / 글루텐프리 |
| 9 | results | 정적 스크린 | fl_chart 체중 예측 그래프, "사용자의 80%…" 통계 |
| 10 | plan | 편집 가능한 도넛 링 | TDEE 계산 목표, 셀별 연필 아이콘 |

마지막 단계에서 "시작하기!" 탭 → `Profiles` 테이블 INSERT → SharedPreferences `onboarding_complete = true` → `/home`으로 이동

### 메인 앱 탭

| 탭 | 주요 콘텐츠 |
|---|---|
| **홈** | 칼로리 링, 영양소 3개 필, 주간 스트립, 오늘 기록한 음식 목록, FAB "+" |
| **분석** | 체중 추이 선형 차트 (최근 90일), 주간 영양소 막대 차트, BMI, 스트릭 |
| **설정** | 테마 (라이트 / 다크 / 시스템), 단위 (kg/lbs), API 키 입력, 체중 기록 |

## 데이터 모델

### SQLite 테이블 (Drift 스키마)

```dart
Profiles        // 단일 행 — 온보딩 완료 시 생성 (목표, 성별, 체중, 키, 칼로리/영양소 목표 등)
DailyLogs       // 날짜별 1행 (YYYY-MM-DD unique), waterMl
FoodEntries     // 기록된 모든 음식 항목 (dailyLogId, name, calories, protein, carbs, fat, source, photoUri)
ExerciseEntries // 기록된 운동 (dailyLogId, name, durationMinutes, caloriesBurned)
WeightLogs      // 체중 추이 차트용 수동 체중 기록
```

### SharedPreferences 키 (비민감 설정)

```
onboarding_complete   — 최초 실행 리다이렉트 게이트 (bool)
theme                 — 'light' | 'dark' | 'system'
weight_unit           — 'kg' | 'lbs'
```

### flutter_secure_storage 키 (API 키 — Keychain / EncryptedSharedPreferences)

```
gemini_api_key        — 설정에서 사용자가 입력
usda_api_key          — 설정에서 사용자가 입력 (data.gov에서 무료 발급)
```

### Riverpod 프로바이더

- **profileProvider** — 앱 시작 시 `Profiles` 테이블에서 로드; 목표 + 영양소 목표 보관
- **dailyProvider(date)** — 홈 화면 포커스마다 해당 날짜의 `DailyLogs`, `FoodEntries`, `ExerciseEntries`에서 리하이드레이션
- **settingsProvider** — SharedPreferences를 직접 읽고 쓴다 (SQLite 없음)

## 핵심 흐름

### AI 음식 사진 스캔

```
"+" FAB → BottomSheet (카메라 / 검색 / 운동 / 수분)
→ CameraScreen (camera 패키지 전체화면) → 셔터 탭
→ base64 인코딩 → GeminiService.analyzeFood() 호출
→ Gemini 2.0 Flash: {"name","calories","protein_g","carbs_g","fat_g","serving_size","health_score"}
→ ScanResultScreen: 전체화면 사진 헤더, 편집 가능한 필드, 헬스 스코어 바
→ "✦ 결과 수정" → 수정 힌트 추가 후 Gemini 재호출
→ "완료" → FoodEntries INSERT + DailyLogs UPSERT → dailyProvider 무효화 → 홈으로 복귀
```

### 음식 텍스트 검색

```
SearchScreen → UsdaService.searchFoods()
→ USDA FoodData Central /fdc/v1/foods/search
→ 결과 목록 → 항목 탭 → 확인 바텀 시트 → DB INSERT
```

## UI 및 컬러 시스템

`.claude/screenshots/` 스크린샷을 기반으로 Cal AI 디자인을 재현한다.

| 토큰 | Hex | 용도 |
|---|---|---|
| bgPrimary (라이트) | `#FFFFFF` | 메인 배경 |
| bgSecondary (라이트) | `#F5F5F5` | 카드, 입력 필드 배경 |
| bgPrimary (다크) | `#111111` | 다크모드 메인 배경 |
| bgSecondary (다크) | `#1E1E1E` | 다크모드 카드 |
| accentOrange | `#FF5500` | 스트릭 플레임 아이콘, 강조 |
| macroProtein | `#FF6B35` | 단백질 링 / 필 색상 |
| macroCarbs | `#FFB800` | 탄수화물 링 / 필 색상 |
| macroFat | `#4A9EFF` | 지방 링 / 필 색상 |

**기본 폰트:** Inter (`google_fonts` 패키지, 대체: System sans-serif)

**핵심 컴포넌트 패턴:**
- 옵션 필 — 라이트 그레이 배경 → 탭 시 검정 배경 + 흰 텍스트 (`BorderRadius.circular(16)`)
- 도넛 링 — `CustomPainter` 원형 진행 바, 영양소 카테고리별 색상
- 룰러 피커 — 눈금이 있는 수평 스크롤뷰, 중앙 하이라이트 + 핀 값 표시
- 칼로리 링 — 홈 대형 도넛, 중앙 플레임 아이콘
- FAB "+" — 검정 `FloatingActionButton`, 우하단, 바텀 시트 기록 창 오픈

## API 연동

### Gemini 2.0 Flash Vision
- **엔드포인트:** `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent`
- **인증:** `?key=GEMINI_API_KEY` (SharedPreferences에서 읽어옴)
- **응답:** `candidates[0].content.parts[0].text`에서 JSON 파싱

### USDA FoodData Central
- **엔드포인트:** `https://api.nal.usda.gov/fdc/v1/foods/search`
- **인증:** `?api_key=USDA_API_KEY` 쿼리 파라미터 (flutter_secure_storage에서 읽어옴)
- **입력:** `?query=chicken+breast&dataType=Foundation,SR+Legacy,Branded`
- **키 발급:** [fdc.nal.usda.gov/api-key-signup](https://fdc.nal.usda.gov/api-key-signup/) — 무료, 이메일 인증만 필요

두 API 키 모두 설정 화면에서 사용자가 한 번 입력하면 flutter_secure_storage에 저장된다.

## 개발

```bash
# 의존성 설치
flutter pub get

# 개발 서버 시작
flutter run

# Drift DB 코드 생성 (스키마 변경 후)
dart run build_runner build --delete-conflicting-outputs

# 타입 검사 / 정적 분석
flutter analyze

# 코드 포맷
dart format lib/ test/

# 전체 테스트
flutter test

# 단일 테스트 파일 실행
flutter test test/utils/tdee_test.dart

# iOS 빌드 (릴리즈)
flutter build ios --release

# Android 빌드 (릴리즈)
flutter build appbundle --release
```

> **주의:** 카메라 패키지는 커스텀 네이티브 빌드가 필요하다. 카메라 기능 테스트 시 실제 기기 또는 올바르게 구성된 에뮬레이터에서 `flutter run`을 사용해야 한다.

---

# Cal AI Clone

A cross-platform mobile clone of [Cal AI](https://www.calai.app/) — an AI-powered calorie tracking app built with Flutter.

Snap a photo of any meal to instantly identify calories and nutrients using AI. The app guides users through a 10-step personalized onboarding, recognizes food via Google Gemini 2.0 Flash Vision API, and searches a food database via the free USDA FoodData Central API. All data is stored locally on-device in SQLite — no backend, no login required.

## Tech Stack

| Concern | Package | Version |
|---|---|---|
| Framework | Flutter (stable) + Dart | latest stable |
| Navigation | go_router | ^14.x |
| State | flutter_riverpod + riverpod_annotation | ^3.x |
| Local DB | drift (SQLite ORM) | ^2.x |
| Settings Store | shared_preferences | ^2.x |
| Secure Store | flutter_secure_storage | ^9.x |
| Camera | camera | ^0.11.x |
| AI Food Recognition | Google Gemini 2.0 Flash Vision API | REST |
| Food Text Search | USDA FoodData Central API | REST |
| Charts | fl_chart | ^0.69.x |
| Notifications | flutter_local_notifications | ^19.x |
| Testing | flutter_test + mocktail | built-in / latest |

## Project Structure

```
lib/
├── main.dart                    # App entry, ProviderScope, GoRouter, theme setup
├── router.dart                  # GoRouter configuration (all routes)
├── db/
│   ├── database.dart            # Drift AppDatabase + all table definitions
│   ├── database.g.dart          # Generated by build_runner (do not edit)
│   └── daos/                    # Data access objects per feature
│       ├── food_dao.dart
│       ├── exercise_dao.dart
│       └── weight_dao.dart
├── features/
│   ├── onboarding/
│   │   ├── notifier.dart        # OnboardingNotifier (temporary state, not persisted)
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
│   ├── calorie_ring.dart        # CustomPainter donut ring
│   ├── macro_pill.dart          # Protein / Carbs / Fat remaining pill
│   ├── food_entry_card.dart     # Dismissible card with photo thumbnail
│   ├── ruler_picker.dart        # Horizontal scroll ruler for numeric input
│   ├── onboarding_layout.dart   # Back arrow + LinearProgressIndicator wrapper
│   └── week_strip.dart          # 7-day strip with active day highlight
└── theme/
    └── app_theme.dart           # ThemeData light + dark, color tokens

test/
├── utils/
│   ├── tdee_test.dart
│   ├── streaks_test.dart
│   └── units_test.dart
└── widgets/
```

## Screens & Onboarding Flow

### Onboarding (10 Steps)

| Step | Screen | Input Type | Notes |
|---|---|---|---|
| 1 | goal | 3 option pills | Lose weight / Maintain / Gain muscle |
| 2 | gender | 3 option pills | Male / Female / Other |
| 3 | birthday | date wheel picker (showDatePicker) | Used for TDEE age calculation |
| 4 | current_weight | ruler picker | kg or lbs based on settings |
| 5 | height | ruler picker | cm or ft/in |
| 6 | target_weight | ruler picker | Shows goal label + dynamic target date |
| 7 | activity | 4 option pills | Sedentary / Lightly active / Active / Very active |
| 8 | diet | multi-select pills | None / Vegetarian / Vegan / Keto / Gluten-free |
| 9 | results | static screen | fl_chart weight projection graph, "80% of users…" stat |
| 10 | plan | editable donut rings | TDEE-calculated goals, pencil edit icon per cell |

Final step "Let's get started!" → `INSERT INTO Profiles` → SharedPreferences `onboarding_complete = true` → navigate to `/home`.

### Main App Tabs

| Tab | Key Content |
|---|---|
| **Home** | Calorie ring, 3 macro pills, week strip, today's food log, FAB "+" |
| **Analytics** | Weight trend line chart (last 90 days), weekly macro bar chart, BMI, streak |
| **Settings** | Theme (light / dark / system), units (kg / lbs), API key input, weight logging |

## Data Model

### SQLite Tables (Drift Schema)

```dart
Profiles        // Single row — created at end of onboarding (goal, gender, weight, height, calorie/macro goals)
DailyLogs       // One row per calendar day (YYYY-MM-DD unique), waterMl
FoodEntries     // Every logged food item (dailyLogId, name, calories, protein, carbs, fat, source, photoUri)
ExerciseEntries // Logged workouts (dailyLogId, name, durationMinutes, caloriesBurned)
WeightLogs      // Manual weight entries for the trend chart
```

### SharedPreferences Keys (non-sensitive settings)

```
onboarding_complete   — first-launch redirect gate (bool)
theme                 — 'light' | 'dark' | 'system'
weight_unit           — 'kg' | 'lbs'
```

### flutter_secure_storage Keys (API keys — Keychain / EncryptedSharedPreferences)

```
gemini_api_key        — entered by user in Settings
usda_api_key          — entered by user in Settings (free from data.gov)
```

### Riverpod Providers

- **profileProvider** — loaded from `Profiles` table at app start; holds goals + macro targets
- **dailyProvider(date)** — rehydrated from the given date's `DailyLogs`, `FoodEntries`, `ExerciseEntries` on every home screen focus
- **settingsProvider** — reads/writes SharedPreferences directly (no SQLite)

## Key Flows

### AI Food Photo Scan

```
"+" FAB → BottomSheet (Camera / Search / Exercise / Water)
→ CameraScreen (camera package fullscreen) → tap shutter
→ base64 encode → GeminiService.analyzeFood()
→ Gemini 2.0 Flash: {"name","calories","protein_g","carbs_g","fat_g","serving_size","health_score"}
→ ScanResultScreen: full-bleed photo header, editable fields, health score bar
→ "✦ Fix Results" → re-call Gemini with user's correction hint
→ "Done" → FoodEntries INSERT + DailyLogs UPSERT → dailyProvider invalidate → back to home
```

### Food Text Search

```
SearchScreen → UsdaService.searchFoods()
→ USDA FoodData Central /fdc/v1/foods/search
→ results list → tap item → confirm bottom sheet → DB INSERT
```

## UI & Color System

UI is matched to Cal AI screenshots in `.claude/screenshots/`.

| Token | Hex | Usage |
|---|---|---|
| bgPrimary (light) | `#FFFFFF` | Main background |
| bgSecondary (light) | `#F5F5F5` | Cards, input backgrounds |
| bgPrimary (dark) | `#111111` | Dark mode main background |
| bgSecondary (dark) | `#1E1E1E` | Dark mode cards |
| accentOrange | `#FF5500` | Streak flame icon, highlights |
| macroProtein | `#FF6B35` | Protein ring / pill color |
| macroCarbs | `#FFB800` | Carbs ring / pill color |
| macroFat | `#4A9EFF` | Fat ring / pill color |

**Primary font:** Inter (`google_fonts` package, fallback: System sans-serif)

**Key component patterns:**
- Option pill — light gray bg → taps to black bg + white text (`BorderRadius.circular(16)`)
- Donut ring — `CustomPainter` circular progress, color per macro category
- Ruler picker — horizontal `ListView` with tick marks, center highlight zone, pinned value display
- Calorie ring — large donut on home screen, flame icon centered
- FAB "+" — black `FloatingActionButton`, bottom-right, opens bottom sheet logger

## API Integration

### Gemini 2.0 Flash Vision
- **Endpoint:** `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent`
- **Auth:** `?key=GEMINI_API_KEY` (read from SharedPreferences)
- **Response:** JSON parsed from `candidates[0].content.parts[0].text`

### USDA FoodData Central
- **Endpoint:** `https://api.nal.usda.gov/fdc/v1/foods/search`
- **Auth:** `?api_key=USDA_API_KEY` query parameter (read from flutter_secure_storage)
- **Input:** `?query=chicken+breast&dataType=Foundation,SR+Legacy,Branded`
- **Get a key:** [fdc.nal.usda.gov/api-key-signup](https://fdc.nal.usda.gov/api-key-signup/) — free, email verification only

Both API keys are entered once by the user in Settings and stored in flutter_secure_storage.

## Development

```bash
# Install dependencies
flutter pub get

# Run on connected device / emulator
flutter run

# Generate Drift DB code (run after schema changes)
dart run build_runner build --delete-conflicting-outputs

# Type check / static analysis
flutter analyze

# Format code
dart format lib/ test/

# Run all tests
flutter test

# Run a single test file
flutter test test/utils/tdee_test.dart

# Build for iOS (release)
flutter build ios --release

# Build for Android (release)
flutter build appbundle --release
```

> **Note:** The camera package requires a native build. Use `flutter run` on a physical device or properly configured emulator for any camera-related testing.
