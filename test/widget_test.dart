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

  Widget home({double textScale = 1}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: HomeScreen(clock: () => DateTime(2026, 10, 1, 8)),
        ),
      );

  testWidgets('example chips fill the input', (tester) async {
    await tester.pumpWidget(home());
    await tester.tap(find.text('@hourly'));
    await tester.pump();
    expect(find.text('At minute 0'), findsOneWidget);
    expect(find.text('Thu 2026-10-01 09:00'), findsOneWidget);
  });

  testWidgets('empty input shows an error and no runs', (tester) async {
    await tester.pumpWidget(home());
    await tester.enterText(find.byKey(const Key('cron-input')), '   ');
    await tester.pump();
    expect(find.text('Enter a cron expression.'), findsOneWidget);
    expect(find.text('Next runs'), findsNothing);
  });

  testWidgets('impossible dates show the never-fires message', (tester) async {
    await tester.pumpWidget(home());
    await tester.enterText(find.byKey(const Key('cron-input')), '0 0 30 2 *');
    await tester.pump();
    expect(find.textContaining('never fires'), findsOneWidget);
  });

  testWidgets('meets tap-target and label guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(home());
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  testWidgets('lays out at 200% text scale on a phone without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(home(textScale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('cron-description')), findsOneWidget);
  });
}
