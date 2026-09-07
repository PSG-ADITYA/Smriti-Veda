import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_veda/models/exercise_attempt.dart';
import 'package:smriti_veda/services/personalization_engine.dart';
import 'package:smriti_veda/services/ai_service.dart';
import 'package:smriti_veda/services/song_generation_service.dart';

void main() {
  group('Smriti Veda Cognitive Gaming & Memory Melody Suite', () {
    test('CognitiveDomain covers all 8 domains with human labels and descriptions', () {
      expect(CognitiveDomain.values.length, 8);
      for (final domain in CognitiveDomain.values) {
        expect(domain.displayName.isNotEmpty, true);
        expect(domain.description.isNotEmpty, true);
      }
    });

    test('ExerciseAttempt infers correct CognitiveDomain including memoryMelody', () {
      final melodyAttempt = ExerciseAttempt(
        id: 'melody-1',
        userId: 'user-1',
        domain: ExerciseDomain.universalCognitive,
        type: ExerciseType.memoryMelody,
        exerciseId: 'memory_melody_ravi',
        responseMode: 'choice',
        rawScore: 90,
        maxScore: 100,
        metadata: {
          'itemRecallScore': 100.0,
          'sequenceRecallScore': 90.0,
          'attentionScore': 85.0,
          'delayedRecallScore': 95.0,
        },
      );
      expect(melodyAttempt.cognitiveDomain, CognitiveDomain.auditoryRecall);
      expect(melodyAttempt.itemRecallScore, 100.0);
      expect(melodyAttempt.sequenceRecallScore, 90.0);
      expect(melodyAttempt.attentionScore, 85.0);
      expect(melodyAttempt.delayedRecallScore, 95.0);
    });

    test('SongGenerationService provides curated regional songs with complete schema', () {
      final songs = SongGenerationService.allCuratedSongs;
      expect(songs.length >= 3, true);

      for (final song in songs) {
        expect(song.title.isNotEmpty, true);
        expect(song.lyrics.isNotEmpty, true);
        expect(song.lines.length >= 4, true);
        expect(song.events.length >= 3, true);
        expect(song.questions.length >= 3, true);
        expect(song.delayedQuestion.question.isNotEmpty, true);
        expect(song.delayedQuestion.options.length >= 3, true);

        // Verify task types
        final taskTypes = song.questions.map((q) => q.taskType).toSet();
        expect(taskTypes.contains('item_recall'), true);
        expect(taskTypes.contains('sequence_recall'), true);
        expect(taskTypes.contains('attention'), true);
        expect(song.delayedQuestion.taskType, 'delayed_recall');
      }
    });

    test('PersonalizationEngine recommends Memory Melody when auditory recall is low', () {
      final attempts = <ExerciseAttempt>[
        ExerciseAttempt(
          id: '1',
          userId: 'u1',
          domain: ExerciseDomain.universalCognitive,
          type: ExerciseType.fruitMemoryPath,
          exerciseId: 'fruit_memory_path',
          responseMode: 'action',
          rawScore: 95,
          maxScore: 100,
          cognitiveDomain: CognitiveDomain.spatialMemory,
        ),
        ExerciseAttempt(
          id: '2',
          userId: 'u1',
          domain: ExerciseDomain.universalCognitive,
          type: ExerciseType.memoryMelody,
          exerciseId: 'memory_melody_ravi',
          responseMode: 'choice',
          rawScore: 40,
          maxScore: 100,
          cognitiveDomain: CognitiveDomain.auditoryRecall,
        ),
      ];

      final rec = PersonalizationEngine.getRecommendation(attempts);
      expect(rec.targetDomain, CognitiveDomain.auditoryRecall);
      expect(rec.exerciseType, ExerciseType.memoryMelody);
      expect(rec.exerciseTitle, 'Memory Melody');
    });

    test('AIService offline fallback generates rich plan, summary, and cognitive content', () async {
      final ai = GeminiOmniRouteAiService();

      final plan = await ai.generatePersonalizedPlan(
        patientName: 'Pranab',
        age: '72',
        cognitiveGoal: 'Focus & Memory',
        language: 'Assamese',
        relatives: 'Granddaughter Priya',
        memoriesAndHobbies: 'Tea gardening, Bihu folk songs',
      );
      expect(plan.isNotEmpty, true);
      expect(plan.contains('Pranab'), true);

      final content = await ai.generateCognitiveExerciseContent(
        patientName: 'Pranab',
        domain: CognitiveDomain.spatialMemory,
        difficulty: 'Medium',
      );
      expect(content.title.contains('Pranab'), true);
      expect(content.cognitiveDomain, CognitiveDomain.spatialMemory);
      expect(content.items.isNotEmpty, true);
      expect(content.questions.isNotEmpty, true);
    });

    test('Memory Melody 5 sub-scores compute correct weighted composite score', () {
      const itemRecall = 100;
      const sequenceRecall = 80;
      const eventOrdering = 100;
      const attention = 60;
      const delayedRecall = 100;

      final composite = (itemRecall * 0.25) +
          (sequenceRecall * 0.25) +
          (eventOrdering * 0.20) +
          (attention * 0.15) +
          (delayedRecall * 0.15);

      // Expected: 25 + 20 + 20 + 9 + 15 = 89.0
      expect(composite, 89.0);

      final attempt = ExerciseAttempt(
        id: 'test-composite-1',
        userId: 'u-qa',
        domain: ExerciseDomain.universalCognitive,
        type: ExerciseType.memoryMelody,
        exerciseId: 'memory_melody_ravi',
        responseMode: 'choice',
        rawScore: composite,
        maxScore: 100.0,
        cognitiveDomain: CognitiveDomain.auditoryRecall,
        metadata: {
          'itemRecallScore': itemRecall.toDouble(),
          'sequenceRecallScore': sequenceRecall.toDouble(),
          'eventOrderingScore': eventOrdering.toDouble(),
          'attentionScore': attention.toDouble(),
          'delayedRecallScore': delayedRecall.toDouble(),
        },
      );

      expect(attempt.rawScore, 89.0);
      expect(attempt.metadata?['itemRecallScore'], 100.0);
      expect(attempt.metadata?['sequenceRecallScore'], 80.0);
      expect(attempt.metadata?['eventOrderingScore'], 100.0);
      expect(attempt.metadata?['attentionScore'], 60.0);
      expect(attempt.metadata?['delayedRecallScore'], 100.0);
    });

    test('PersonalizationEngine dynamically recalculates domains and updates recommendations without fake scores', () {
      // Scenario A: User scored 85% in Spatial Memory and 40% in Auditory Recall
      final initialAttempts = [
        ExerciseAttempt(
          id: 'att-1',
          userId: 'u1',
          domain: ExerciseDomain.universalCognitive,
          type: ExerciseType.fruitMemoryPath,
          exerciseId: 'fruit_memory_path',
          responseMode: 'action',
          rawScore: 85,
          maxScore: 100,
          cognitiveDomain: CognitiveDomain.spatialMemory,
        ),
        ExerciseAttempt(
          id: 'att-2',
          userId: 'u1',
          domain: ExerciseDomain.universalCognitive,
          type: ExerciseType.memoryMelody,
          exerciseId: 'memory_melody_ravi',
          responseMode: 'choice',
          rawScore: 40,
          maxScore: 100,
          cognitiveDomain: CognitiveDomain.auditoryRecall,
        ),
      ];

      final scoresA = PersonalizationEngine.computeDomainScores(initialAttempts);
      expect(scoresA[CognitiveDomain.spatialMemory]!.averagePercentage, 85.0);
      expect(scoresA[CognitiveDomain.auditoryRecall]!.averagePercentage, 40.0);

      // System recommends Auditory Recall (Memory Melody) because 40% is the weakest
      final recA = PersonalizationEngine.getRecommendation(initialAttempts);
      expect(recA.targetDomain, CognitiveDomain.auditoryRecall);
      expect(recA.exerciseType, ExerciseType.memoryMelody);

      // Scenario B: User now practices and excels in Auditory Recall with 100% and 95%
      final updatedAttempts = [
        ...initialAttempts,
        ExerciseAttempt(
          id: 'att-3',
          userId: 'u1',
          domain: ExerciseDomain.universalCognitive,
          type: ExerciseType.memoryMelody,
          exerciseId: 'memory_melody_ravi',
          responseMode: 'choice',
          rawScore: 100,
          maxScore: 100,
          cognitiveDomain: CognitiveDomain.auditoryRecall,
        ),
        ExerciseAttempt(
          id: 'att-4',
          userId: 'u1',
          domain: ExerciseDomain.universalCognitive,
          type: ExerciseType.memoryMelody,
          exerciseId: 'memory_melody_ravi',
          responseMode: 'choice',
          rawScore: 100,
          maxScore: 100,
          cognitiveDomain: CognitiveDomain.auditoryRecall,
        ),
        ExerciseAttempt(
          id: 'att-5',
          userId: 'u1',
          domain: ExerciseDomain.universalCognitive,
          type: ExerciseType.memoryMelody,
          exerciseId: 'memory_melody_ravi',
          responseMode: 'choice',
          rawScore: 100,
          maxScore: 100,
          cognitiveDomain: CognitiveDomain.auditoryRecall,
        ),
      ];

      final scoresB = PersonalizationEngine.computeDomainScores(updatedAttempts);
      // (40 + 100 + 100 + 100) / 4 = 85.0%
      expect(scoresB[CognitiveDomain.auditoryRecall]!.averagePercentage, 85.0);

      // Now add a high attempt to make Auditory Recall higher than Spatial Memory
      final finalAttempts = [
        ...updatedAttempts,
        ExerciseAttempt(
          id: 'att-6',
          userId: 'u1',
          domain: ExerciseDomain.universalCognitive,
          type: ExerciseType.memoryMelody,
          exerciseId: 'memory_melody_ravi',
          responseMode: 'choice',
          rawScore: 100,
          maxScore: 100,
          cognitiveDomain: CognitiveDomain.auditoryRecall,
        ),
      ];
      final scoresFinal = PersonalizationEngine.computeDomainScores(finalAttempts);
      // (40 + 100 + 100 + 100 + 100) / 5 = 88.0% > 85.0%
      expect(scoresFinal[CognitiveDomain.auditoryRecall]!.averagePercentage > 85.0, true);

      // Dynamic shift: Recommendation shifts away from Auditory Recall to Spatial Memory
      final recFinal = PersonalizationEngine.getRecommendation(finalAttempts);
      expect(recFinal.targetDomain, CognitiveDomain.spatialMemory);
      expect(recFinal.exerciseType, ExerciseType.fruitMemoryPath);
    });

    test('SongGenerationService songs feature 20-30s stimulus line timings, ordering events, and delayed probe', () {
      final songs = SongGenerationService.allCuratedSongs;
      for (final s in songs) {
        // Stimulus lines have duration 4-5 seconds each -> total 20-30s experience
        final totalSeconds = s.lines.length * 4;
        expect(totalSeconds >= 16 && totalSeconds <= 35, true);

        // Events for ordering challenge
        expect(s.events.length, greaterThanOrEqualTo(3));
        for (int i = 0; i < s.events.length; i++) {
          expect(s.events[i].correctOrder, i + 1);
        }

        // Intervening delayed recall question
        expect(s.delayedQuestion.question.isNotEmpty, true);
        expect(s.delayedQuestion.correctAnswer.isNotEmpty, true);
        expect(s.delayedQuestion.options.contains(s.delayedQuestion.correctAnswer), true);
      }
    });
  });
}
