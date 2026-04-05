import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/settings/notifier.dart';
import '../../../utils/units.dart';
import '../../../widgets/onboarding_layout.dart';
import '../../../widgets/ruler_picker.dart';
import '../notifier.dart';
import 'onboarding_widgets.dart';

class HeightScreen extends ConsumerWidget {
  const HeightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heightCm = ref.watch(onboardingProvider).heightCm;
    final unit = ref.watch(settingsProvider).weightUnit;
    final isLbs = unit == 'lbs';

    final displayValue = isLbs ? _cmToTotalInches(heightCm) : heightCm;
    final min = isLbs ? 47.0 : 120.0;
    final max = isLbs ? 96.0 : 245.0;
    const step = 1.0;
    final unitLabel = isLbs ? 'in' : 'cm';

    final (ft, inches) = cmToFtIn(heightCm);
    final ftLabel = "$ft' $inches\"";

    return OnboardingLayout(
      step: 5,
      totalSteps: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              'How tall are you?',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Height is used together with weight to set your targets.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            if (isLbs) ...[
              const SizedBox(height: 12),
              Text(
                ftLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
            const Spacer(),
            RulerPicker(
              value: displayValue,
              min: min,
              max: max,
              step: step,
              unit: unitLabel,
              onChanged: (v) {
                final cm = isLbs ? _totalInchesToCm(v) : v;
                ref.read(onboardingProvider.notifier).setHeight(cm);
              },
            ),
            const Spacer(),
            OnboardingNextButton(
              onPressed: () => context.go('/onboarding/target-weight'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  double _cmToTotalInches(double cm) => cm / 2.54;
  double _totalInchesToCm(double inches) => inches * 2.54;
}
