import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/home/notifier.dart';
import 'router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final router = await buildRouter();
  runApp(ProviderScope(child: CalAiApp(router: router)));
}

class CalAiApp extends ConsumerStatefulWidget {
  const CalAiApp({super.key, required this.router});
  final GoRouter router;

  @override
  ConsumerState<CalAiApp> createState() => _CalAiAppState();
}

class _CalAiAppState extends ConsumerState<CalAiApp> {
  @override
  void initState() {
    super.initState();
    // Pre-warm profile and today's daily data on startup.
    ref.read(profileProvider);
    ref.read(dailyProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cal AI',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: widget.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
