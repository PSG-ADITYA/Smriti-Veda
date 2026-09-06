import '../models/exercise_attempt.dart';

abstract class ExerciseAttemptRepository {
  /// Log a new attempt to the append-only event log
  Future<void> logAttempt(ExerciseAttempt attempt);

  /// Retrieve all attempts filtered by domain, type, or userId
  List<ExerciseAttempt> getAttempts({
    ExerciseDomain? domain,
    ExerciseType? type,
    String? userId,
  });

  /// Retrieve N recent attempts sorted by timestamp descending
  List<ExerciseAttempt> getRecentAttempts({int limit = 50, String? userId});

  /// Compute rolling average score percentage for a domain or exercise type
  double getAverageScorePercentage({
    ExerciseDomain? domain,
    ExerciseType? type,
    String? userId,
  });

  /// Get total count of completed exercises/events
  int getCompletedCount({
    ExerciseDomain? domain,
    ExerciseType? type,
    String? userId,
  });
}
