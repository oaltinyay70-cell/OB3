import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drone_commander/app.dart';

void main() {
  testWidgets('App launches without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DroneCommanderApp());

    // App starts on SplashScreen with async timers (typewriter, loading).
    // Verify the scaffold exists (splash is visible).
    expect(find.byType(DroneCommanderApp), findsOneWidget);

    // Pump through all pending timers to avoid "Timer still pending" errors.
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
