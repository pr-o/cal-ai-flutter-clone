import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/home/notifier.dart';
import 'features/settings/notifier.dart';
import 'router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
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
    ref.read(profileProvider);
    ref.read(dailyProvider);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));

    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            platformBrightness == Brightness.dark);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: MaterialApp.router(
        title: 'Cal AI',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        routerConfig: widget.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
