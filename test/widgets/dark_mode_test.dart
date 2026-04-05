import 'package:cal_ai_flutter_clone/theme/app_theme.dart';
import 'package:cal_ai_flutter_clone/widgets/calorie_ring.dart';
import 'package:cal_ai_flutter_clone/widgets/food_entry_card.dart';
import 'package:cal_ai_flutter_clone/widgets/macro_pill.dart';
import 'package:cal_ai_flutter_clone/widgets/onboarding_layout.dart';
import 'package:cal_ai_flutter_clone/widgets/ruler_picker.dart';
import 'package:cal_ai_flutter_clone/widgets/week_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  // ── CalorieRing ────────────────────────────────────────────────────────────
  group('CalorieRing', () {
    testWidgets('renders in light mode', (tester) async {
      await tester.pumpWidget(
        _light(const CalorieRing(consumed: 800, goal: 2000)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(CalorieRing), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        _dark(const CalorieRing(consumed: 800, goal: 2000)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(CalorieRing), findsOneWidget);
    });
  });

  // ── MacroPill ─────────────────────────────────────────────────────────────
  group('MacroPill', () {
    testWidgets('renders protein in light mode', (tester) async {
      await tester.pumpWidget(
        _light(
          const MacroPill(type: MacroType.protein, remaining: 80, goal: 150),
        ),
      );
      expect(find.byType(MacroPill), findsOneWidget);
    });

    testWidgets('renders carbs in dark mode', (tester) async {
      await tester.pumpWidget(
        _dark(
          const MacroPill(type: MacroType.carbs, remaining: 120, goal: 250),
        ),
      );
      expect(find.byType(MacroPill), findsOneWidget);
    });

    testWidgets('renders fat in dark mode', (tester) async {
      await tester.pumpWidget(
        _dark(const MacroPill(type: MacroType.fat, remaining: 30, goal: 65)),
      );
      expect(find.byType(MacroPill), findsOneWidget);
    });
  });

  // ── FoodEntryCard ──────────────────────────────────────────────────────────
  group('FoodEntryCard', () {
    testWidgets('renders in light mode', (tester) async {
      await tester.pumpWidget(
        _light(
          FoodEntryCard(
            id: 1,
            name: 'Chicken Salad',
            calories: 350,
            proteinG: 30.0,
            carbsG: 15.0,
            fatG: 10.0,
            onDismissed: () {},
          ),
        ),
      );
      expect(find.byType(FoodEntryCard), findsOneWidget);
      expect(find.text('Chicken Salad'), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        _dark(
          FoodEntryCard(
            id: 2,
            name: 'Greek Yogurt',
            calories: 150,
            proteinG: 18.0,
            carbsG: 12.0,
            fatG: 4.0,
            onDismissed: () {},
            loggedAt: '12:46 PM',
          ),
        ),
      );
      expect(find.byType(FoodEntryCard), findsOneWidget);
      expect(find.text('Greek Yogurt'), findsOneWidget);
    });
  });

  // ── WeekStrip ─────────────────────────────────────────────────────────────
  group('WeekStrip', () {
    final today = () {
      final now = DateTime.now();
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }();

    testWidgets('renders in light mode', (tester) async {
      await tester.pumpWidget(
        _light(WeekStrip(selectedDate: today, onDaySelected: (_) {})),
      );
      expect(find.byType(WeekStrip), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        _dark(
          WeekStrip(
            selectedDate: today,
            onDaySelected: (_) {},
            loggedDates: {today},
          ),
        ),
      );
      expect(find.byType(WeekStrip), findsOneWidget);
    });
  });

  // ── RulerPicker ───────────────────────────────────────────────────────────
  group('RulerPicker', () {
    testWidgets('renders in light mode', (tester) async {
      await tester.pumpWidget(
        _light(
          RulerPicker(
            value: 70.0,
            min: 40.0,
            max: 200.0,
            step: 0.5,
            unit: 'kg',
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(RulerPicker), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        _dark(
          RulerPicker(
            value: 70.0,
            min: 40.0,
            max: 200.0,
            step: 0.5,
            unit: 'kg',
            onChanged: (_) {},
            label: 'Lose weight',
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(RulerPicker), findsOneWidget);
    });
  });

  // ── OnboardingLayout ──────────────────────────────────────────────────────
  group('OnboardingLayout', () {
    testWidgets('renders in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.light,
          home: const OnboardingLayout(
            step: 3,
            totalSteps: 10,
            child: SizedBox(),
          ),
        ),
      );
      expect(find.byType(OnboardingLayout), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.dark,
          home: const OnboardingLayout(
            step: 3,
            totalSteps: 10,
            child: SizedBox(),
          ),
        ),
      );
      expect(find.byType(OnboardingLayout), findsOneWidget);
    });
  });
}
