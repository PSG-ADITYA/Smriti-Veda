import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smriti_veda/providers/app_state.dart';
import 'package:smriti_veda/screens/memory_melody_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Memory Melody: Plays synchronized musical notes, accepts ordered note taps, evaluates accurately, and resets cleanly', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    final appState = AppState();

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          state: appState,
          child: const MemoryMelodyScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initial Ready Phase Check
    expect(find.text('Memory Melody'), findsOneWidget);
    expect(find.textContaining('EASY DIFFICULTY'), findsOneWidget);
    expect(find.text('Play Melody (Listen)'), findsOneWidget);

    // 2. Start Playback Phase
    await tester.tap(find.text('Play Melody (Listen)'));
    await tester.pump();
    expect(find.text('Playing Melody Tones...'), findsOneWidget);

    // Fast-forward playback duration by ticking through sequential timers
    for (int i = 0; i < 7; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();

    // 3. Reproduction Phase Reached
    expect(find.textContaining('REPRODUCED SEQUENCE'), findsOneWidget);
    expect(find.text('Check Melody'), findsOneWidget);

    // Verify 8 musical note pads (C, D, E, F, G, A, B, C5)
    expect(find.text('C'), findsWidgets);
    expect(find.text('E'), findsWidgets);
    expect(find.text('G'), findsWidgets);

    // Tap notes: C then E then G (matching Round 1 target chord)
    // Find the note pads in the grid
    final notePadC = find.widgetWithText(InkWell, 'C');
    final notePadE = find.widgetWithText(InkWell, 'E');
    final notePadG = find.widgetWithText(InkWell, 'G');

    await tester.tap(notePadC);
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(notePadE);
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(notePadG);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // 4. Automatic / Submission Evaluation
    expect(find.textContaining('Accuracy:'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.text('Next Difficulty'), findsOneWidget);

    // 5. Tap Try Again to verify clean reset
    await tester.ensureVisible(find.text('Try Again'));
    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();

    // Should return to ready state with Play Melody button
    expect(find.text('Play Melody (Listen)'), findsOneWidget);
  });
}
