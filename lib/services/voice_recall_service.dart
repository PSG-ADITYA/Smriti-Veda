import 'dart:math';
import '../models/voice_assessment.dart';

class VoiceRecallService {
  /// Evaluates the spoken text against the expected target text
  static VoiceAssessmentResult evaluateRecitation({
    required String targetText,
    required String spokenText,
    required Duration duration,
  }) {
    final cleanTargetWords = _tokenizeAndClean(targetText);
    final cleanSpokenWords = _tokenizeAndClean(spokenText);

    if (cleanTargetWords.isEmpty) {
      return VoiceAssessmentResult(
        targetText: targetText,
        spokenText: spokenText,
        accuracyScore: 0.0,
        sequenceScore: 0.0,
        totalExpectedWords: 0,
        correctWordsCount: 0,
        missingWords: [],
        matchedWords: [],
        feedbackMessage: 'Target text is empty.',
        responseDuration: duration,
      );
    }

    final matchedWords = <String>[];
    final missingWords = <String>[];
    int correctCount = 0;

    for (var targetWord in cleanTargetWords) {
      bool found = false;
      for (var spokenWord in cleanSpokenWords) {
        if (_isSimilar(targetWord, spokenWord)) {
          found = true;
          break;
        }
      }
      if (found) {
        correctCount++;
        matchedWords.add(targetWord);
      } else {
        missingWords.add(targetWord);
      }
    }

    final accuracy = (correctCount / cleanTargetWords.length * 100.0).clamp(0.0, 100.0);

    // Sequence Preservation via Levenshtein Distance
    final sequenceAlignment = _calculateSequenceMatch(cleanTargetWords, cleanSpokenWords);

    String feedback;
    if (accuracy >= 85.0) {
      feedback = 'उत्कृष्टम् (Excellent)! Outstanding vocal recall & rhythm.';
    } else if (accuracy >= 60.0) {
      feedback = 'शोभनम् (Well Done)! Good recitation; practice missing phrases.';
    } else {
      feedback = 'पुनः प्रयत्नं कुरु (Keep Practicing)! Take your time and listen again.';
    }

    return VoiceAssessmentResult(
      targetText: targetText,
      spokenText: spokenText,
      accuracyScore: double.parse(accuracy.toStringAsFixed(1)),
      sequenceScore: double.parse(sequenceAlignment.toStringAsFixed(1)),
      totalExpectedWords: cleanTargetWords.length,
      correctWordsCount: correctCount,
      missingWords: missingWords,
      matchedWords: matchedWords,
      feedbackMessage: feedback,
      responseDuration: duration,
    );
  }

  static List<String> _tokenizeAndClean(String text) {
    return text
        .replaceAll(RegExp(r'[।॥\.\,\-\?\!\(\)\n\r]'), ' ')
        .split(RegExp(r'\s+'))
        .map((w) => w.trim().toLowerCase())
        .where((w) => w.isNotEmpty)
        .toList();
  }

  static bool _isSimilar(String a, String b) {
    if (a == b) return true;
    if (a.contains(b) || b.contains(a)) return true;
    final dist = _levenshtein(a, b);
    final maxLen = max(a.length, b.length);
    return (maxLen > 0) && (dist / maxLen <= 0.35);
  }

  static double _calculateSequenceMatch(List<String> target, List<String> spoken) {
    if (target.isEmpty || spoken.isEmpty) return 0.0;
    int matches = 0;
    int minLen = min(target.length, spoken.length);
    for (int i = 0; i < minLen; i++) {
      if (_isSimilar(target[i], spoken[i])) {
        matches++;
      }
    }
    return (matches / target.length * 100.0).clamp(0.0, 100.0);
  }

  static int _levenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }
}
