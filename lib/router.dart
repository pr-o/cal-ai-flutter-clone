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
        pageBuilder: (context, state) =>
            _slidePage(state.pageKey, const GoalScreen()),
      ),
      GoRoute(
        path: '/onboarding/gender',
        pageBuilder: (context, state) =>
            _slidePage(state.pageKey, const GenderScreen()),
      ),
      GoRoute(
        path: '/onboarding/birthday',
        pageBuilder: (context, state) =>
            _slidePage(state.pageKey, const BirthdayScreen()),
      ),
      GoRoute(
        path: '/onboarding/current-weight',
        pageBuilder: (context, state) =>
            _slidePage(state.pageKey, const CurrentWeightScreen()),
      ),
      GoRoute(
        path: '/onboarding/height',
        pageBuilder: (context, state) =>
            _slidePage(state.pageKey, const HeightScreen()),
      ),
      GoRoute(
        path: '/onboarding/target-weight',
        pageBuilder: (context, state) =>
            _slidePage(state.pageKey, const TargetWeightScreen()),
      ),
      GoRoute(
        path: '/onboarding/activity',
        pageBuilder: (context, state) =>
            _slidePage(state.pageKey, const ActivityScreen()),
      ),
      GoRoute(
        path: '/onboarding/diet',
        pageBuilder: (context, state) =>
            _slidePage(state.pageKey, const DietScreen()),
      ),
      GoRoute(
        path: '/onboarding/results',
        pageBuilder: (context, state) =>
            _slidePage(state.pageKey, const ResultsScreen()),
      ),
      GoRoute(
        path: '/onboarding/plan',
        pageBuilder: (context, state) =>
            _slidePage(state.pageKey, const PlanScreen()),
      ),
      // ── Log routes (pushed over shell) ───────────────────────────────────
      GoRoute(
        path: '/log/camera',
        pageBuilder: (context, state) =>
            _slideUpPage(state.pageKey, const CameraScreen()),
      ),
      GoRoute(
        path: '/log/scan-result',
        pageBuilder: (context, state) => _slideUpPage(
          state.pageKey,
          ScanResultScreen(photoPath: state.extra as String),
        ),
      ),
      GoRoute(
        path: '/log/search',
        pageBuilder: (context, state) =>
            _slideUpPage(state.pageKey, const SearchScreen()),
      ),
      GoRoute(
        path: '/log/exercise',
        pageBuilder: (context, state) =>
            _slideUpPage(state.pageKey, const ExerciseScreen()),
      ),
      GoRoute(
        path: '/log/water',
        pageBuilder: (context, state) =>
            _slideUpPage(state.pageKey, const WaterScreen()),
      ),
      // ── App shell (tabs) ──────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const HomeScreen()),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const AnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

CustomTransitionPage<void> _slidePage(LocalKey key, Widget child) =>
    CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: child,
          ),
    );

CustomTransitionPage<void> _slideUpPage(LocalKey key, Widget child) =>
    CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
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
