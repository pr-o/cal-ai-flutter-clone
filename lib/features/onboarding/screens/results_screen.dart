import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/onboarding_layout.dart';
import 'onboarding_widgets.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      step: 9,
      totalSteps: 10,
      onBack: () => context.go('/onboarding/diet'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              'Cal AI creates\nlong-term results',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            _ResultsChart(),
            const SizedBox(height: 16),
            _StatCard(),
            const Spacer(),
            OnboardingNextButton(
              onPressed: () => context.go('/onboarding/plan'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ResultsChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final calAiSpots = [
      const FlSpot(0, 80),
      const FlSpot(1, 78),
      const FlSpot(2, 75),
      const FlSpot(3, 73),
      const FlSpot(4, 71),
      const FlSpot(5, 70),
      const FlSpot(6, 69.5),
    ];

    final traditionalSpots = [
      const FlSpot(0, 80),
      const FlSpot(1, 77),
      const FlSpot(2, 76),
      const FlSpot(3, 77),
      const FlSpot(4, 79),
      const FlSpot(5, 81),
      const FlSpot(6, 83),
    ];

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          minX: 0,
          maxX: 6,
          minY: 65,
          maxY: 88,
          lineBarsData: [
            LineChartBarData(
              spots: calAiSpots,
              isCurved: true,
              color: Theme.of(context).colorScheme.onSurface,
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: traditionalSpots,
              isCurved: true,
              color: const Color(0xFFFF8A80),
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFFF8A80).withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🍎', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '80% of Cal AI users maintain their weight loss even 6 months later.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
