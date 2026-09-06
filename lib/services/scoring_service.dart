import 'dart:math';

class SequenceScoreResult {
  final double rawScore;
  final double maxScore;
  final double percentage;
  final int exactMatchesCount;
  final int totalItems;
  final String feedbackText;

  const SequenceScoreResult({
    required this.rawScore,
    required this.maxScore,
    required this.percentage,
    required this.exactMatchesCount,
    required this.totalItems,
    required this.feedbackText,
  });
}

class RecognitionScoreResult {
  final double rawScore;
  final double maxScore;
  final double percentage;
  final int correctSelectionsCount;
  final int falsePositivesCount;
  final int totalTargetItems;
  final String feedbackText;

  const RecognitionScoreResult({
    required this.rawScore,
    required this.maxScore,
    required this.percentage,
    required this.correctSelectionsCount,
    required this.falsePositivesCount,
    required this.totalTargetItems,
    required this.feedbackText,
  });
}

class ScoringService {
  /// Deterministic Sequence Recall Scoring
  /// Compares [expectedSequence] vs [actualSequence] positionally and calculates score percentage.
  static SequenceScoreResult computeSequenceScore(
    List<String> expectedSequence,
    List<String> actualSequence,
  ) {
    if (expectedSequence.isEmpty) {
      return const SequenceScoreResult(
        rawScore: 0,
        maxScore: 0,
        percentage: 0,
        exactMatchesCount: 0,
        totalItems: 0,
        feedbackText: 'No sequence provided.',
      );
    }

    int exactMatches = 0;
    final minLength = min(expectedSequence.length, actualSequence.length);

    for (int i = 0; i < minLength; i++) {
      if (expectedSequence[i].trim().toLowerCase() == actualSequence[i].trim().toLowerCase()) {
        exactMatches++;
      }
    }

    final double maxScore = expectedSequence.length.toDouble();
    final double rawScore = exactMatches.toDouble();
    final double percentage = (rawScore / maxScore) * 100.0;

    String feedback;
    if (percentage == 100.0) {
      feedback = 'Perfect Recall! Every item in exact sequence order.';
    } else if (percentage >= 75.0) {
      feedback = 'Great Recall! Excellent sequence retention.';
    } else if (percentage >= 50.0) {
      feedback = 'Good Effort! Keep practicing to improve accuracy.';
    } else {
      feedback = 'Keep practicing! Review the sequence once more.';
    }

    return SequenceScoreResult(
      rawScore: rawScore,
      maxScore: maxScore,
      percentage: percentage,
      exactMatchesCount: exactMatches,
      totalItems: expectedSequence.length,
      feedbackText: feedback,
    );
  }

  /// Deterministic Recognition Memory Scoring
  /// Compares user [selectedItems] against [targetItems].
  static RecognitionScoreResult computeRecognitionScore(
    Set<String> targetItems,
    Set<String> selectedItems,
  ) {
    if (targetItems.isEmpty) {
      return const RecognitionScoreResult(
        rawScore: 0,
        maxScore: 0,
        percentage: 0,
        correctSelectionsCount: 0,
        falsePositivesCount: 0,
        totalTargetItems: 0,
        feedbackText: 'No target items provided.',
      );
    }

    int correctSelections = 0;
    int falsePositives = 0;

    for (final item in selectedItems) {
      if (targetItems.contains(item)) {
        correctSelections++;
      } else {
        falsePositives++;
      }
    }

    // Net score subtracts false positives, clamped to 0
    final double rawScore = max(0, correctSelections - falsePositives).toDouble();
    final double maxScore = targetItems.length.toDouble();
    final double percentage = (rawScore / maxScore) * 100.0;

    String feedback;
    if (percentage == 100.0) {
      feedback = 'Perfect Recognition! All target items identified.';
    } else if (percentage >= 75.0) {
      feedback = 'Strong Recognition! Excellent visual memory.';
    } else if (percentage >= 50.0) {
      feedback = 'Fair Recognition. Watch out for distractor items!';
    } else {
      feedback = 'Keep practicing! Focus on target items in study phase.';
    }

    return RecognitionScoreResult(
      rawScore: rawScore,
      maxScore: maxScore,
      percentage: percentage,
      correctSelectionsCount: correctSelections,
      falsePositivesCount: falsePositives,
      totalTargetItems: targetItems.length,
      feedbackText: feedback,
    );
  }
}
