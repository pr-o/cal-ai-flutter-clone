import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/onboarding_layout.dart';
import '../notifier.dart';
import 'onboarding_widgets.dart';

class GenderScreen extends ConsumerWidget {
  const GenderScreen({super.key});

  static const _options = [
    ('male', 'Male'),
    ('female', 'Female'),
    ('other', 'Other'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).gender;

    return OnboardingLayout(
      step: 2,
      totalSteps: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              'What is your gender?',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'This helps us calculate your calorie needs accurately.',
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
                  selected: selected == opt.$1,
                  onTap: () =>
                      ref.read(onboardingProvider.notifier).setGender(opt.$1),
                ),
              ),
            ),
            const Spacer(),
            OnboardingNextButton(
              onPressed: () => context.push('/onboarding/birthday'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
