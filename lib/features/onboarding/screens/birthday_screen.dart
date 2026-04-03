import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/onboarding_layout.dart';
import '../notifier.dart';
import 'onboarding_widgets.dart';

class BirthdayScreen extends ConsumerWidget {
  const BirthdayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birthday = ref.watch(onboardingProvider).birthday;
    final parts = birthday.split('-');
    final display = parts.length == 3
        ? '${parts[1]}/${parts[2]}/${parts[0]}'
        : birthday;

    return OnboardingLayout(
      step: 3,
      totalSteps: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              'When were you born?',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your age helps us fine-tune your calorie targets.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 48),
            GestureDetector(
              onTap: () => _pickDate(context, ref, birthday),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cake_outlined, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        display,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            OnboardingNextButton(
              onPressed: () => context.go('/onboarding/current-weight'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(
      BuildContext context, WidgetRef ref, String current) async {
    final parts = current.split('-');
    final initial = parts.length == 3
        ? DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]))
        : DateTime(1995, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      final iso =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      ref.read(onboardingProvider.notifier).setBirthday(iso);
    }
  }
}
