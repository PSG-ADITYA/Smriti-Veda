import 'package:flutter/material.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';

enum ExercisePhase {
  setup,
  study,
  recall,
  feedback,
  complete,
}

class ExerciseEngine extends ChangeNotifier {
  ExercisePhase _phase = ExercisePhase.setup;
  final Stopwatch _stopwatch = Stopwatch();
  int _hintsUsed = 0;

  ExercisePhase get phase => _phase;
  int get timeTakenMs => _stopwatch.elapsedMilliseconds;
  int get hintsUsed => _hintsUsed;

  void reset() {
    _phase = ExercisePhase.setup;
    _stopwatch.reset();
    _hintsUsed = 0;
    notifyListeners();
  }

  void startStudy() {
    _phase = ExercisePhase.study;
    _stopwatch.reset();
    _stopwatch.start();
    notifyListeners();
  }

  void startRecall() {
    _phase = ExercisePhase.recall;
    notifyListeners();
  }

  void incrementHint() {
    _hintsUsed++;
    notifyListeners();
  }

  Future<void> finishAndLogAttempt({
    required AppState appState,
    required ExerciseDomain domain,
    required ExerciseType type,
    required String exerciseId,
    required String responseMode,
    required double rawScore,
    required double maxScore,
    int? stage,
    String? transcript,
    Map<String, dynamic>? metadata,
  }) async {
    _stopwatch.stop();
    _phase = ExercisePhase.feedback;
    notifyListeners();

    final attempt = ExerciseAttempt(
      id: 'att_${DateTime.now().millisecondsSinceEpoch}',
      userId: appState.credentialId,
      domain: domain,
      type: type,
      exerciseId: exerciseId,
      timestamp: DateTime.now(),
      stage: stage,
      responseMode: responseMode,
      rawScore: rawScore,
      maxScore: maxScore,
      timeTakenMs: timeTakenMs,
      hintsUsed: _hintsUsed,
      transcript: transcript,
      metadata: metadata,
    );

    await appState.attemptRepository.logAttempt(attempt);
  }

  void complete() {
    _phase = ExercisePhase.complete;
    notifyListeners();
  }
}
