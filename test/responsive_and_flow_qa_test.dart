import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_veda/providers/app_state.dart';
import 'package:smriti_veda/screens/ai_game_generator_screen.dart';
import 'package:smriti_veda/screens/attention_exercise_screen.dart';
import 'package:smriti_veda/screens/daily_routine_recall_screen.dart';
import 'package:smriti_veda/screens/everyday_memory_screen.dart';
import 'package:smriti_veda/screens/fruit_memory_path_screen.dart';
import 'package:smriti_veda/screens/home_tab.dart';
import 'package:smriti_veda/screens/medical_reports_screen.dart';
import 'package:smriti_veda/screens/memory_melody_screen.dart';
import 'package:smriti_veda/screens/my_data_screen.dart';
import 'package:smriti_veda/screens/object_memory_screen.dart';
import 'package:smriti_veda/screens/pattern_memory_screen.dart';
import 'package:smriti_veda/screens/practice_tab.dart';
import 'package:smriti_veda/screens/progress_tab.dart';
import 'package:smriti_veda/screens/sequence_recall_screen.dart';
import 'package:smriti_veda/screens/story_memory_screen.dart';
import 'package:smriti_veda/theme/app_theme.dart';

Widget _wrapWithScope(Widget child, {Size size = const Size(360, 800)}) {
  final appState = AppState();
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: MediaQuery(
      data: MediaQueryData(
        size: size,
        padding: const EdgeInsets.only(top: 24, bottom: 16),
      ),
      child: AppStateScope(
        state: appState,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  const testSizes = [
    Size(360, 800),
    Size(390, 844),
    Size(412, 915),
  ];

  group('Smriti Veda Full QA & Responsive Overflow Pass', () {
    for (final size in testSizes) {

      testWidgets('Flow 1 & 2: Home Tab renders at ', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_wrapWithScope(HomeTab(onNavigateTab: (_) {}), size: size));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.textContaining('Ready for today'), findsWidgets);
      });

      testWidgets('Flow 3: Practice Tab renders at ', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_wrapWithScope(const PracticeTab(), size: size));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.textContaining('Memory Melody'), findsWidgets);
      });

      testWidgets('Flow 4: Memory Melody Screen renders at ', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_wrapWithScope(const MemoryMelodyScreen(), size: size));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.textContaining('Memory Melody'), findsWidgets);
      });

      testWidgets('Flow 5: Fruit Memory Path renders at ', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_wrapWithScope(const FruitMemoryPathScreen(), size: size));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.text('Fruit Memory Path'), findsWidgets);
      });

      testWidgets('Flow 6: Pattern Memory renders at ', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_wrapWithScope(const PatternMemoryScreen(), size: size));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.textContaining('Pattern'), findsWidgets);
      });

      testWidgets('Flow 7: Object Recall renders at ', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_wrapWithScope(const ObjectMemoryScreen(), size: size));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.textContaining('Object Recall'), findsWidgets);
      });

      testWidgets('Flow 8: Visual Search renders at ', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_wrapWithScope(const AttentionExerciseScreen(), size: size));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.textContaining('Attention & Focus Challenge'), findsWidgets);
      });

      testWidgets('Flow 9: Sequence Recall renders at ', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_wrapWithScope(const SequenceRecallScreen(), size: size));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.textContaining('Sequence Recall'), findsWidgets);
      });

      testWidgets('Flow 10: Oral Heritage Stories renders at ', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_wrapWithScope(const StoryMemoryScreen(), size: size));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.textContaining('Story'), findsWidgets);
      });

      testWidgets('Flow 11: Daily Routine Recall renders at ', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_wrapWithScope(const DailyRoutineRecallScreen(), size: size));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.text('Daily Routine Recall'), findsWidgets);
      });

      testWidgets('Flow 12: Progress Tab renders at ', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_wrapWithScope(const ProgressTab(), size: size));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.textContaining('Your Practice & Memory Journey'), findsWidgets);
        expect(find.textContaining('Caregiver'), findsWidgets);
      });

      testWidgets('Flow 13: Everyday Memory Screen renders at ', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_wrapWithScope(const EverydayMemoryScreen(), size: size));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.textContaining('Everyday Memory'), findsWidgets);
      });

      testWidgets('Flow 14: Medical Reports Screen renders at ', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_wrapWithScope(const MedicalReportsScreen(), size: size));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.textContaining('Medical Reports Hub'), findsWidgets);
        expect(find.textContaining('Add Medical Report'), findsWidgets);
      });

      testWidgets('Flow 15: AI Game Generator Screen renders at ', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_wrapWithScope(const AiGameGeneratorScreen(), size: size));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.textContaining('AI Game Architect'), findsWidgets);
      });

      testWidgets('Flow 16: My Data Hub Screen renders at ', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_wrapWithScope(const MyDataScreen(), size: size));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.textContaining('My Data Hub'), findsWidgets);
        expect(find.textContaining('PROFILE & ACCOUNT INFORMATION'), findsWidgets);
      });
    }
  });
}
