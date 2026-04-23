import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/settings/notifier.dart';
import '../../../utils/units.dart';
import '../../../widgets/onboarding_layout.dart';
import '../../../widgets/ruler_picker.dart';
import '../notifier.dart';
import 'onboarding_widgets.dart';

class TargetWeightScreen extends ConsumerWidget {
  const TargetWeightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ob = ref.watch(onboardingProvider);
    final unit = ref.watch(settingsProvider).weightUnit;
    final isLbs = unit == 'lbs';

    final displayValue = isLbs ? kgToLbs(ob.targetWeightKg) : ob.targetWeightKg;
    final min = isLbs ? 88.0 : 40.0;
    final max = isLbs ? 440.0 : 200.0;
    final step = isLbs ? 0.5 : 0.1;

    final goalLabel = switch (ob.goal) {
      'lose' => 'Lose weight',
      'gain' => 'Gain weight',
      _ => 'Target weight',
    };

    return OnboardingLayout(
      step: 6,
      totalSteps: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              'What is your target weight?',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Set the weight you want to reach.',
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
              label: goalLabel,
              onChanged: (v) {
                final kg = isLbs ? lbsToKg(v) : v;
                ref.read(onboardingProvider.notifier).setTargetWeight(kg);
              },
            ),
            const Spacer(),
            OnboardingNextButton(
              onPressed: () => context.push('/onboarding/activity'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
