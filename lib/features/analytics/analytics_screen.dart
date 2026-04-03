import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/notifier.dart';
import 'notifier.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogWeightSheet(context, ref),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.monitor_weight_outlined),
        label: const Text('Log Weight'),
      ),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (analytics) {
          final profile = profileAsync.value;
          final targetWeight = profile?.targetWeightKg;
          final heightCm = profile?.heightCm;
          final latestWeight = analytics.latestWeightKg;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(analyticsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                // Streak + BMI row
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: '🔥',
                        label: 'Current Streak',
                        value: '${analytics.streakDays} days',
                        color: const Color(0xFFFF5500),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BmiCard(
                        heightCm: heightCm,
                        weightKg: latestWeight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Weight trend chart
                _SectionHeader('Weight Trend (90 days)'),
                const SizedBox(height: 8),
                _WeightChart(
                  logs: analytics.weightHistory,
                  targetWeightKg: targetWeight,
                ),
                const SizedBox(height: 16),
                // Weekly macros chart
                _SectionHeader('Weekly Nutrition'),
                const SizedBox(height: 8),
                _MacroBarChart(days: analytics.weeklyMacros),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLogWeightSheet(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Log today's weight",
                style: Theme.of(ctx)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,1}')),
              ],
              decoration: InputDecoration(
                hintText: '70.0',
                suffixText: 'kg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final kg = double.tryParse(ctrl.text);
                if (kg == null || kg <= 0) return;
                Navigator.of(ctx).pop();
                await ref.read(analyticsProvider.notifier).logWeight(kg);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Weight chart ─────────────────────────────────────────────────────────────

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.logs, this.targetWeightKg});
  final List logs; // List<WeightLog>
  final double? targetWeightKg;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return _EmptyChart(
        message: 'No weight logged yet.\nTap "Log Weight" to get started.',
      );
    }

    final spots = logs.asMap().entries.map((e) {
      final log = e.value;
      return FlSpot(e.key.toDouble(), (log.weightKg as double));
    }).toList();

    final weights = spots.map((s) => s.y).toList();
    final minY = (weights.reduce((a, b) => a < b ? a : b) - 2)
        .clamp(0.0, double.infinity);
    final maxY = weights.reduce((a, b) => a > b ? a : b) + 2;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            bottomTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.black,
              barWidth: 2.5,
              dotData: FlDotData(
                show: spots.length < 10,
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.black.withValues(alpha: 0.06),
              ),
            ),
            if (targetWeightKg != null)
              LineChartBarData(
                spots: [
                  FlSpot(0, targetWeightKg!),
                  FlSpot((spots.length - 1).toDouble(), targetWeightKg!),
                ],
                isCurved: false,
                color: const Color(0xFFFF5500).withValues(alpha: 0.6),
                barWidth: 1.5,
                dashArray: [6, 4],
                dotData: const FlDotData(show: false),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Macro bar chart ──────────────────────────────────────────────────────────

class _MacroBarChart extends StatelessWidget {
  const _MacroBarChart({required this.days});
  final List<WeeklyMacroDay> days;

  @override
  Widget build(BuildContext context) {
    final hasData = days.any((d) => d.calories > 0);
    if (!hasData) {
      return _EmptyChart(message: 'Log food to see your weekly nutrition.');
    }

    final dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= days.length) {
                          return const SizedBox.shrink();
                        }
                        final date = DateTime.parse(days[idx].date);
                        return Text(
                          dayLabels[date.weekday % 7],
                          style: Theme.of(context).textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: days.asMap().entries.map((e) {
                  final i = e.key;
                  final d = e.value;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: d.proteinG + d.carbsG + d.fatG,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                        rodStackItems: [
                          BarChartRodStackItem(
                              0, d.proteinG, const Color(0xFFFF6B35)),
                          BarChartRodStackItem(d.proteinG,
                              d.proteinG + d.carbsG, const Color(0xFFFFB800)),
                          BarChartRodStackItem(
                              d.proteinG + d.carbsG,
                              d.proteinG + d.carbsG + d.fatG,
                              const Color(0xFF4A9EFF)),
                        ],
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _LegendDot(color: Color(0xFFFF6B35), label: 'Protein'),
              SizedBox(width: 12),
              _LegendDot(color: Color(0xFFFFB800), label: 'Carbs'),
              SizedBox(width: 12),
              _LegendDot(color: Color(0xFF4A9EFF), label: 'Fat'),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final String icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  )),
        ],
      ),
    );
  }
}

class _BmiCard extends StatelessWidget {
  const _BmiCard({this.heightCm, this.weightKg});
  final double? heightCm;
  final double? weightKg;

  @override
  Widget build(BuildContext context) {
    double? bmi;
    String label = 'N/A';
    Color color = Colors.grey;

    if (heightCm != null && weightKg != null && heightCm! > 0) {
      final hM = heightCm! / 100;
      bmi = weightKg! / (hM * hM);
      if (bmi < 18.5) {
        label = 'Underweight';
        color = Colors.blue;
      } else if (bmi < 25) {
        label = 'Normal';
        color = Colors.green;
      } else if (bmi < 30) {
        label = 'Overweight';
        color = Colors.orange;
      } else {
        label = 'Obese';
        color = Colors.red;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚖️', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            bmi != null ? bmi.toStringAsFixed(1) : '—',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800, color: color),
          ),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  )),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
