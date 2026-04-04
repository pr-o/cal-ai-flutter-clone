import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../db/database.dart';
import '../../../features/settings/notifier.dart';
import '../../../utils/tdee.dart';
import '../../../widgets/onboarding_layout.dart';
import '../notifier.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _computeTdee());
  }

  void _computeTdee() {
    final ob = ref.read(onboardingProvider);
    final result = calculateTdee(TdeeInput(
      currentWeightKg: ob.currentWeightKg,
      heightCm: ob.heightCm,
      birthday: ob.birthday,
      gender: ob.gender,
      activityLevel: ob.activityLevel,
      goal: ob.goal,
    ));
    ref.read(onboardingProvider.notifier).setPlanTargets(
          calories: result.calories,
          proteinG: result.proteinG,
          carbsG: result.carbsG,
          fatG: result.fatG,
        );
  }

  String _goalDateEstimate(OnboardingState ob) {
    final diff = (ob.currentWeightKg - ob.targetWeightKg).abs();
    if (diff < 0.5) return 'You\'re already at your goal!';

    // Rough estimate: 0.5 kg/week for lose/gain
    final weeksNeeded = (diff / 0.5).ceil();
    final targetDate =
        DateTime.now().add(Duration(days: weeksNeeded * 7));
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[targetDate.month - 1]} ${targetDate.day}, ${targetDate.year}';
  }

  Future<void> _saveAndStart() async {
    setState(() => _saving = true);
    try {
      final ob = ref.read(onboardingProvider);
      final db = ref.read(databaseProvider);

      await db.into(db.profiles).insert(ProfilesCompanion(
            goal: Value(ob.goal),
            gender: Value(ob.gender),
            birthday: Value(ob.birthday),
            currentWeightKg: Value(ob.currentWeightKg),
            heightCm: Value(ob.heightCm),
            targetWeightKg: Value(ob.targetWeightKg),
            activityLevel: Value(ob.activityLevel),
            dietaryPreferences:
                Value(jsonEncode(ob.dietaryPreferences.toList())),
            dailyCalories: Value(ob.dailyCalories),
            dailyProteinG: Value(ob.dailyProteinG),
            dailyCarbsG: Value(ob.dailyCarbsG),
            dailyFatG: Value(ob.dailyFatG),
            createdAt: Value(DateTime.now().toIso8601String()),
          ));

      await ref
          .read(settingsProvider.notifier)
          .setOnboardingComplete(true);

      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ob = ref.watch(onboardingProvider);

    return OnboardingLayout(
      step: 10,
      totalSteps: 10,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.check_circle_outline_rounded,
                size: 48, color: Color(0xFFFF5500)),
            const SizedBox(height: 16),
            Text(
              'Congratulations,\nyour custom plan is ready!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
            ),
            const SizedBox(height: 12),
            if (ob.goal != 'maintain') ...[
              Text(
                ob.goal == 'lose'
                    ? 'You should lose: ${(ob.currentWeightKg - ob.targetWeightKg).abs().toStringAsFixed(1)} kg by ${_goalDateEstimate(ob)}'
                    : 'You should gain: ${(ob.targetWeightKg - ob.currentWeightKg).abs().toStringAsFixed(1)} kg by ${_goalDateEstimate(ob)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              'Daily recommendation · You can edit this anytime',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
            ),
            const SizedBox(height: 24),
            // 2×2 grid of editable macro targets
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
              children: [
                _MacroCell(
                  label: 'Calories',
                  value: ob.dailyCalories,
                  unit: 'kcal',
                  color: const Color(0xFFFF5500),
                  onEdit: (v) => ref
                      .read(onboardingProvider.notifier)
                      .setPlanTargets(
                        calories: v,
                        proteinG: ob.dailyProteinG,
                        carbsG: ob.dailyCarbsG,
                        fatG: ob.dailyFatG,
                      ),
                ),
                _MacroCell(
                  label: 'Protein',
                  value: ob.dailyProteinG,
                  unit: 'g',
                  color: const Color(0xFFFF6B35),
                  onEdit: (v) => ref
                      .read(onboardingProvider.notifier)
                      .setPlanTargets(
                        calories: ob.dailyCalories,
                        proteinG: v,
                        carbsG: ob.dailyCarbsG,
                        fatG: ob.dailyFatG,
                      ),
                ),
                _MacroCell(
                  label: 'Carbs',
                  value: ob.dailyCarbsG,
                  unit: 'g',
                  color: const Color(0xFFFFB800),
                  onEdit: (v) => ref
                      .read(onboardingProvider.notifier)
                      .setPlanTargets(
                        calories: ob.dailyCalories,
                        proteinG: ob.dailyProteinG,
                        carbsG: v,
                        fatG: ob.dailyFatG,
                      ),
                ),
                _MacroCell(
                  label: 'Fat',
                  value: ob.dailyFatG,
                  unit: 'g',
                  color: const Color(0xFF4A9EFF),
                  onEdit: (v) => ref
                      .read(onboardingProvider.notifier)
                      .setPlanTargets(
                        calories: ob.dailyCalories,
                        proteinG: ob.dailyProteinG,
                        carbsG: ob.dailyCarbsG,
                        fatG: v,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _saveAndStart,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Let's get started!",
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _MacroCell extends StatelessWidget {
  const _MacroCell({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.onEdit,
  });

  final String label;
  final int value;
  final String unit;
  final Color color;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Value content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$value',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
              ),
              Text(
                unit,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          // Pencil edit button — bottom right
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => _showEditDialog(context),
              child: Icon(
                Icons.edit_outlined,
                size: 18,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: '$value');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: unit,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text);
              if (parsed != null && parsed > 0) onEdit(parsed);
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
