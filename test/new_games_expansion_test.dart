import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_veda/providers/app_state.dart';
import 'package:smriti_veda/screens/dice_memory_screen.dart';
import 'package:smriti_veda/screens/word_memory_puzzle_screen.dart';
import 'package:smriti_veda/services/db_service.dart';
import 'package:smriti_veda/widgets/dice_3d_widget.dart';
import 'package:smriti_veda/widgets/difficulty_selector.dart';

Widget _wrap(Widget child, AppState appState) {
  return MaterialApp(
    home: AppStateScope(
      state: appState,
      child: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppState appState;

  setUp(() async {
    await DbService().init();
    appState = AppState();
  });

  group('3D Dice Memory Screen Widget Tests', () {
    testWidgets('Renders tabletop area, difficulty selector, and dice widgets', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrap(const DiceMemoryScreen(), appState));
      await tester.pumpAndSettle();

      expect(find.text('3D Dice Memory'), findsOneWidget);
      expect(find.byType(DifficultySelector), findsOneWidget);
      expect(find.byType(Dice3DWidget), findsWidgets);
      expect(find.textContaining('Start Memorizing'), findsOneWidget);
    });

    testWidgets('Starts preview phase and countdown timer', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrap(const DiceMemoryScreen(), appState));
      await tester.pumpAndSettle();

      // Tap Start Memorizing
      await tester.tap(find.textContaining('Start Memorizing'));
      await tester.pump();

      expect(find.text('Memorize the Numbers & Order'), findsOneWidget);
      expect(find.text('Seconds Remaining'), findsOneWidget);
    });
  });

  group('Word Memory Puzzle Screen Widget Tests', () {
    testWidgets('Renders word deck, difficulty selector, and instructions', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrap(const WordMemoryPuzzleScreen(), appState));
      await tester.pumpAndSettle();

      expect(find.text('Word Memory Puzzle'), findsOneWidget);
      expect(find.byType(DifficultySelector), findsOneWidget);
      expect(find.text('WORD SEQUENCE DECK'), findsOneWidget);
      expect(find.textContaining('Start Memorizing'), findsOneWidget);
    });

    testWidgets('Starts preview phase and displays countdown', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrap(const WordMemoryPuzzleScreen(), appState));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Start Memorizing'));
      await tester.pump();

      expect(find.text('Memorize the Words in Order'), findsOneWidget);
      expect(find.text('Seconds Remaining'), findsOneWidget);
    });
  });
}
