// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:performance_stopwatch/main.dart';

void main() {
  testWidgets('Stopwatch app renders primary UI elements', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PerformanceStopwatchApp());

    expect(find.text('Index'), findsOneWidget);
    expect(find.text('Captured Time'), findsOneWidget);
    expect(find.text('00:00:00'), findsOneWidget);
  });
}
