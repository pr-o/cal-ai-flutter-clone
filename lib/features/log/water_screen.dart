import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/notifier.dart';

class WaterScreen extends ConsumerStatefulWidget {
  const WaterScreen({super.key});

  @override
  ConsumerState<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends ConsumerState<WaterScreen> {
  final _customCtrl = TextEditingController();
  bool _saving = false;

  static const _quickAmounts = [250, 500, 750, 1000];
  static const _goalMl = 2500;

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _add(int ml) async {
    if (ml <= 0) return;
    setState(() => _saving = true);
    try {
      await ref.read(dailyProvider.notifier).updateWater(ml);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyAsync = ref.watch(dailyProvider);
    final currentMl = dailyAsync.value?.waterMl ?? 0;
    final progress = (currentMl / _goalMl).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Log Water')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.water_drop_rounded,
                          color: Color(0xFF4A9EFF), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Today\'s intake',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${_fmtMl(currentMl)} / ${_fmtMl(_goalMl)}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFF4A9EFF)
                          .withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF4A9EFF)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_goalMl - currentMl > 0 ? _fmtMl(_goalMl - currentMl) : '0 ml'} remaining',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Quick add',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            // Quick amount buttons
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.4,
              children: _quickAmounts.map((ml) {
                return ElevatedButton.icon(
                  onPressed: _saving ? null : () => _add(ml),
                  icon: const Icon(Icons.water_drop_rounded,
                      size: 16, color: Color(0xFF4A9EFF)),
                  label: Text(
                    _fmtMl(ml),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            Text(
              'Custom amount',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    decoration: InputDecoration(
                      hintText: '350',
                      suffixText: 'ml',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _saving
                      ? null
                      : () {
                          final ml =
                              int.tryParse(_customCtrl.text) ?? 0;
                          _add(ml);
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size(80, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Add',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtMl(int ml) => ml >= 1000
      ? '${(ml / 1000).toStringAsFixed(ml % 1000 == 0 ? 0 : 1)} L'
      : '$ml ml';
}
