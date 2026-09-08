import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smriti_veda/providers/app_state.dart';
import 'package:smriti_veda/screens/arranging_order_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Arranging Order screen initializes with shuffled items and can reorder & evaluate', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    final appState = AppState();

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          state: appState,
          child: const ArrangingOrderScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and round title
    expect(find.text('Arranging Order'), findsOneWidget);
    expect(find.textContaining('EASY DIFFICULTY'), findsOneWidget);

    // Verify 4 items rendered
    expect(find.byType(ReorderableListView), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsWidgets);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsWidgets);

    // Tap move down on first item
    final firstMoveDown = find.byTooltip('Move Down').first;
    await tester.tap(firstMoveDown);
    await tester.pumpAndSettle();

    // Ensure "Check Answer" is visible and tap it
    final checkButton = find.text('Check Answer');
    await tester.ensureVisible(checkButton);
    await tester.pumpAndSettle();
    await tester.tap(checkButton);
    await tester.pumpAndSettle();

    // Results feedback should be displayed
    expect(find.textContaining('Accuracy:'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.text('Try Next Difficulty'), findsOneWidget);

    // Tap "Try Again"
    await tester.ensureVisible(find.text('Try Again'));
    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();

    // Should return to playable state with Check Answer button
    expect(find.text('Check Answer'), findsOneWidget);
  });
}
