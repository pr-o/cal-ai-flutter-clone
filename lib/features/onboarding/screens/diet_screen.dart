import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/onboarding_layout.dart';
import '../notifier.dart';
import 'onboarding_widgets.dart';

class DietScreen extends ConsumerWidget {
  const DietScreen({super.key});

  static const _options = [
    ('none', 'No restrictions'),
    ('vegetarian', 'Vegetarian'),
    ('vegan', 'Vegan'),
    ('keto', 'Keto'),
    ('gluten_free', 'Gluten-free'),
    ('dairy_free', 'Dairy-free'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).dietaryPreferences;

    return OnboardingLayout(
      step: 8,
      totalSteps: 10,
      onBack: () => context.go('/onboarding/activity'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              'Any dietary preferences?',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Select all that apply. You can change this later.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _options.map((opt) {
                final isSelected = selected.contains(opt.$1);
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return GestureDetector(
                  onTap: () =>
                      ref.read(onboardingProvider.notifier).toggleDiet(opt.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFF0F0F0)),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      opt.$2,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? (isDark ? Colors.black : Colors.white)
                            : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            OnboardingNextButton(
              onPressed: () => context.go('/onboarding/results'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
