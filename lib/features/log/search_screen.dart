import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../features/home/notifier.dart';
import '../../features/settings/notifier.dart';
import '../../services/usda_service.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _focus = FocusNode();
  final _ctrl = TextEditingController();
  Timer? _debounce;

  List<FoodSearchResult> _results = [];
  bool _loading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    _ctrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final q = _ctrl.text.trim();
    if (q == _query) return;
    setState(() => _query = q);

    _debounce?.cancel();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q));
  }

  Future<void> _search(String q) async {
    final apiKey = await ref.read(settingsProvider.notifier).getUsdaApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'USDA API key not set. Add it in Settings to search foods.',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final results = await UsdaService(apiKey: apiKey).searchFoods(q);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showConfirmSheet(FoodSearchResult result) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ConfirmSheet(
        result: result,
        onAdd: () async {
          Navigator.of(ctx).pop();
          final entry = FoodEntriesCompanion(
            dailyLogId: const Value(0),
            name: Value(result.name),
            calories: Value(result.calories),
            proteinG: Value(result.proteinG),
            carbsG: Value(result.carbsG),
            fatG: Value(result.fatG),
            servingSize: Value(result.servingSize),
            servings: const Value(1.0),
            source: const Value('search'),
            loggedAt: Value(DateTime.now().toIso8601String()),
          );
          await ref.read(dailyProvider.notifier).addFoodEntry(entry);
          if (mounted) context.go('/home');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          focusNode: _focus,
          decoration: InputDecoration(
            hintText: 'Search foods…',
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _ctrl.clear();
                      setState(() {
                        _query = '';
                        _results = [];
                      });
                    },
                  )
                : null,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: _search,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_query.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              'Search for a food',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          'No results for "$_query"',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final r = _results[i];
        return ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.restaurant_outlined,
              size: 24,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          title: Text(
            r.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${r.calories.round()} kcal · ${r.servingSize}'
            '${r.brandOwner.isNotEmpty ? ' · ${r.brandOwner}' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.add_circle_outline_rounded),
          onTap: () => _showConfirmSheet(r),
        );
      },
    );
  }
}

// ─── Confirm bottom sheet ─────────────────────────────────────────────────────

class _ConfirmSheet extends StatefulWidget {
  const _ConfirmSheet({required this.result, required this.onAdd});
  final FoodSearchResult result;
  final VoidCallback onAdd;

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  double _servings = 1.0;

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final calories = (r.calories * _servings).round();
    final protein = r.proteinG * _servings;
    final carbs = r.carbsG * _servings;
    final fat = r.fatG * _servings;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              r.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (r.brandOwner.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                r.brandOwner,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Servings stepper
            Row(
              children: [
                Text('Servings', style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _servings > 0.5
                      ? () => setState(() => _servings -= 0.5)
                      : null,
                ),
                Text(
                  _servings == _servings.truncate()
                      ? '${_servings.toInt()}'
                      : '$_servings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _servings += 0.5),
                ),
              ],
            ),
            Text(
              r.servingSize,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const Divider(height: 24),
            // Macro breakdown
            _MacroRow(
              icon: Icons.local_fire_department_rounded,
              color: const Color(0xFFFF5500),
              label: 'Calories',
              value: '$calories kcal',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _MacroBadge(
                  label: 'Protein',
                  value: '${protein.toStringAsFixed(1)}g',
                  color: const Color(0xFFFF6B35),
                ),
                const SizedBox(width: 8),
                _MacroBadge(
                  label: 'Carbs',
                  value: '${carbs.toStringAsFixed(1)}g',
                  color: const Color(0xFFFFB800),
                ),
                const SizedBox(width: 8),
                _MacroBadge(
                  label: 'Fat',
                  value: '${fat.toStringAsFixed(1)}g',
                  color: const Color(0xFF4A9EFF),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: widget.onAdd,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Add to log',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _MacroBadge extends StatelessWidget {
  const _MacroBadge({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
      ),
    );
  }
}
