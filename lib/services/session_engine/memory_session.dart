import '../../models/exercise_attempt.dart';
import '../../models/game_difficulty.dart';

enum QuestionType {
  singleChoice,
  multiChoice,
  ordering,
  spatialPosition,
  missingElement,
  association,
}

class MemoryRecallQuestion {
  final String id;
  final String prompt;
  final QuestionType type;
  final List<String> options;
  final int correctIndex;
  final String correctAnswerText;
  final List<String>? targetOrder;
  final Map<String, dynamic>? metadata;

  const MemoryRecallQuestion({
    required this.id,
    required this.prompt,
    required this.type,
    required this.options,
    required this.correctIndex,
    required this.correctAnswerText,
    this.targetOrder,
    this.metadata,
  });

  bool isCorrect(dynamic userResponse) {
    if (userResponse is String && userResponse.trim().toLowerCase() == correctAnswerText.trim().toLowerCase()) {
      return true;
    }

    if (type == QuestionType.ordering && targetOrder != null) {
      if (userResponse is List<String>) {
        if (userResponse.length != targetOrder!.length) return false;
        for (int i = 0; i < targetOrder!.length; i++) {
          if (userResponse[i].trim().toLowerCase() != targetOrder![i].trim().toLowerCase()) return false;
        }
        return true;
      }
    }

    if (userResponse is int) {
      return userResponse == correctIndex;
    }
    return false;
  }
}

class MemoryTimingParams {
  final int previewSeconds;
  final int recallTimeoutSeconds;
  final int? delayIntervalSeconds;

  const MemoryTimingParams({
    required this.previewSeconds,
    this.recallTimeoutSeconds = 60,
    this.delayIntervalSeconds,
  });
}

class MemoryScoringConfig {
  final int baseScore;
  final int penaltyPerMistake;
  final double itemRecallWeight;
  final double sequenceWeight;
  final double spatialWeight;
  final double attentionWeight;

  const MemoryScoringConfig({
    this.baseScore = 100,
    this.penaltyPerMistake = 15,
    this.itemRecallWeight = 0.4,
    this.sequenceWeight = 0.3,
    this.spatialWeight = 0.2,
    this.attentionWeight = 0.1,
  });
}

class MemorySession<T> {
  final String sessionId;
  final ExerciseType gameType;
  final GameDifficulty difficulty;
  final Map<String, dynamic> difficultyParams;
  final T stimulus;
  final List<dynamic> sequence;
  final Map<String, dynamic> positions;
  final List<dynamic> distractors;
  final List<MemoryRecallQuestion> questions;
  final MemoryTimingParams timingParams;
  final MemoryScoringConfig scoringConfig;

  const MemorySession({
    required this.sessionId,
    required this.gameType,
    required this.difficulty,
    required this.difficultyParams,
    required this.stimulus,
    this.sequence = const [],
    this.positions = const {},
    this.distractors = const [],
    this.questions = const [],
    required this.timingParams,
    this.scoringConfig = const MemoryScoringConfig(),
  });
}
