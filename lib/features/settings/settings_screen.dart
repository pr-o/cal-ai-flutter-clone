import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../db/database.dart';
import '../../features/home/notifier.dart';
import '../../utils/notifications.dart';
import '../../widgets/section_header.dart';
import 'notifier.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _geminiCtrl = TextEditingController();
  final _usdaCtrl = TextEditingController();
  bool _keysLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  @override
  void dispose() {
    _geminiCtrl.dispose();
    _usdaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKeys() async {
    final notifier = ref.read(settingsProvider.notifier);
    final gemini = await notifier.getGeminiApiKey();
    final usda = await notifier.getUsdaApiKey();
    if (mounted) {
      setState(() {
        _geminiCtrl.text = gemini ?? '';
        _usdaCtrl.text = usda ?? '';
        _keysLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          SectionHeader('Theme'),
          const SizedBox(height: 8),
          _ThemeSegment(current: settings.themeMode),
          const SizedBox(height: 20),
          _WeightUnitTile(unit: settings.weightUnit),
          const SizedBox(height: 20),
          SectionHeader('Reminders'),
          const SizedBox(height: 8),
          const _RemindersTile(),
          const SizedBox(height: 20),
          SectionHeader('API Keys'),
          const SizedBox(height: 8),
          if (_keysLoaded) ...[
            _ApiKeyField(
              label: 'Gemini API Key',
              controller: _geminiCtrl,
              onSave: () async {
                await ref
                    .read(settingsProvider.notifier)
                    .setGeminiApiKey(_geminiCtrl.text.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gemini API key saved')),
                  );
                }
              },
              onTest: () => _testGeminiKey(context, _geminiCtrl.text.trim()),
            ),
            const SizedBox(height: 12),
            _ApiKeyField(
              label: 'USDA API Key',
              controller: _usdaCtrl,
              onSave: () async {
                await ref
                    .read(settingsProvider.notifier)
                    .setUsdaApiKey(_usdaCtrl.text.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('USDA API key saved')),
                  );
                }
              },
              onTest: () => _testUsdaKey(context, _usdaCtrl.text.trim()),
            ),
          ] else
            const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 20),
          SectionHeader('Profile & Goals'),
          const SizedBox(height: 8),
          profileAsync.when(
            loading: () => const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Error: $e'),
            data: (profile) => _ProfileSection(profile: profile),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => _confirmReset(context),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reset Onboarding'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _testGeminiKey(BuildContext context, String key) async {
    if (key.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a key first')));
      return;
    }
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$key',
      );
      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': 'Say OK'},
            ],
          },
        ],
      });
      final res = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 10));
      if (!context.mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✓ Gemini key is valid')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gemini error ${res.statusCode}')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gemini test failed: $e')));
    }
  }

  Future<void> _testUsdaKey(BuildContext context, String key) async {
    if (key.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a key first')));
      return;
    }
    try {
      final url = Uri.parse(
        'https://api.nal.usda.gov/fdc/v1/foods/search?query=apple&pageSize=1&api_key=$key',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (!context.mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✓ USDA key is valid')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('USDA error ${res.statusCode}')));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('USDA test failed: $e')));
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset onboarding?'),
        content: const Text(
          'This will delete your profile and return you to the setup flow.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final db = ref.read(databaseProvider);
    await db.delete(db.profiles).go();
    await ref.read(settingsProvider.notifier).clearOnboarding();
    if (context.mounted) {
      context.go('/onboarding/goal');
    }
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ThemeSegment extends ConsumerWidget {
  const _ThemeSegment({required this.current});
  final ThemeMode current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(value: ThemeMode.light, label: Text('Light')),
        ButtonSegment(value: ThemeMode.system, label: Text('System')),
        ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
      ],
      selected: {current},
      onSelectionChanged: (sel) =>
          ref.read(settingsProvider.notifier).setTheme(sel.first),
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _WeightUnitTile extends ConsumerWidget {
  const _WeightUnitTile({required this.unit});
  final String unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: const Text('Weight Unit'),
        subtitle: Text(unit == 'lbs' ? 'Pounds (lbs)' : 'Kilograms (kg)'),
        secondary: Text(
          unit,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        value: unit == 'lbs',
        onChanged: (v) =>
            ref.read(settingsProvider.notifier).setWeightUnit(v ? 'lbs' : 'kg'),
      ),
    );
  }
}

class _ApiKeyField extends StatefulWidget {
  const _ApiKeyField({
    required this.label,
    required this.controller,
    required this.onSave,
    required this.onTest,
  });
  final String label;
  final TextEditingController controller;
  final VoidCallback onSave;
  final VoidCallback onTest;

  @override
  State<_ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends State<_ApiKeyField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: widget.label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: widget.onTest, child: const Text('Test')),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: widget.onSave,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileSection extends ConsumerWidget {
  const _ProfileSection({required this.profile});
  final Profile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (profile == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('No profile found. Complete onboarding first.'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _goalLabel(profile!.goal),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () => _showEditGoals(context, ref, profile!),
                child: const Text('Edit Goals'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _GoalRow('Calories', '${profile!.dailyCalories} kcal'),
          _GoalRow('Protein', '${profile!.dailyProteinG}g'),
          _GoalRow('Carbs', '${profile!.dailyCarbsG}g'),
          _GoalRow('Fat', '${profile!.dailyFatG}g'),
        ],
      ),
    );
  }

  String _goalLabel(String goal) => switch (goal) {
    'lose' => 'Goal: Lose weight',
    'gain' => 'Goal: Gain muscle',
    _ => 'Goal: Maintain weight',
  };

  void _showEditGoals(BuildContext context, WidgetRef ref, Profile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditGoalsSheet(profile: profile),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _EditGoalsSheet extends ConsumerStatefulWidget {
  const _EditGoalsSheet({required this.profile});
  final Profile profile;

  @override
  ConsumerState<_EditGoalsSheet> createState() => _EditGoalsSheetState();
}

class _EditGoalsSheetState extends ConsumerState<_EditGoalsSheet> {
  late final TextEditingController _calCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _fatCtrl;

  @override
  void initState() {
    super.initState();
    _calCtrl = TextEditingController(
      text: widget.profile.dailyCalories.toString(),
    );
    _proteinCtrl = TextEditingController(
      text: widget.profile.dailyProteinG.toString(),
    );
    _carbsCtrl = TextEditingController(
      text: widget.profile.dailyCarbsG.toString(),
    );
    _fatCtrl = TextEditingController(text: widget.profile.dailyFatG.toString());
  }

  @override
  void dispose() {
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Edit Daily Goals',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _NumField(label: 'Calories (kcal)', controller: _calCtrl),
          const SizedBox(height: 12),
          _NumField(label: 'Protein (g)', controller: _proteinCtrl),
          const SizedBox(height: 12),
          _NumField(label: 'Carbs (g)', controller: _carbsCtrl),
          const SizedBox(height: 12),
          _NumField(label: 'Fat (g)', controller: _fatCtrl),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save Goals'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final cal = int.tryParse(_calCtrl.text);
    final protein = int.tryParse(_proteinCtrl.text);
    final carbs = int.tryParse(_carbsCtrl.text);
    final fat = int.tryParse(_fatCtrl.text);
    if (cal == null || protein == null || carbs == null || fat == null) return;

    final db = ref.read(databaseProvider);
    await (db.update(
      db.profiles,
    )..where((t) => t.id.equals(widget.profile.id))).write(
      ProfilesCompanion(
        dailyCalories: Value(cal),
        dailyProteinG: Value(protein),
        dailyCarbsG: Value(carbs),
        dailyFatG: Value(fat),
      ),
    );
    ref.invalidate(profileProvider);

    if (mounted) Navigator.of(context).pop();
  }
}

class _NumField extends StatelessWidget {
  const _NumField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _RemindersTile extends ConsumerStatefulWidget {
  const _RemindersTile();

  @override
  ConsumerState<_RemindersTile> createState() => _RemindersTileState();
}

class _RemindersTileState extends ConsumerState<_RemindersTile> {
  final Map<String, bool> _loading = {};

  Future<void> _toggle(String meal, bool value) async {
    setState(() => _loading[meal] = true);
    // Request permission on first enable
    if (value) await initNotifications();
    await ref.read(settingsProvider.notifier).setReminder(meal, value);
    if (mounted) {
      setState(() => _loading[meal] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _ReminderRow(
            emoji: '🌅',
            label: 'Breakfast',
            time: '8:00 AM',
            value: settings.reminderBreakfast,
            loading: _loading['breakfast'] ?? false,
            onChanged: (v) => _toggle('breakfast', v),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _ReminderRow(
            emoji: '☀️',
            label: 'Lunch',
            time: '12:00 PM',
            value: settings.reminderLunch,
            loading: _loading['lunch'] ?? false,
            onChanged: (v) => _toggle('lunch', v),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _ReminderRow(
            emoji: '🌙',
            label: 'Dinner',
            time: '7:00 PM',
            value: settings.reminderDinner,
            loading: _loading['dinner'] ?? false,
            onChanged: (v) => _toggle('dinner', v),
          ),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.emoji,
    required this.label,
    required this.time,
    required this.value,
    required this.loading,
    required this.onChanged,
  });

  final String emoji;
  final String label;
  final String time;
  final bool value;
  final bool loading;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Text(emoji, style: const TextStyle(fontSize: 22)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        time,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      value: value,
      onChanged: loading ? null : onChanged,
    );
  }
}
