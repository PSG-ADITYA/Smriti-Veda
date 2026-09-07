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
          cognitiveDomain: _parseCognitiveDomain(item['cognitiveDomain']),
          exerciseId: item['exerciseId'] ?? 'ex_1',
          timestamp: DateTime.tryParse(item['timestamp'] ?? '') ?? DateTime.now(),
          stage: item['stage'],
          responseMode: item['responseMode'] ?? 'choice',
          rawScore: (item['rawScore'] as num?)?.toDouble() ?? 0.0,
          maxScore: (item['maxScore'] as num?)?.toDouble() ?? 100.0,
          timeTakenMs: item['timeTakenMs'] ?? 0,
          transcript: item['transcript'],
          metadata: item['metadata'] is Map ? Map<String, dynamic>.from(item['metadata']) : null,
        ));
      }
    } catch (_) {}
  }

  ExerciseDomain _parseDomain(dynamic val) {
    if (val == 'ExerciseDomain.culturalOral' || val == 'culturalOral') return ExerciseDomain.culturalOral;
    if (val == 'ExerciseDomain.everydayMemory' || val == 'everydayMemory') return ExerciseDomain.everydayMemory;
    return ExerciseDomain.universalCognitive;
  }

  CognitiveDomain? _parseCognitiveDomain(dynamic val) {
    if (val == null) return null;
    final str = val.toString().replaceAll('CognitiveDomain.', '');
    for (final d in CognitiveDomain.values) {
      if (d.name == str) return d;
    }
    return null;
  }

  ExerciseType _parseType(dynamic val) {
    if (val == null) return ExerciseType.structuredRecallPipeline;
    final str = val.toString().replaceAll('ExerciseType.', '');
    for (final t in ExerciseType.values) {
      if (t.name == str) return t;
    }
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
      'cognitiveDomain': attempt.cognitiveDomain.name,
      'exerciseId': attempt.exerciseId,
      'timestamp': attempt.timestamp.toIso8601String(),
      'stage': attempt.stage,
      'responseMode': attempt.responseMode,
      'rawScore': attempt.rawScore,
      'maxScore': attempt.maxScore,
      'timeTakenMs': attempt.timeTakenMs,
      'transcript': attempt.transcript,
      'metadata': attempt.metadata,
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

  List<ExerciseAttempt> getAttemptsForCognitiveDomain(CognitiveDomain domain, {String? userId}) {
    _loadFromDb();
    return _inMemoryAttempts.where((a) {
      if (a.cognitiveDomain != domain) return false;
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
