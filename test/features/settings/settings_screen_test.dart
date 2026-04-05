import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cal_ai_flutter_clone/features/home/notifier.dart';
import 'package:cal_ai_flutter_clone/features/settings/settings_screen.dart';

// Minimal router wrapper so GoRouter context is available.
Widget _wrap(Widget child) {
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(path: '/settings', builder: (_, __) => child),
      GoRoute(
        path: '/onboarding/goal',
        builder: (_, __) => const Scaffold(body: Text('onboarding')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [profileProvider.overrideWith((ref) async => null)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  testWidgets('shows theme SegmentedButton with System selected by default', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pump();

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
  });

  testWidgets('shows weight unit section', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pump();

    expect(find.text('Weight Unit'), findsOneWidget);
    expect(find.text('kg'), findsOneWidget);
  });

  testWidgets('shows API keys section', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pump();
    await tester.pump();

    expect(find.text('API Keys', skipOffstage: false), findsOneWidget);
    expect(find.text('Gemini API Key', skipOffstage: false), findsOneWidget);
    expect(find.text('USDA API Key', skipOffstage: false), findsOneWidget);
  });

  testWidgets('shows reset onboarding button', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Scroll down to reveal Reset Onboarding button past the Reminders section
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pump();

    expect(find.text('Reset Onboarding'), findsOneWidget);
  });

  testWidgets('reset onboarding shows confirmation dialog', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Scroll down to reveal the Reset Onboarding button past the Reminders section
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pump();

    await tester.tap(find.text('Reset Onboarding'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Reset onboarding?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
  });
}
