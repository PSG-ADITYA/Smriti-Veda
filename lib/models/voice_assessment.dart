class VoiceAssessmentResult {
  final String targetText;
  final String spokenText;
  final double accuracyScore; // 0.0 to 100.0 %
  final double sequenceScore; // 0.0 to 100.0 %
  final int totalExpectedWords;
  final int correctWordsCount;
  final List<String> missingWords;
  final List<String> matchedWords;
  final String feedbackMessage;
  final Duration responseDuration;

  const VoiceAssessmentResult({
    required this.targetText,
    required this.spokenText,
    required this.accuracyScore,
    required this.sequenceScore,
    required this.totalExpectedWords,
    required this.correctWordsCount,
    required this.missingWords,
    required this.matchedWords,
    required this.feedbackMessage,
    required this.responseDuration,
  });

  bool get isPassed => accuracyScore >= 60.0;
}
