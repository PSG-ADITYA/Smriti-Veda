import 'package:flutter/material.dart';
import '../models/exercise_attempt.dart';

class CognitiveDomainScore {
  final CognitiveDomain domain;
  final double averagePercentage;
  final int attemptCount;
  final DateTime? lastAttemptTime;

  const CognitiveDomainScore({
    required this.domain,
    required this.averagePercentage,
    required this.attemptCount,
    this.lastAttemptTime,
  });

  bool get hasSufficientData => attemptCount > 0;
}

class ExerciseRecommendation {
  final String exerciseTitle;
  final String exerciseSubtitle;
  final CognitiveDomain targetDomain;
  final ExerciseType exerciseType;
  final String reason;
  final String difficultyLabel;
  final IconData icon;
  final Color color;

  const ExerciseRecommendation({
    required this.exerciseTitle,
    required this.exerciseSubtitle,
    required this.targetDomain,
    required this.exerciseType,
    required this.reason,
    required this.difficultyLabel,
    required this.icon,
    required this.color,
  });
}

class PersonalizationEngine {
  /// Analyzes recent attempts and computes domain scores across all cognitive domains
  static Map<CognitiveDomain, CognitiveDomainScore> computeDomainScores(
    List<ExerciseAttempt> attempts,
  ) {
    final Map<CognitiveDomain, List<double>> domainPercentages = {};
    final Map<CognitiveDomain, DateTime?> lastTimes = {};

    for (final domain in CognitiveDomain.values) {
      domainPercentages[domain] = [];
      lastTimes[domain] = null;
    }

    for (final attempt in attempts) {
      final domain = attempt.cognitiveDomain;
      domainPercentages[domain]?.add(attempt.scorePercentage);
      final prevTime = lastTimes[domain];
      if (prevTime == null || attempt.timestamp.isAfter(prevTime)) {
        lastTimes[domain] = attempt.timestamp;
      }
    }

    final Map<CognitiveDomain, CognitiveDomainScore> results = {};
    for (final domain in CognitiveDomain.values) {
      final scores = domainPercentages[domain] ?? [];
      final count = scores.length;
      final avg = count > 0 ? (scores.reduce((a, b) => a + b) / count) : 0.0;
      results[domain] = CognitiveDomainScore(
        domain: domain,
        averagePercentage: avg,
        attemptCount: count,
        lastAttemptTime: lastTimes[domain],
      );
    }
    return results;
  }

  /// Identifies the weakest domain or domain requiring practice
  static CognitiveDomain identifyWeakestDomain(
    Map<CognitiveDomain, CognitiveDomainScore> domainScores,
  ) {
    CognitiveDomain? lowestScoringDomain;
    double lowestScore = 101.0;

    for (final entry in domainScores.entries) {
      if (entry.value.hasSufficientData && entry.value.averagePercentage < lowestScore) {
        lowestScore = entry.value.averagePercentage;
        lowestScoringDomain = entry.key;
      }
    }

    if (lowestScoringDomain != null) {
      return lowestScoringDomain;
    }

    for (final domain in CognitiveDomain.values) {
      if (!domainScores[domain]!.hasSufficientData) {
        return domain;
      }
    }

    return CognitiveDomain.spatialMemory;
  }

