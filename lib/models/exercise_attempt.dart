enum ExerciseDomain {
  universalCognitive,
  culturalOral,
  everydayMemory,
}

enum ExerciseType {
  sequenceRecall,
  recognition,
  attention,
  structuredRecallPipeline,
  familiarPersonRecall,
  reminderCheck,
  routineStepCheck,
}

class ExerciseAttempt {
  final String id;
  final String userId;
  final ExerciseDomain domain;
  final ExerciseType type;
  final String exerciseId;
  final DateTime timestamp;
  final int? stage; // 1 to 7 for pipeline stages, null for single exercises
  final String responseMode; // 'voice', 'text', 'choice', 'action'
  final double rawScore;
  final double maxScore;
  final int timeTakenMs;
  final int hintsUsed;
  final int? delayIntervalMinutes;
  final String? transcript;
  final Map<String, dynamic>? metadata;

  ExerciseAttempt({
    required this.id,
    required this.userId,
    required this.domain,
    required this.type,
    required this.exerciseId,
    DateTime? timestamp,
    this.stage,
    required this.responseMode,
    required this.rawScore,
    required this.maxScore,
    this.timeTakenMs = 0,
    this.hintsUsed = 0,
    this.delayIntervalMinutes,
    this.transcript,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  double get scorePercentage => maxScore > 0 ? (rawScore / maxScore) * 100.0 : 0.0;
  bool get isPassed => scorePercentage >= 60.0;
}
