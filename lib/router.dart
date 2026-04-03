import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/home/home_screen.dart';
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

Future<GoRouter> buildRouter() async {
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete =
      prefs.getBool('onboarding_complete') ?? false;

  return GoRouter(
    initialLocation:
        onboardingComplete ? '/home' : '/onboarding/goal',
    routes: [
      // ── Onboarding stack ────────────────────────────────────────────────────
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
      // ── App shell ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
}
