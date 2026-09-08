import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_veda/models/exercise_attempt.dart';
import 'package:smriti_veda/models/game_difficulty.dart';
import 'package:smriti_veda/services/db_service.dart';
import 'package:smriti_veda/services/session_engine/memory_session_generator.dart';
import 'package:smriti_veda/services/session_engine/memory_scoring_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await DbService().init();
  });

  group('Memory Session Engine Generator Tests', () {
    test('Fruit Memory Path session generation produces valid varying paths', () {
      final session1 = MemorySessionGenerator.generateFruitSession(GameDifficulty.easy);
      final session2 = MemorySessionGenerator.generateFruitSession(GameDifficulty.easy);
      expect(session2.stimulus.fruits.isNotEmpty, isTrue);

      expect(session1.gameType, ExerciseType.fruitMemoryPath);
      expect(session1.stimulus.fruits.length, 3);
      expect(session1.stimulus.pathIndices.length, 3);
      expect(session1.stimulus.gridSize, 3);

      // Verify all path indices are within grid bounds
      for (final idx in session1.stimulus.pathIndices) {
        expect(idx >= 0 && idx < 9, isTrue);
      }

      final hardSession = MemorySessionGenerator.generateFruitSession(GameDifficulty.hard);
      expect(hardSession.stimulus.fruits.length, 7);
      expect(hardSession.stimulus.gridSize, 4);
    });

    test('Memory Melody session generates authentic swaras and timing', () {
      final session = MemorySessionGenerator.generateMelodySession(GameDifficulty.medium);
      expect(session.gameType, ExerciseType.memoryMelody);
      expect(session.stimulus.noteIds.length, 5);
      expect(session.stimulus.swaraNames.length, 5);
      expect(session.sequence.isNotEmpty, isTrue);
    });

    test('Pattern Memory session generates unique active cell sets', () {
      final easy = MemorySessionGenerator.generatePatternSession(GameDifficulty.easy);
      expect(easy.stimulus.activeTiles.length, 3);
      for (final tile in easy.stimulus.activeTiles) {
        expect(tile >= 0 && tile < 9, isTrue);
      }

      final hard = MemorySessionGenerator.generatePatternSession(GameDifficulty.hard);
      expect(hard.stimulus.activeTiles.length, 6);
      for (final tile in hard.stimulus.activeTiles) {
        expect(tile >= 0 && tile < 16, isTrue);
      }
    });

    test('Object Recall Matrix session generates valid room and target allocations', () {
      final session = MemorySessionGenerator.generateObjectSession(GameDifficulty.medium);
      expect(session.gameType, ExerciseType.recognition);
      expect(session.stimulus.targets.length, 5);
      expect(session.stimulus.distractors.length, 4);
      expect(session.stimulus.roomTitle.isNotEmpty, isTrue);
    });

    test('Attention Focus session generates grid with correct target counts', () {
      final session = MemorySessionGenerator.generateAttentionSession(GameDifficulty.medium);
      expect(session.gameType, ExerciseType.attention);
      expect(session.stimulus.totalCount, 16);
      expect(session.stimulus.targetCount, 5);
      final trueCount = session.stimulus.targetLocations.where((b) => b).length;
      expect(trueCount, 5);
    });

    test('Sequence Recall session selects from rich thematic sequences', () {
      final session = MemorySessionGenerator.generateSequenceSession(GameDifficulty.easy);
      expect(session.gameType, ExerciseType.sequenceRecall);
      expect(session.stimulus.targetSequence.length <= 4, isTrue);
      expect(session.stimulus.title.isNotEmpty, isTrue);
    });

    test('Oral Heritage Stories session provides questions and region', () {
      final session = MemorySessionGenerator.generateStorySession(GameDifficulty.medium);
      expect(session.gameType, ExerciseType.storyMemory);
      expect(session.stimulus.story.title.isNotEmpty, isTrue);
      expect(session.stimulus.questions.isNotEmpty, isTrue);
    });

    test('Daily Routine Recall session generates chronological routine steps', () {
      final session = MemorySessionGenerator.generateRoutineSession(GameDifficulty.medium);
      expect(session.gameType, ExerciseType.dailyRoutineRecall);
      expect(session.stimulus.steps.length >= 4, isTrue);
    });

    test('3D Dice Memory session produces tabletop layout and deterministic questions', () {
      final session = MemorySessionGenerator.generateDiceSession(GameDifficulty.easy);
      expect(session.gameType, ExerciseType.diceMemory);
      expect(session.stimulus.diceValues.length, 3);
      expect(session.stimulus.positions.length, 3);
      expect(session.questions.length >= 3, isTrue);

      // Verify dice values are in range 1-6
      for (final val in session.stimulus.diceValues) {
        expect(val >= 1 && val <= 6, isTrue);
      }
    });

    test('Word Memory Puzzle session generates questions and choices from word bank', () {
      final session = MemorySessionGenerator.generateWordPuzzleSession(GameDifficulty.easy);
      expect(session.gameType, ExerciseType.wordMemoryPuzzle);
      expect(session.stimulus.targetWords.length, 4);
      expect(session.questions.length >= 3, isTrue);

      // Verify word format
      for (final w in session.stimulus.targetWords) {
        expect(w.word.isNotEmpty, isTrue);
        expect(w.category.isNotEmpty, isTrue);
      }
    });
  });

  group('Memory Scoring Engine & Attempt Persistence Tests', () {
    test('evaluateQuestionSession computes 100% score for all correct answers and logs attempt', () async {
      final session = MemorySessionGenerator.generateDiceSession(GameDifficulty.easy);
      final answers = <String, dynamic>{};
      for (final q in session.questions) {
        answers[q.id] = q.correctAnswerText;
      }

      final result = await MemoryScoringEngine.evaluateQuestionSession(
        session: session,
        userAnswers: answers,
        timeTakenMs: 4500,
        mistakes: 0,
      );

      expect(result.scorePct, 100.0);
      expect(result.correctAnswers, session.questions.length);
      expect(result.itemRecallScore, 1.0);

      // Verify persisted attempt in DbService
      final logged = DbService().getLoggedAttempts();
      expect(logged.isNotEmpty, isTrue);
      final match = logged.firstWhere((a) => a['id'] == result.attempt.id);
      expect(match['rawScore'], 100.0);
      expect(match['type'], ExerciseType.diceMemory.name);
    });

    test('recordContinuousSession persists continuous performance correctly', () async {
      final attempt = await MemoryScoringEngine.recordContinuousSession(
        gameType: ExerciseType.fruitMemoryPath,
        sessionId: 'test_fruit_session_01',
        difficulty: GameDifficulty.hard,
        accuracyPct: 85.0,
        timeTakenMs: 12000,
        mistakes: 1,
      );

      expect(attempt.type, ExerciseType.fruitMemoryPath);
      expect(attempt.rawScore, 85.0);
      expect(attempt.cognitiveDomain, CognitiveDomain.spatialMemory);

      final logged = DbService().getLoggedAttempts();
      final match = logged.firstWhere((a) => a['id'] == attempt.id);
      expect(match['rawScore'], 85.0);
      expect(match['domain'], ExerciseDomain.universalCognitive.name);
    });
  });
}
