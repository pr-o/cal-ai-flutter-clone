import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/onboarding_layout.dart';
import '../notifier.dart';
import 'onboarding_widgets.dart';

class GoalScreen extends ConsumerWidget {
  const GoalScreen({super.key});

  static const _options = [
    ('lose', 'Lose weight', 'Burn fat and reach your goal weight'),
    (
      'maintain',
      'Maintain weight',
      'Keep your current weight and stay healthy',
    ),
    ('gain', 'Gain weight', 'Build muscle and increase body mass'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).goal;

    return OnboardingLayout(
      step: 1,
      totalSteps: 10,
      onBack: null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              'What is your goal?',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll personalize your plan based on your goal.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 32),
            ..._options.map(
              (opt) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OnboardingOptionPill(
                  label: opt.$2,
                  subtitle: opt.$3,
                  selected: selected == opt.$1,
                  onTap: () =>
                      ref.read(onboardingProvider.notifier).setGoal(opt.$1),
                ),
              ),
            ),
            const Spacer(),
            OnboardingNextButton(
              onPressed: () => context.go('/onboarding/gender'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
