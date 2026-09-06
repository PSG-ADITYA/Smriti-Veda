import '../models/exercise_attempt.dart';
import '../services/db_service.dart';
import 'exercise_attempt_repository.dart';

class LocalExerciseAttemptRepository implements ExerciseAttemptRepository {
  final List<ExerciseAttempt> _inMemoryAttempts = [];

  LocalExerciseAttemptRepository() {
    _loadFromDb();
  }

  void _loadFromDb() {
    try {
      final list = DbService().getLoggedAttempts();
      _inMemoryAttempts.clear();
      for (var item in list) {
        _inMemoryAttempts.add(ExerciseAttempt(
          id: item['id'] ?? 'att_${DateTime.now().millisecondsSinceEpoch}',
          userId: item['userId'] ?? 'patient123',
          domain: _parseDomain(item['domain']),
          type: _parseType(item['type']),
          exerciseId: item['exerciseId'] ?? 'ex_1',
          timestamp: DateTime.tryParse(item['timestamp'] ?? '') ?? DateTime.now(),
          stage: item['stage'],
          responseMode: item['responseMode'],
          rawScore: (item['rawScore'] as num?)?.toDouble() ?? 0.0,
          maxScore: (item['maxScore'] as num?)?.toDouble() ?? 100.0,
          timeTakenMs: item['timeTakenMs'],
          transcript: item['transcript'],
        ));
      }
    } catch (_) {}
  }

  ExerciseDomain _parseDomain(dynamic val) {
    if (val == 'ExerciseDomain.culturalOral' || val == 'culturalOral') return ExerciseDomain.culturalOral;
    if (val == 'ExerciseDomain.everydayMemory' || val == 'everydayMemory') return ExerciseDomain.everydayMemory;
    return ExerciseDomain.universalCognitive;
  }

  ExerciseType _parseType(dynamic val) {
    if (val == 'ExerciseType.familiarPersonRecall' || val == 'familiarPersonRecall') return ExerciseType.familiarPersonRecall;
    if (val == 'ExerciseType.reminderCheck' || val == 'reminderCheck') return ExerciseType.reminderCheck;
    if (val == 'ExerciseType.sequenceRecall' || val == 'sequenceRecall') return ExerciseType.sequenceRecall;
    return ExerciseType.structuredRecallPipeline;
  }

  @override
  Future<void> logAttempt(ExerciseAttempt attempt) async {
    _inMemoryAttempts.add(attempt);
    DbService().saveAttempt({
      'id': attempt.id,
      'userId': attempt.userId,
      'domain': attempt.domain.name,
      'type': attempt.type.name,
      'exerciseId': attempt.exerciseId,
      'timestamp': attempt.timestamp.toIso8601String(),
      'stage': attempt.stage,
      'responseMode': attempt.responseMode,
      'rawScore': attempt.rawScore,
      'maxScore': attempt.maxScore,
      'timeTakenMs': attempt.timeTakenMs,
      'transcript': attempt.transcript,
    });
  }

  @override
  List<ExerciseAttempt> getAttempts({
    ExerciseDomain? domain,
    ExerciseType? type,
    String? userId,
  }) {
    _loadFromDb();
    return _inMemoryAttempts.where((a) {
      if (domain != null && a.domain != domain) return false;
      if (type != null && a.type != type) return false;
      if (userId != null && a.userId != userId) return false;
      return true;
    }).toList();
  }

  @override
  List<ExerciseAttempt> getRecentAttempts({int limit = 50, String? userId}) {
    final filtered = getAttempts(userId: userId);
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered.take(limit).toList();
  }

  @override
  double getAverageScorePercentage({
    ExerciseDomain? domain,
    ExerciseType? type,
    String? userId,
  }) {
    final filtered = getAttempts(domain: domain, type: type, userId: userId);
    if (filtered.isEmpty) return 0.0;
    final totalPercentage = filtered.fold<double>(0.0, (sum, a) => sum + a.scorePercentage);
    return totalPercentage / filtered.length;
  }

  @override
  int getCompletedCount({
    ExerciseDomain? domain,
    ExerciseType? type,
    String? userId,
  }) {
    return getAttempts(domain: domain, type: type, userId: userId).length;
  }
}
