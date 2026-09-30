import 'package:cron/main.dart';
import 'package:cron/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app shell shows the cron tool and about tab', (tester) async {
    await tester.pumpWidget(const CronApp());
    expect(find.text('Cron'), findsWidgets);
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('Features'), findsOneWidget);
  });

  testWidgets('typing an expression updates meaning and next runs', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(clock: () => DateTime(2026, 10, 1, 8))),
    );
    await tester.enterText(find.byKey(const Key('cron-input')), '30 8 * * *');
    await tester.pump();
    expect(find.text('At 08:30'), findsOneWidget);
    expect(find.text('Thu 2026-10-01 08:30'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('cron-input')), '99 * * * *');
    await tester.pump();
    expect(find.textContaining('between 0 and 59'), findsOneWidget);
  });
}
