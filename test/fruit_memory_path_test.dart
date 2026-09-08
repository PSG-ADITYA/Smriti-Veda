import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smriti_veda/providers/app_state.dart';
import 'package:smriti_veda/screens/fruit_memory_path_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Fruit Memory Path: Starts ready, initiates 5-second memorization without numbers, and reproduces sequence', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    final appState = AppState();

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          state: appState,
          child: const FruitMemoryPathScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Ready State Check
    expect(find.text('Fruit Memory Path'), findsOneWidget);
    expect(find.text('Start 5-Second Memorization'), findsOneWidget);

    // 2. Start 5-Second Memorization
    final startBtn = find.text('Start 5-Second Memorization');
    await tester.ensureVisible(startBtn);
    await tester.pumpAndSettle();
    await tester.tap(startBtn);
    await tester.pump();

    // Verify 5-second countdown message appears
    expect(find.textContaining('PREVIEW):'), findsOneWidget);

    // Verify NO numbers are displayed as sequence badges on the fruits
    // Check that there is no circle avatar or text badge like '1', '2', '3' positioned over fruits
    expect(find.text('1.'), findsNothing);
    expect(find.text('2.'), findsNothing);

    // Fast-forward the 5-second preview timer
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();

    // 3. Navigation Phase Reached (pavers hidden)
    expect(find.textContaining('REPRODUCE SEQUENCE IN ORDER'), findsOneWidget);
    expect(find.textContaining('Found: 0 of'), findsOneWidget);

    // 4. Verify Restart Tier button works and resets cleanly
    expect(find.text('Restart Round'), findsOneWidget);
    await tester.ensureVisible(find.text('Restart Round'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restart Round'));
    await tester.pumpAndSettle();

    // Should return cleanly to ready phase
    expect(find.text('Start 5-Second Memorization'), findsOneWidget);
  });
}
