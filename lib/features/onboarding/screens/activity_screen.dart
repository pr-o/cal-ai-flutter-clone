import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/onboarding_layout.dart';
import '../notifier.dart';
import 'onboarding_widgets.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  static const _options = [
    ('sedentary', 'Sedentary', 'Little or no exercise, desk job'),
    ('lightly_active', 'Lightly active', 'Light exercise 1–3 days/week'),
    ('active', 'Active', 'Moderate exercise 3–5 days/week'),
    ('very_active', 'Very active',
        'Hard exercise 6–7 days/week or physical job'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).activityLevel;

    return OnboardingLayout(
      step: 7,
      totalSteps: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              'How active are you?',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your activity level affects your daily calorie burn.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 32),
            ..._options.map((opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OnboardingOptionPill(
                    label: opt.$2,
                    subtitle: opt.$3,
                    selected: selected == opt.$1,
                    onTap: () => ref
                        .read(onboardingProvider.notifier)
                        .setActivityLevel(opt.$1),
                  ),
                )),
            const Spacer(),
            OnboardingNextButton(
              onPressed: () => context.go('/onboarding/diet'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
