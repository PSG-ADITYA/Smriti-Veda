import 'package:flutter/material.dart';

enum ExerciseDomain {
  universalCognitive,
  culturalOral,
  everydayMemory,
}

enum CognitiveDomain {
  spatialMemory,
  visualMemory,
  attentionFocus,
  sequentialMemory,
  auditoryRecall,
  workingMemory,
  prospectiveMemory,
  semanticMemory;

  String get displayName {
    switch (this) {
      case CognitiveDomain.spatialMemory:
        return 'Spatial Memory';
      case CognitiveDomain.visualMemory:
        return 'Visual Memory';
      case CognitiveDomain.attentionFocus:
        return 'Attention & Focus';
      case CognitiveDomain.sequentialMemory:
        return 'Sequential Memory';
      case CognitiveDomain.auditoryRecall:
        return 'Auditory Recall';
      case CognitiveDomain.workingMemory:
        return 'Working Memory';
      case CognitiveDomain.prospectiveMemory:
        return 'Everyday & Routine Recall';
      case CognitiveDomain.semanticMemory:
        return 'Language & Association';
    }
  }

  String get description {
    switch (this) {
      case CognitiveDomain.spatialMemory:
        return 'Remembering grid paths, directional locations, and spatial landmarks.';
      case CognitiveDomain.visualMemory:
        return 'Recognizing household objects, scenes, and visual cues accurately.';
      case CognitiveDomain.attentionFocus:
        return 'Filtering out visual distractions and sustaining active concentration.';
      case CognitiveDomain.sequentialMemory:
        return 'Retaining the exact chronological order of numbers, symbols, and steps.';
      case CognitiveDomain.auditoryRecall:
        return 'Listening to oral stories, regional proverbs, and rhythmic verses.';
      case CognitiveDomain.workingMemory:
        return 'Holding and manipulating patterns and items temporarily in active mind.';
      case CognitiveDomain.prospectiveMemory:
        return 'Recalling daily routines, medicine schedules, and important habits.';
      case CognitiveDomain.semanticMemory:
        return 'Connecting word concepts, meanings, and familiar everyday associations.';
    }
  }

  IconData get icon {
    switch (this) {
      case CognitiveDomain.spatialMemory:
        return Icons.explore_rounded;
      case CognitiveDomain.visualMemory:
        return Icons.visibility_rounded;
      case CognitiveDomain.attentionFocus:
        return Icons.center_focus_strong_rounded;
      case CognitiveDomain.sequentialMemory:
        return Icons.format_list_numbered_rounded;
      case CognitiveDomain.auditoryRecall:
        return Icons.record_voice_over_rounded;
      case CognitiveDomain.workingMemory:
        return Icons.grid_on_rounded;
      case CognitiveDomain.prospectiveMemory:
        return Icons.access_time_filled_rounded;
      case CognitiveDomain.semanticMemory:
        return Icons.menu_book_rounded;
    }
  }

  Color get color {
    switch (this) {
      case CognitiveDomain.spatialMemory:
        return const Color(0xFFE07A5F); // Terracotta
      case CognitiveDomain.visualMemory:
        return const Color(0xFF3D5A80); // Deep Slate Blue
      case CognitiveDomain.attentionFocus:
        return const Color(0xFFD4A373); // Sandalwood Gold
      case CognitiveDomain.sequentialMemory:
        return const Color(0xFF5B8E7D); // Sage Green
      case CognitiveDomain.auditoryRecall:
        return const Color(0xFF8F5C86); // Warm Plum
      case CognitiveDomain.workingMemory:
        return const Color(0xFF4A7C59); // Forest Sage
      case CognitiveDomain.prospectiveMemory:
        return const Color(0xFFB85028); // Rust Terracotta
      case CognitiveDomain.semanticMemory:
        return const Color(0xFF386641); // Herbal Olive
    }
  }
}

enum ExerciseType {
  fruitMemoryPath,
  memoryMelody,
  sequenceRecall,
  recognition,
  patternRecall,
  attention,
  storyMemory,
  wordAssociation,
  dailyRoutineRecall,
  structuredRecallPipeline,
  familiarPersonRecall,
  reminderCheck,
  routineStepCheck,
  delayedRecall,
  diceMemory,
  wordMemoryPuzzle,
}

class ExerciseAttempt {
  final String id;
  final String userId;
  final ExerciseDomain domain;
  final ExerciseType type;
  final CognitiveDomain cognitiveDomain;
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
    CognitiveDomain? cognitiveDomain,
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
  })  : cognitiveDomain = cognitiveDomain ?? _inferCognitiveDomain(type, exerciseId),
        timestamp = timestamp ?? DateTime.now();

  static CognitiveDomain _inferCognitiveDomain(ExerciseType type, String exerciseId) {
    if (exerciseId.contains('fruit')) return CognitiveDomain.spatialMemory;
    switch (type) {
      case ExerciseType.fruitMemoryPath:
        return CognitiveDomain.spatialMemory;
      case ExerciseType.recognition:
        if (exerciseId.contains('pattern')) return CognitiveDomain.workingMemory;
        return CognitiveDomain.visualMemory;
      case ExerciseType.patternRecall:
        return CognitiveDomain.workingMemory;
      case ExerciseType.sequenceRecall:
        return CognitiveDomain.sequentialMemory;
      case ExerciseType.attention:
        return CognitiveDomain.attentionFocus;
      case ExerciseType.memoryMelody:
      case ExerciseType.storyMemory:
        return CognitiveDomain.auditoryRecall;
      case ExerciseType.wordAssociation:
        return CognitiveDomain.semanticMemory;
      case ExerciseType.dailyRoutineRecall:
      case ExerciseType.routineStepCheck:
      case ExerciseType.reminderCheck:
        return CognitiveDomain.prospectiveMemory;
      case ExerciseType.familiarPersonRecall:
        return CognitiveDomain.visualMemory;
      case ExerciseType.structuredRecallPipeline:
        return CognitiveDomain.auditoryRecall;
      case ExerciseType.delayedRecall:
        return CognitiveDomain.visualMemory;
      case ExerciseType.diceMemory:
        return CognitiveDomain.spatialMemory;
      case ExerciseType.wordMemoryPuzzle:
        return CognitiveDomain.semanticMemory;
    }
  }

  double? get itemRecallScore => (metadata?['itemRecallScore'] as num?)?.toDouble();
  double? get sequenceRecallScore => (metadata?['sequenceRecallScore'] as num?)?.toDouble();
  double? get delayedRecallScore => (metadata?['delayedRecallScore'] as num?)?.toDouble();
  double? get attentionScore => (metadata?['attentionScore'] as num?)?.toDouble();

  double get scorePercentage => maxScore > 0 ? (rawScore / maxScore) * 100.0 : 0.0;
  bool get isPassed => scorePercentage >= 60.0;
}
