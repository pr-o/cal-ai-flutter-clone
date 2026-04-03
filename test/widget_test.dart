import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cal_ai_flutter_clone/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/onboarding/goal',
      routes: [
        GoRoute(
          path: '/onboarding/goal',
          builder: (context, state) =>
              const Scaffold(body: Text('Cal AI')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: CalAiApp(router: router)),
    );
    expect(find.text('Cal AI'), findsOne);
  });
}
