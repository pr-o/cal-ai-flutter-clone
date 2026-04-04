import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../utils/streaks.dart';
import '../../widgets/calorie_ring.dart';
import '../../widgets/food_entry_card.dart';
import '../../widgets/macro_pill.dart';
import '../../widgets/week_strip.dart';
import 'notifier.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final dailyAsync = ref.watch(dailyProvider);
    final profileAsync = ref.watch(profileProvider);

    // Collect all logged dates for the week strip dot indicators
    final loggedDates = dailyAsync.value != null
        ? {dailyAsync.value!.date}
        : <String>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🍎 Cal AI',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          _StreakBadge(
            dates:
                dailyAsync.value?.foodEntries
                    .map((e) => e.loggedAt.substring(0, 10))
                    .toList() ??
                [],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: dailyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (daily) {
          final profile = profileAsync.value;
          final goalCalories = profile?.dailyCalories ?? 2000;
          final goalProtein = profile?.dailyProteinG ?? 150;
          final goalCarbs = profile?.dailyCarbsG ?? 200;
          final goalFat = profile?.dailyFatG ?? 65;

          final remaining =
              goalCalories -
              daily.caloriesConsumed +
              daily.caloriesFromExercise;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(dailyProvider),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: WeekStrip(
                      selectedDate: selectedDate,
                      loggedDates: loggedDates,
                      onDaySelected: (date) =>
                          ref.read(selectedDateProvider.notifier).select(date),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _CalorieCard(
                      consumed: daily.caloriesConsumed,
                      remaining: remaining,
                      goal: goalCalories,
                      burned: daily.caloriesFromExercise,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: MacroPill(
                            type: MacroType.protein,
                            remaining:
                                (goalProtein - daily.macrosConsumed.proteinG)
                                    .clamp(0, goalProtein.toDouble()),
                            goal: goalProtein.toDouble(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MacroPill(
                            type: MacroType.carbs,
                            remaining: (goalCarbs - daily.macrosConsumed.carbsG)
                                .clamp(0, goalCarbs.toDouble()),
                            goal: goalCarbs.toDouble(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MacroPill(
                            type: MacroType.fat,
                            remaining: (goalFat - daily.macrosConsumed.fatG)
                                .clamp(0, goalFat.toDouble()),
                            goal: goalFat.toDouble(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'Recently logged',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (daily.foodEntries.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList.separated(
                      itemCount: daily.foodEntries.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final entry = daily.foodEntries[i];
                        return FoodEntryCard(
                          id: entry.id,
                          name: entry.name,
                          calories: entry.calories.round(),
                          proteinG: entry.proteinG,
                          carbsG: entry.carbsG,
                          fatG: entry.fatG,
                          imageUrl: entry.photoUri,
                          loggedAt: _formatTime(entry.loggedAt),
                          onDismissed: () => ref
                              .read(dailyProvider.notifier)
                              .deleteFoodEntry(entry.id),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLogSheet(context),
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        foregroundColor: Theme.of(context).colorScheme.surface,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  void _showLogSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  ctx,
                ).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Scan food'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.push('/log/camera');
              },
            ),
            ListTile(
              leading: const Icon(Icons.search_rounded),
              title: const Text('Search food'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.push('/log/search');
              },
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center_rounded),
              title: const Text('Log exercise'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.push('/log/exercise');
              },
            ),
            ListTile(
              leading: const Icon(Icons.water_drop_outlined),
              title: const Text('Log water'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.push('/log/water');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatTime(String isoTimestamp) {
    try {
      final dt = DateTime.parse(isoTimestamp).toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final min = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour < 12 ? 'AM' : 'PM';
      return '$hour:$min $ampm';
    } catch (_) {
      return '';
    }
  }
}

// ─── Calorie summary card ─────────────────────────────────────────────────────

class _CalorieCard extends StatelessWidget {
  const _CalorieCard({
    required this.consumed,
    required this.remaining,
    required this.goal,
    required this.burned,
  });

  final int consumed;
  final int remaining;
  final int goal;
  final int burned;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$remaining',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Calories left',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.restaurant_outlined,
                      label: '$consumed eaten',
                    ),
                    const SizedBox(width: 8),
                    if (burned > 0)
                      _StatChip(
                        icon: Icons.directions_run_rounded,
                        label: '$burned burned',
                        color: const Color(0xFFFF5500),
                      ),
                  ],
                ),
              ],
            ),
          ),
          CalorieRing(consumed: consumed, goal: goal, size: 140),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c =
        color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c),
        ),
      ],
    );
  }
}

// ─── Streak badge ─────────────────────────────────────────────────────────────

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.dates});
  final List<String> dates;

  @override
  Widget build(BuildContext context) {
    final streak = calculateStreak(dates);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5500),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            size: 72,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          Text(
            'No food logged yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to log your first meal',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
