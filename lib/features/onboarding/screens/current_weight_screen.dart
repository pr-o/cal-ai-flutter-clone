import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/settings/notifier.dart';
import '../../../utils/units.dart';
import '../../../widgets/onboarding_layout.dart';
import '../../../widgets/ruler_picker.dart';
import '../notifier.dart';
import 'onboarding_widgets.dart';

class CurrentWeightScreen extends ConsumerWidget {
  const CurrentWeightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightKg = ref.watch(onboardingProvider).currentWeightKg;
    final unit = ref.watch(settingsProvider).weightUnit;
    final isLbs = unit == 'lbs';

    final displayValue = isLbs ? kgToLbs(weightKg) : weightKg;
    final min = isLbs ? 88.0 : 40.0;
    final max = isLbs ? 440.0 : 200.0;
    final step = isLbs ? 0.5 : 0.1;

    return OnboardingLayout(
      step: 4,
      totalSteps: 10,
      onBack: () => context.go('/onboarding/birthday'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              'What is your current weight?',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'We need this to calculate your daily calorie target.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const Spacer(),
            RulerPicker(
              value: displayValue,
              min: min,
              max: max,
              step: step,
              unit: unit,
              onChanged: (v) {
                final kg = isLbs ? lbsToKg(v) : v;
                ref.read(onboardingProvider.notifier).setCurrentWeight(kg);
              },
            ),
            const Spacer(),
            OnboardingNextButton(
              onPressed: () => context.go('/onboarding/height'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
