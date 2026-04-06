import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../features/home/notifier.dart';
import '../../features/settings/notifier.dart';
import '../../services/gemini_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/units.dart';

class ScanResultScreen extends ConsumerStatefulWidget {
  const ScanResultScreen({super.key, required this.photoPath});

  final String photoPath;

  @override
  ConsumerState<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends ConsumerState<ScanResultScreen> {
  late final TextEditingController _nameCtrl;
  bool _loading = true;
  String? _error;
  FoodScanResult? _result;
  double _servings = 1.0;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _analyze();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _analyze({String? hint}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apiKey = await ref
          .read(settingsProvider.notifier)
          .getGeminiApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _loading = false;
          _error =
              'Gemini API key not set. Add it in Settings to use AI scanning.';
        });
        return;
      }
      final bytes = await File(widget.photoPath).readAsBytes();
      final b64 = base64Encode(bytes);
      final result = await GeminiService(
        apiKey: apiKey,
      ).analyzeFood(b64, correctionHint: hint);
      setState(() {
        _result = result;
        _nameCtrl.text = result.name;
        _servings = 1.0;
        _loading = false;
      });
    } on GeminiParseException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Analysis failed: $e';
      });
    }
  }

  Future<void> _showFixDialog() async {
    final ctrl = TextEditingController();
    final hint = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fix Results'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'e.g. "This is a Caesar salad, not pasta"',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            child: const Text('Reanalyze'),
          ),
        ],
      ),
    );
    if (hint != null && hint.isNotEmpty) {
      await _analyze(hint: hint);
    }
  }

  Future<void> _done() async {
    final r = _result;
    if (r == null) return;

    final entry = FoodEntriesCompanion(
      dailyLogId: const Value(0), // overwritten by notifier
      name: Value(_nameCtrl.text.isNotEmpty ? _nameCtrl.text : r.name),
      calories: Value(r.calories * _servings),
      proteinG: Value(r.proteinG * _servings),
      carbsG: Value(r.carbsG * _servings),
      fatG: Value(r.fatG * _servings),
      servingSize: Value(r.servingSize),
      servings: Value(_servings),
      source: const Value('camera'),
      photoUri: Value(widget.photoPath),
      healthScore: Value(r.healthScore),
      loggedAt: Value(DateTime.now().toIso8601String()),
    );

    await ref.read(dailyProvider.notifier).addFoodEntry(entry);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // ── Photo header (~45% height) ─────────────────────────────────────
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(File(widget.photoPath), fit: BoxFit.cover),
                // Gradient overlay at bottom of photo
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ),
                // Back button
                SafeArea(
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Text(
                          'Nutrition',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Result content ─────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _ErrorView(message: _error!, onRetry: () => _analyze())
                : _ResultContent(
                    result: _result!,
                    servings: _servings,
                    nameCtrl: _nameCtrl,
                    onServingsChanged: (v) => setState(() => _servings = v),
                    onFix: _showFixDialog,
                    onDone: _done,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Result content widget ────────────────────────────────────────────────────

class _ResultContent extends StatelessWidget {
  const _ResultContent({
    required this.result,
    required this.servings,
    required this.nameCtrl,
    required this.onServingsChanged,
    required this.onFix,
    required this.onDone,
  });

  final FoodScanResult result;
  final double servings;
  final TextEditingController nameCtrl;
  final ValueChanged<double> onServingsChanged;
  final VoidCallback onFix;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final calories = (result.calories * servings).round();
    final protein = (result.proteinG * servings);
    final carbs = (result.carbsG * servings);
    final fat = (result.fatG * servings);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name + servings row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: nameCtrl,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Servings stepper
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: servings > 0.5
                          ? () => onServingsChanged(servings - 0.5)
                          : null,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                    ),
                    Text(
                      fmtServings(servings),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: () => onServingsChanged(servings + 0.5),
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            result.servingSize,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          // Calories
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.accentOrange,
                size: 20,
              ),
              const SizedBox(width: 6),
              const Text('Calories'),
              const Spacer(),
              Text(
                '$calories',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          // Macros row
          Row(
            children: [
              _MacroItem(
                label: 'Protein',
                value: protein,
                color: AppColors.macroProtein,
              ),
              _MacroItem(
                label: 'Carbs',
                value: carbs,
                color: AppColors.macroCarbs,
              ),
              _MacroItem(
                label: 'Fat',
                value: fat,
                color: AppColors.macroFat,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Health score
          Row(
            children: [
              const Icon(
                Icons.favorite_outline_rounded,
                size: 18,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              const Text('Health Score'),
              const Spacer(),
              Text(
                '${result.healthScore}/10',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: result.healthScore / 10,
              minHeight: 6,
              backgroundColor: Colors.green.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
          if (result.ingredients.isNotEmpty) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Ingredients'),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    result.ingredients.join(', '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onFix,
                  icon: const Text('✦', style: TextStyle(fontSize: 12)),
                  label: const Text('Fix Results'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onDone,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  const _MacroItem({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '${value.toStringAsFixed(1)}g',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
