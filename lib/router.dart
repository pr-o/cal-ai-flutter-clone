import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/analytics/analytics_screen.dart';
import 'features/home/home_screen.dart';
import 'features/log/camera_screen.dart';
import 'features/log/exercise_screen.dart';
import 'features/log/scan_result_screen.dart';
import 'features/log/search_screen.dart';
import 'features/log/water_screen.dart';
import 'features/onboarding/screens/activity_screen.dart';
import 'features/onboarding/screens/birthday_screen.dart';
import 'features/onboarding/screens/current_weight_screen.dart';
import 'features/onboarding/screens/diet_screen.dart';
import 'features/onboarding/screens/gender_screen.dart';
import 'features/onboarding/screens/goal_screen.dart';
import 'features/onboarding/screens/height_screen.dart';
import 'features/onboarding/screens/plan_screen.dart';
import 'features/onboarding/screens/results_screen.dart';
import 'features/onboarding/screens/target_weight_screen.dart';
import 'features/settings/settings_screen.dart';
import 'widgets/scaffold_with_nav_bar.dart';

Future<GoRouter> buildRouter() async {
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  return GoRouter(
    initialLocation: onboardingComplete ? '/home' : '/onboarding/goal',
    routes: [
      // ── Onboarding stack ──────────────────────────────────────────────────
      GoRoute(
        path: '/onboarding/goal',
        builder: (context, state) => const GoalScreen(),
      ),
      GoRoute(
        path: '/onboarding/gender',
        builder: (context, state) => const GenderScreen(),
      ),
      GoRoute(
        path: '/onboarding/birthday',
        builder: (context, state) => const BirthdayScreen(),
      ),
      GoRoute(
        path: '/onboarding/current-weight',
        builder: (context, state) => const CurrentWeightScreen(),
      ),
      GoRoute(
        path: '/onboarding/height',
        builder: (context, state) => const HeightScreen(),
      ),
      GoRoute(
        path: '/onboarding/target-weight',
        builder: (context, state) => const TargetWeightScreen(),
      ),
      GoRoute(
        path: '/onboarding/activity',
        builder: (context, state) => const ActivityScreen(),
      ),
      GoRoute(
        path: '/onboarding/diet',
        builder: (context, state) => const DietScreen(),
      ),
      GoRoute(
        path: '/onboarding/results',
        builder: (context, state) => const ResultsScreen(),
      ),
      GoRoute(
        path: '/onboarding/plan',
        builder: (context, state) => const PlanScreen(),
      ),
      // ── Log routes (pushed over shell) ───────────────────────────────────
      GoRoute(
        path: '/log/camera',
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/log/scan-result',
        builder: (context, state) =>
            ScanResultScreen(photoPath: state.extra as String),
      ),
      GoRoute(
        path: '/log/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/log/exercise',
        builder: (context, state) => const ExerciseScreen(),
      ),
      GoRoute(
        path: '/log/water',
        builder: (context, state) => const WaterScreen(),
      ),
      // ── App shell (tabs) ──────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}

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