  /// Generates a personalized exercise recommendation based on domain performance
  static ExerciseRecommendation getRecommendation(
    List<ExerciseAttempt> attempts,
  ) {
    final domainScores = computeDomainScores(attempts);
    final targetDomain = identifyWeakestDomain(domainScores);
    final targetScore = domainScores[targetDomain];

    switch (targetDomain) {
      case CognitiveDomain.spatialMemory:
        return ExerciseRecommendation(
          exerciseTitle: 'Fruit Memory Path',
          exerciseSubtitle: 'Memorize fruit locations & navigate your avatar',
          targetDomain: targetDomain,
          exerciseType: ExerciseType.fruitMemoryPath,
          reason: targetScore != null && targetScore.hasSufficientData
              ? 'Spatial memory score is currently ${targetScore.averagePercentage.toInt()}%. Practice navigation to reinforce working landmarks.'
              : 'Recommended today to establish your baseline spatial and path memory.',
          difficultyLabel: 'Level 1 (Adaptive)',
          icon: Icons.map_rounded,
          color: const Color(0xFFE07A5F),
        );

      case CognitiveDomain.attentionFocus:
        return ExerciseRecommendation(
          exerciseTitle: 'Attention & Focus Challenge',
          exerciseSubtitle: 'Spot target symbols among visual distractors',
          targetDomain: targetDomain,
          exerciseType: ExerciseType.attention,
          reason: targetScore != null && targetScore.hasSufficientData
              ? 'Attention score is ${targetScore.averagePercentage.toInt()}%. Sharp concentration practice helps daily focus.'
              : 'Exercise your selective visual attention and filter out distractions.',
          difficultyLabel: 'Timed Round',
          icon: Icons.center_focus_strong_rounded,
          color: const Color(0xFFD4A373),
        );

      case CognitiveDomain.visualMemory:
        return ExerciseRecommendation(
          exerciseTitle: 'Object Recall Matrix',
          exerciseSubtitle: 'Observe household scenes & recall hidden items',
          targetDomain: targetDomain,
          exerciseType: ExerciseType.recognition,
          reason: targetScore != null && targetScore.hasSufficientData
              ? 'Visual recall is at ${targetScore.averagePercentage.toInt()}%. Strengthen everyday object recognition.'
              : 'Remember familiar objects placed in everyday room settings.',
          difficultyLabel: 'Visual Mode',
          icon: Icons.visibility_rounded,
          color: const Color(0xFF3D5A80),
        );

      case CognitiveDomain.sequentialMemory:
        return ExerciseRecommendation(
          exerciseTitle: 'Sequence Recall',
          exerciseSubtitle: 'Memorize & order symbols in chronological sequence',
          targetDomain: targetDomain,
          exerciseType: ExerciseType.sequenceRecall,
          reason: targetScore != null && targetScore.hasSufficientData
              ? 'Sequence memory is at ${targetScore.averagePercentage.toInt()}%. Sequential practice enhances step-by-step recall.'
              : 'Practice ordering sequences to strengthen mental chaining.',
          difficultyLabel: 'Chaining Mode',
          icon: Icons.format_list_numbered_rounded,
          color: const Color(0xFF5B8E7D),
        );

      case CognitiveDomain.auditoryRecall:
        return ExerciseRecommendation(
          exerciseTitle: 'Memory Melody',
          exerciseSubtitle: 'Listen to melodic verses & test item and sequence recall',
          targetDomain: targetDomain,
          exerciseType: ExerciseType.memoryMelody,
          reason: targetScore != null && targetScore.hasSufficientData
              ? 'Auditory recall is at ${targetScore.averagePercentage.toInt()}%. Rhythmic melodies and events stimulate multi-task recall.'
              : 'Enjoy a pleasant rhythmic song and practice recalling items, sequence, and details.',
          difficultyLabel: 'Melodic Recall',
          icon: Icons.music_note_rounded,
          color: const Color(0xFF8F5C86),
        );

      case CognitiveDomain.workingMemory:
        return ExerciseRecommendation(
          exerciseTitle: 'Pattern Memory Grid',
          exerciseSubtitle: 'Reconstruct visual grid matrices from memory',
          targetDomain: targetDomain,
          exerciseType: ExerciseType.patternRecall,
          reason: targetScore != null && targetScore.hasSufficientData
              ? 'Working memory score is ${targetScore.averagePercentage.toInt()}%. Pattern reconstruction exercises active retention.'
              : 'Challenge your working memory by reconstructing illuminated tile patterns.',
          difficultyLabel: 'Grid Matrix',
          icon: Icons.grid_on_rounded,
          color: const Color(0xFF4A7C59),
        );

      case CognitiveDomain.prospectiveMemory:
        return ExerciseRecommendation(
          exerciseTitle: 'Daily Routine Recall',
          exerciseSubtitle: 'Sequence your morning routine & medication habits',
          targetDomain: targetDomain,
          exerciseType: ExerciseType.dailyRoutineRecall,
          reason: targetScore != null && targetScore.hasSufficientData
              ? 'Routine recall is at ${targetScore.averagePercentage.toInt()}%. Habit sequencing helps everyday independence.'
              : 'Connect your real daily habits and reminders with sequence exercises.',
          difficultyLabel: 'Everyday Recall',
          icon: Icons.access_time_filled_rounded,
          color: const Color(0xFFB85028),
        );

      case CognitiveDomain.semanticMemory:
        return ExerciseRecommendation(
          exerciseTitle: 'Word Association',
          exerciseSubtitle: 'Match related concepts & meaningful language pairs',
          targetDomain: targetDomain,
          exerciseType: ExerciseType.wordAssociation,
          reason: targetScore != null && targetScore.hasSufficientData
              ? 'Language association score is ${targetScore.averagePercentage.toInt()}%. Semantic pairing keeps language agile.'
              : 'Form connections between related words, opposites, and regional idioms.',
          difficultyLabel: 'Semantic Pairs',
          icon: Icons.menu_book_rounded,
          color: const Color(0xFF386641),
        );
    }
  }
}
