import 'dart:math';
import '../../models/exercise_attempt.dart';
import '../../models/game_difficulty.dart';
import '../db_service.dart';
import '../personalization_engine.dart';
import 'memory_session.dart';

class SessionEvaluationResult {
  final double scorePct;
  final double itemRecallScore;
  final double sequenceRecallScore;
  final double spatialRecallScore;
  final double attentionScore;
  final int correctAnswers;
  final int totalQuestions;
  final ExerciseAttempt attempt;

  const SessionEvaluationResult({
    required this.scorePct,
    required this.itemRecallScore,
    required this.sequenceRecallScore,
    required this.spatialRecallScore,
    required this.attentionScore,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.attempt,
  });
}

class MemoryScoringEngine {
  /// Evaluates a question-based memory session (such as 3D Dice Memory or Word Memory Puzzle).
  static Future<SessionEvaluationResult> evaluateQuestionSession({
    required MemorySession session,
    required Map<String, dynamic> userAnswers,
    required int timeTakenMs,
    int mistakes = 0,
    String? userId,
  }) async {
    final questions = session.questions;
    int correctCount = 0;
    int totalQuestions = questions.length;

    int itemRecallCorrect = 0;
    int itemRecallTotal = 0;
    int seqRecallCorrect = 0;
    int seqRecallTotal = 0;
    int spatialRecallCorrect = 0;
    int spatialRecallTotal = 0;

    for (final q in questions) {
      final userAns = userAnswers[q.id];
      final isCorrect = q.isCorrect(userAns);
      if (isCorrect) correctCount++;

      switch (q.type) {
        case QuestionType.singleChoice:
        case QuestionType.multiChoice:
        case QuestionType.missingElement:
          itemRecallTotal++;
          if (isCorrect) itemRecallCorrect++;
          break;
        case QuestionType.ordering:
          seqRecallTotal++;
          if (isCorrect) seqRecallCorrect++;
          break;
        case QuestionType.spatialPosition:
          spatialRecallTotal++;
          if (isCorrect) spatialRecallCorrect++;
          break;
        case QuestionType.association:
          itemRecallTotal++;
          if (isCorrect) itemRecallCorrect++;
          break;
      }
    }

    final itemScore = itemRecallTotal > 0 ? (itemRecallCorrect / itemRecallTotal) : 1.0;
    final seqScore = seqRecallTotal > 0 ? (seqRecallCorrect / seqRecallTotal) : 1.0;
    final spatialScore = spatialRecallTotal > 0 ? (spatialRecallCorrect / spatialRecallTotal) : 1.0;
    // Attention factor: penalized by time overage or mistakes
    final attentionScore = max(0.0, 1.0 - (mistakes * 0.15));

    final rawPercentage = totalQuestions > 0
        ? (correctCount / totalQuestions) * 100.0
        : 100.0;
    final clampedScore = rawPercentage.clamp(0.0, 100.0);

    final currentUid = userId ?? DbService().activeUserId;

    final attempt = ExerciseAttempt(
      id: 'att_${session.gameType.name}_${DateTime.now().millisecondsSinceEpoch}',
      userId: currentUid,
      domain: ExerciseDomain.universalCognitive,
      type: session.gameType,
      exerciseId: session.sessionId,
      responseMode: 'choice',
      rawScore: clampedScore,
      maxScore: 100.0,
      timeTakenMs: timeTakenMs,
      hintsUsed: mistakes,
      metadata: {
        'difficulty': session.difficulty.name,
        'itemRecallScore': itemScore,
        'sequenceRecallScore': seqScore,
        'spatialRecallScore': spatialScore,
        'attentionScore': attentionScore,
        'totalQuestions': totalQuestions,
        'correctAnswers': correctCount,
      },
    );

    DbService().saveExerciseAttempt(attempt);

    // Provide non-diagnostic feedback recommendation via PersonalizationEngine
    PersonalizationEngine.evaluateAttempt(attempt);

    return SessionEvaluationResult(
      scorePct: clampedScore,
      itemRecallScore: itemScore,
      sequenceRecallScore: seqScore,
      spatialRecallScore: spatialScore,
      attentionScore: attentionScore,
      correctAnswers: correctCount,
      totalQuestions: totalQuestions,
      attempt: attempt,
    );
  }

  /// Evaluates a continuous action session (such as Fruit Memory Path, Pattern Grid, or Attention Scan).
  static Future<ExerciseAttempt> recordContinuousSession({
    required ExerciseType gameType,
    required String sessionId,
    required GameDifficulty difficulty,
    required double accuracyPct,
    required int timeTakenMs,
    required int mistakes,
    Map<String, dynamic>? extraMetrics,
    String? userId,
  }) async {
    final currentUid = userId ?? DbService().activeUserId;
    final clampedAccuracy = accuracyPct.clamp(0.0, 100.0);

    final attempt = ExerciseAttempt(
      id: 'att_${gameType.name}_${DateTime.now().millisecondsSinceEpoch}',
      userId: currentUid,
      domain: ExerciseDomain.universalCognitive,
      type: gameType,
      exerciseId: sessionId,
      responseMode: 'action',
      rawScore: clampedAccuracy,
      maxScore: 100.0,
      timeTakenMs: timeTakenMs,
      hintsUsed: mistakes,
      metadata: {
        'difficulty': difficulty.name,
        'attentionScore': max(0.0, 1.0 - (mistakes * 0.1)),
        ...?extraMetrics,
      },
    );

    DbService().saveExerciseAttempt(attempt);
    PersonalizationEngine.evaluateAttempt(attempt);
    return attempt;
  }
}
