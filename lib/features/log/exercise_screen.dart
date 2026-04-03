import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../features/home/notifier.dart';
import '../../utils/exercise.dart';

class ExerciseScreen extends ConsumerStatefulWidget {
  const ExerciseScreen({super.key});

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen> {
  final _durationCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  String _selectedExercise = kExerciseSuggestions.first;
  bool _saving = false;

  @override
  void dispose() {
    _durationCtrl.dispose();
    _caloriesCtrl.dispose();
    super.dispose();
  }

  void _onExerciseSelected(String name) {
    setState(() => _selectedExercise = name);
    _recalcCalories();
  }

  void _recalcCalories() {
    final minutes = int.tryParse(_durationCtrl.text) ?? 0;
    if (minutes <= 0) return;

    final profile = ref.read(profileProvider).value;
    final weightKg = profile?.currentWeightKg ?? 70.0;

    final cal = estimateCaloriesBurned(
      exerciseName: _selectedExercise,
      durationMinutes: minutes,
      weightKg: weightKg,
    );
    _caloriesCtrl.text = cal.round().toString();
  }

  Future<void> _log() async {
    final minutes = int.tryParse(_durationCtrl.text);
    final calories = double.tryParse(_caloriesCtrl.text);

    if (minutes == null || minutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid duration.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final entry = ExerciseEntriesCompanion(
        dailyLogId: const Value(0), // overwritten by notifier
        name: Value(_selectedExercise),
        durationMinutes: Value(minutes),
        caloriesBurned: Value(calories ?? 0),
        loggedAt: Value(DateTime.now().toIso8601String()),
      );
      await ref.read(dailyProvider.notifier).addExerciseEntry(entry);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Exercise')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Exercise',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            // Exercise autocomplete
            Autocomplete<String>(
              initialValue:
                  TextEditingValue(text: _selectedExercise),
              optionsBuilder: (value) {
                if (value.text.isEmpty) return kExerciseSuggestions;
                return kExerciseSuggestions.where((e) => e
                    .toLowerCase()
                    .contains(value.text.toLowerCase()));
              },
              onSelected: _onExerciseSelected,
              fieldViewBuilder:
                  (context, ctrl, focusNode, onSubmitted) {
                return TextField(
                  controller: ctrl,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'e.g. Running',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onChanged: (v) {
                    setState(() => _selectedExercise = v);
                    _recalcCalories();
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            Text('Duration (minutes)',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '30',
                suffixText: 'min',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              onChanged: (_) => _recalcCalories(),
            ),
            const SizedBox(height: 20),
            Text('Calories burned',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Auto-estimated — tap to override',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _caloriesCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '250',
                suffixText: 'kcal',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _log,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Log Exercise',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
