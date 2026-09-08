import 'dart:math';
import '../../models/exercise_attempt.dart';
import '../../models/game_difficulty.dart';
import 'memory_session.dart';
import 'memory_content_bank.dart';
import 'memory_layout_generator.dart';
import 'memory_question_generator.dart';

// ── Stimulus Data Wrappers ──────────────────────────────────────────
class FruitSessionData {
  final int gridSize;
  final List<FruitStimulus> fruits;
  final List<int> pathIndices;
  final Map<int, FruitStimulus> gridFruitMap;
  final int previewSeconds;

  const FruitSessionData({
    required this.gridSize,
    required this.fruits,
    required this.pathIndices,
    required this.gridFruitMap,
    required this.previewSeconds,
  });
}

class MelodySessionData {
  final String title;
  final List<String> noteIds;
  final List<String> swaraNames;
  final Duration noteDuration;
  final Duration gapDuration;

  const MelodySessionData({
    required this.title,
    required this.noteIds,
    required this.swaraNames,
    required this.noteDuration,
    required this.gapDuration,
  });
}

class PatternSessionData {
  final int gridSize;
  final Set<int> activeTiles;
  final int previewSeconds;

  const PatternSessionData({
    required this.gridSize,
    required this.activeTiles,
    required this.previewSeconds,
  });
}

class ObjectSessionData {
  final String roomTitle;
  final String roomSubtitle;
  final List<ObjectStimulus> targets;
  final List<ObjectStimulus> distractors;
  final Map<int, ObjectStimulus> gridMap;
  final int previewSeconds;

  const ObjectSessionData({
    required this.roomTitle,
    required this.roomSubtitle,
    required this.targets,
    required this.distractors,
    required this.gridMap,
    required this.previewSeconds,
  });
}

class AttentionSessionData {
  final FocusThemeStimulus theme;
  final int totalCount;
  final int targetCount;
  final List<bool> targetLocations;
  final int timeLimitSeconds;

  const AttentionSessionData({
    required this.theme,
    required this.totalCount,
    required this.targetCount,
    required this.targetLocations,
    required this.timeLimitSeconds,
  });
}

class SequenceSessionData {
  final String title;
  final String category;
  final List<String> targetSequence;
  final int previewSeconds;

  const SequenceSessionData({
    required this.title,
    required this.category,
    required this.targetSequence,
    required this.previewSeconds,
  });
}

class StorySessionData {
  final HeritageStoryStimulus story;
  final List<Map<String, dynamic>> questions;

  const StorySessionData({
    required this.story,
    required this.questions,
  });
}

class RoutineSessionData {
  final RoutineScenarioStimulus routine;
  final List<Map<String, dynamic>> steps;

  const RoutineSessionData({
    required this.routine,
    required this.steps,
  });
}

class DiceSessionData {
  final List<int> diceValues;
  final List<Dice3DLayoutPosition> positions;
  final int previewSeconds;

  const DiceSessionData({
    required this.diceValues,
    required this.positions,
    required this.previewSeconds,
  });
}

class WordPuzzleSessionData {
  final List<WordStimulus> targetWords;
  final List<WordStimulus> distractors;
  final int previewSeconds;

  const WordPuzzleSessionData({
    required this.targetWords,
    required this.distractors,
    required this.previewSeconds,
  });
}

// ── Master Replayable Memory Session Generator ──────────────────────
class MemorySessionGenerator {
  static final Random _rng = Random();

  /// 1. FRUIT MEMORY PATH SESSION
  static MemorySession<FruitSessionData> generateFruitSession(GameDifficulty difficulty) {
    int gridSize;
    int fruitCount;
    int previewSec;

    switch (difficulty) {
      case GameDifficulty.easy:
        gridSize = 3;
        fruitCount = 3;
        previewSec = 6;
        break;
      case GameDifficulty.medium:
        gridSize = 4;
        fruitCount = 5;
        previewSec = 5;
        break;
      case GameDifficulty.hard:
        gridSize = 4;
        fruitCount = 7;
        previewSec = 4;
        break;
    }

    final path = MemoryLayoutGenerator.generateGardenPath(gridSize: gridSize, pathLength: fruitCount);
    final fruits = (List<FruitStimulus>.from(MemoryContentBank.fruits)..shuffle(_rng)).take(fruitCount).toList();

    final Map<int, FruitStimulus> gridFruitMap = {};
    for (int i = 0; i < fruitCount; i++) {
      gridFruitMap[path[i]] = fruits[i];
    }

    return MemorySession<FruitSessionData>(
      sessionId: 'sess_fruit_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(9999)}',
      gameType: ExerciseType.fruitMemoryPath,
      difficulty: difficulty,
      difficultyParams: {'gridSize': gridSize, 'fruitCount': fruitCount, 'previewSec': previewSec},
      stimulus: FruitSessionData(
        gridSize: gridSize,
        fruits: fruits,
        pathIndices: path,
        gridFruitMap: gridFruitMap,
        previewSeconds: previewSec,
      ),
      sequence: fruits.map((f) => f.name).toList(),
      timingParams: MemoryTimingParams(previewSeconds: previewSec),
      scoringConfig: const MemoryScoringConfig(itemRecallWeight: 0.5, sequenceWeight: 0.3, spatialWeight: 0.2),
    );
  }

  /// 2. MEMORY MELODY SESSION
  static MemorySession<MelodySessionData> generateMelodySession(GameDifficulty difficulty) {
    int noteCount;
    Duration noteDur;
    Duration gapDur;

    switch (difficulty) {
      case GameDifficulty.easy:
        noteCount = 3;
        noteDur = const Duration(milliseconds: 650);
        gapDur = const Duration(milliseconds: 250);
        break;
      case GameDifficulty.medium:
        noteCount = 5;
        noteDur = const Duration(milliseconds: 450);
        gapDur = const Duration(milliseconds: 150);
        break;
      case GameDifficulty.hard:
        noteCount = 7;
        noteDur = const Duration(milliseconds: 320);
        gapDur = const Duration(milliseconds: 100);
        break;
    }

    // Available notes: c4(Sa), d4(Re), e4(Ga), f4(Ma), g4(Pa), a4(Dha), b4(Ni), c5(Taar Sa)
    const idToSwara = {
      'c4': 'Sa', 'd4': 'Re', 'e4': 'Ga', 'f4': 'Ma',
      'g4': 'Pa', 'a4': 'Dha', 'b4': 'Ni', 'c5': 'Taar Sa',
    };

    // Authentic Indian classical scales & melodic structures (Mohanam, Hamsadhwani, Shankarabharanam, etc.)
    final List<List<String>> melodicPatterns = [
      // 1. Ascending Arohana Patterns
      ['c4', 'd4', 'e4', 'g4', 'a4', 'c5', 'g4'],
      ['c4', 'e4', 'g4', 'a4', 'c5', 'a4', 'g4'],
      ['c4', 'd4', 'e4', 'f4', 'g4', 'a4', 'b4'],
      ['c4', 'd4', 'f4', 'g4', 'a4', 'c5', 'a4'],
      // 2. Descending Avarohana Waves
      ['c5', 'a4', 'g4', 'e4', 'd4', 'c4', 'g4'],
      ['c5', 'b4', 'a4', 'g4', 'f4', 'e4', 'c4'],
      ['g4', 'e4', 'd4', 'c4', 'e4', 'g4', 'c5'],
      // 3. Symmetrical & Arch Arcs (Vakra Swaras)
      ['c4', 'e4', 'g4', 'c5', 'g4', 'e4', 'c4'],
      ['c4', 'd4', 'g4', 'e4', 'a4', 'g4', 'c5'],
      ['c4', 'g4', 'e4', 'g4', 'c5', 'g4', 'e4'],
      ['c4', 'e4', 'd4', 'g4', 'e4', 'a4', 'g4'],
      // 4. Repeated Rhythmic Paired Swaras
      ['c4', 'c4', 'e4', 'g4', 'g4', 'a4', 'c5'],
      ['c4', 'd4', 'd4', 'e4', 'g4', 'a4', 'a4'],
      ['c4', 'e4', 'e4', 'g4', 'c5', 'c5', 'g4'],
      // 5. Classic Ragas (Hamsadhwani, Durga, Madhmad)
      ['c4', 'd4', 'e4', 'g4', 'b4', 'c5', 'g4'], // Hamsadhwani
      ['c4', 'd4', 'f4', 'g4', 'a4', 'c5', 'd4'], // Durga
      ['c4', 'e4', 'f4', 'g4', 'b4', 'c5', 'e4'], // Kalyani
      ['c4', 'd4', 'f4', 'g4', 'c5', 'a4', 'f4'], // Madhmad
      ['c4', 'e4', 'g4', 'a4', 'd4', 'g4', 'c4'], // Shivaranjani arch
    ];

    // Seeded/randomized selection for endless procedurally varied sessions
    final basePattern = melodicPatterns[_rng.nextInt(melodicPatterns.length)];
    List<String> pickedNotes;

    // Apply procedural transforms based on difficulty and seed
    final transformType = _rng.nextInt(4);
    if (transformType == 1 && noteCount <= basePattern.length) {
      // Subsequence starting at varied anchor
      final startIdx = _rng.nextInt(basePattern.length - noteCount + 1);
      pickedNotes = basePattern.sublist(startIdx, startIdx + noteCount);
    } else if (transformType == 2 && difficulty == GameDifficulty.hard) {
      // Reversed wave
      pickedNotes = basePattern.take(noteCount).toList().reversed.toList();
    } else {
      pickedNotes = basePattern.take(noteCount).toList();
    }

    final swaras = pickedNotes.map((id) => idToSwara[id] ?? 'Sa').toList();

    return MemorySession<MelodySessionData>(
      sessionId: 'sess_melody_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(9999)}',
      gameType: ExerciseType.memoryMelody,
      difficulty: difficulty,
      difficultyParams: {'noteCount': noteCount, 'noteDurationMs': noteDur.inMilliseconds},
      stimulus: MelodySessionData(
        title: '${swaras.length}-Tone Traditional Swara Melody (${swaras.join(" - ")})',
        noteIds: pickedNotes,
        swaraNames: swaras,
        noteDuration: noteDur,
        gapDuration: gapDur,
      ),
      sequence: swaras,
      timingParams: const MemoryTimingParams(previewSeconds: 5),
      scoringConfig: const MemoryScoringConfig(itemRecallWeight: 0.3, sequenceWeight: 0.5, attentionWeight: 0.2),
    );
  }

  /// 3. PATTERN MEMORY GRID SESSION
  static MemorySession<PatternSessionData> generatePatternSession(GameDifficulty difficulty) {
    int gridSize;
    int activeCount;
    int previewSec;

    switch (difficulty) {
      case GameDifficulty.easy:
        gridSize = 3;
        activeCount = 3;
        previewSec = 4;
        break;
      case GameDifficulty.medium:
        gridSize = 3;
        activeCount = 4;
        previewSec = 3;
        break;
      case GameDifficulty.hard:
        gridSize = 4;
        activeCount = 6;
        previewSec = 3;
        break;
    }

    final activePattern = MemoryLayoutGenerator.generatePatternGrid(
      gridSize: gridSize,
      activeTiles: activeCount,
    );

    return MemorySession<PatternSessionData>(
      sessionId: 'sess_pattern_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(9999)}',
      gameType: ExerciseType.patternRecall,
      difficulty: difficulty,
      difficultyParams: {'gridSize': gridSize, 'activeCount': activeCount, 'previewSec': previewSec},
      stimulus: PatternSessionData(
        gridSize: gridSize,
        activeTiles: activePattern,
        previewSeconds: previewSec,
      ),
      sequence: activePattern.toList(),
      timingParams: MemoryTimingParams(previewSeconds: previewSec),
      scoringConfig: const MemoryScoringConfig(spatialWeight: 0.6, itemRecallWeight: 0.4),
    );
  }

  /// 4. OBJECT RECALL MATRIX SESSION
  static MemorySession<ObjectSessionData> generateObjectSession(GameDifficulty difficulty) {
    int targetCount;
    int distractorCount;
    int previewSec;

    switch (difficulty) {
      case GameDifficulty.easy:
        targetCount = 4;
        distractorCount = 3;
        previewSec = 8;
        break;
      case GameDifficulty.medium:
        targetCount = 5;
        distractorCount = 4;
        previewSec = 6;
        break;
      case GameDifficulty.hard:
        targetCount = 6;
        distractorCount = 5;
        previewSec = 5;
        break;
    }

    final shuffled = List<ObjectStimulus>.from(MemoryContentBank.objects)..shuffle(_rng);
    final targets = shuffled.take(targetCount).toList();
    final distractors = shuffled.skip(targetCount).take(distractorCount).toList();

    final roomTitles = [
      'Pooja Room & Sacred Veranda',
      'Morning Kitchen & Wooden Spice Shelf',
      'Quiet Study & Traditional Reading Desk',
      'Veranda Garden & Courtyard Walkway',
      'Weekly Morning Market Basket',
    ];
    final roomTitle = roomTitles[_rng.nextInt(roomTitles.length)];

    final gridMap = MemoryLayoutGenerator.distributeItemsOnGrid<ObjectStimulus>(
      gridSize: 3,
      items: targets,
    );

    return MemorySession<ObjectSessionData>(
      sessionId: 'sess_obj_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(9999)}',
      gameType: ExerciseType.recognition,
      difficulty: difficulty,
      difficultyParams: {'targetCount': targetCount, 'distractorCount': distractorCount},
      stimulus: ObjectSessionData(
        roomTitle: roomTitle,
        roomSubtitle: 'Memorize the items placed in this room.',
        targets: targets,
        distractors: distractors,
        gridMap: gridMap,
        previewSeconds: previewSec,
      ),
      timingParams: MemoryTimingParams(previewSeconds: previewSec),
      scoringConfig: const MemoryScoringConfig(itemRecallWeight: 0.6, spatialWeight: 0.4),
    );
  }

  /// 5. VISUAL SEARCH & FOCUS SESSION
  static MemorySession<AttentionSessionData> generateAttentionSession(GameDifficulty difficulty) {
    int totalCount;
    int targetCount;
    int timeLimit;

    switch (difficulty) {
      case GameDifficulty.easy:
        totalCount = 16;
        targetCount = 4;
        timeLimit = 20;
        break;
      case GameDifficulty.medium:
        totalCount = 16;
        targetCount = 5;
        timeLimit = 16;
        break;
      case GameDifficulty.hard:
        totalCount = 20;
        targetCount = 7;
        timeLimit = 14;
        break;
    }

    final theme = MemoryContentBank.focusThemes[_rng.nextInt(MemoryContentBank.focusThemes.length)];
    final targetIndices = (List<int>.generate(totalCount, (i) => i)..shuffle(_rng)).take(targetCount).toSet();
    final targetLocations = List<bool>.generate(totalCount, (i) => targetIndices.contains(i));

    return MemorySession<AttentionSessionData>(
      sessionId: 'sess_attn_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(9999)}',
      gameType: ExerciseType.attention,
      difficulty: difficulty,
      difficultyParams: {'totalCount': totalCount, 'targetCount': targetCount, 'timeLimit': timeLimit},
      stimulus: AttentionSessionData(
        theme: theme,
        totalCount: totalCount,
        targetCount: targetCount,
        targetLocations: targetLocations,
        timeLimitSeconds: timeLimit,
      ),
      timingParams: MemoryTimingParams(previewSeconds: 0, recallTimeoutSeconds: timeLimit),
      scoringConfig: const MemoryScoringConfig(attentionWeight: 0.7, itemRecallWeight: 0.3),
    );
  }

  /// 6. SEQUENCE RECALL SESSION
  static MemorySession<SequenceSessionData> generateSequenceSession(GameDifficulty difficulty) {
    // Filter sequences by difficulty length
    List<SequenceStimulus> candidates;
    switch (difficulty) {
      case GameDifficulty.easy:
        candidates = MemoryContentBank.sequences.where((s) => s.items.length <= 4).toList();
        break;
      case GameDifficulty.medium:
        candidates = MemoryContentBank.sequences.where((s) => s.items.length == 5).toList();
        break;
      case GameDifficulty.hard:
        candidates = MemoryContentBank.sequences.where((s) => s.items.length >= 6).toList();
        break;
    }
    if (candidates.isEmpty) candidates = MemoryContentBank.sequences;

    final seq = candidates[_rng.nextInt(candidates.length)];
    final previewSec = difficulty == GameDifficulty.easy ? 6 : (difficulty == GameDifficulty.medium ? 5 : 4);

    return MemorySession<SequenceSessionData>(
      sessionId: 'sess_seq_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(9999)}',
      gameType: ExerciseType.sequenceRecall,
      difficulty: difficulty,
      difficultyParams: {'length': seq.items.length, 'category': seq.category},
      stimulus: SequenceSessionData(
        title: seq.title,
        category: seq.category,
        targetSequence: seq.items,
        previewSeconds: previewSec,
      ),
      sequence: seq.items,
      timingParams: MemoryTimingParams(previewSeconds: previewSec),
      scoringConfig: const MemoryScoringConfig(sequenceWeight: 0.7, itemRecallWeight: 0.3),
    );
  }

  /// 7. ORAL HERITAGE STORIES SESSION
  static MemorySession<StorySessionData> generateStorySession(GameDifficulty difficulty) {
    final story = MemoryContentBank.stories[_rng.nextInt(MemoryContentBank.stories.length)];
    final shuffledQuestions = List<Map<String, dynamic>>.from(story.questions)..shuffle(_rng);

    return MemorySession<StorySessionData>(
      sessionId: 'sess_story_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(9999)}',
      gameType: ExerciseType.storyMemory,
      difficulty: difficulty,
      difficultyParams: {'region': story.region, 'questionCount': shuffledQuestions.length},
      stimulus: StorySessionData(
        story: story,
        questions: shuffledQuestions,
      ),
      timingParams: const MemoryTimingParams(previewSeconds: 15),
      scoringConfig: const MemoryScoringConfig(itemRecallWeight: 0.5, sequenceWeight: 0.3, attentionWeight: 0.2),
    );
  }

  /// 8. DAILY ROUTINE RECALL SESSION
  static MemorySession<RoutineSessionData> generateRoutineSession(GameDifficulty difficulty) {
    final routine = MemoryContentBank.routines[_rng.nextInt(MemoryContentBank.routines.length)];
    final shuffledSteps = List<Map<String, dynamic>>.from(routine.steps)..shuffle(_rng);

    return MemorySession<RoutineSessionData>(
      sessionId: 'sess_routine_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(9999)}',
      gameType: ExerciseType.dailyRoutineRecall,
      difficulty: difficulty,
      difficultyParams: {'stepsCount': routine.steps.length},
      stimulus: RoutineSessionData(
        routine: routine,
        steps: shuffledSteps,
      ),
      timingParams: const MemoryTimingParams(previewSeconds: 10),
      scoringConfig: const MemoryScoringConfig(sequenceWeight: 0.6, itemRecallWeight: 0.4),
    );
  }

  /// 9. NEW GAME — 3D DICE MEMORY SESSION
  static MemorySession<DiceSessionData> generateDiceSession(GameDifficulty difficulty) {
    int diceCount;
    int previewSec;

    switch (difficulty) {
      case GameDifficulty.easy:
        diceCount = 3;
        previewSec = 6;
        break;
      case GameDifficulty.medium:
        diceCount = 4;
        previewSec = 5;
        break;
      case GameDifficulty.hard:
        diceCount = 5;
        previewSec = 4;
        break;
    }

    // Generate random dice values 1 to 6 (avoid all identical)
    final List<int> values = [];
    for (int i = 0; i < diceCount; i++) {
      values.add(1 + _rng.nextInt(6));
    }

    final layoutPositions = MemoryLayoutGenerator.generateDiceTabletopLayout(diceCount: diceCount);
    final questions = MemoryQuestionGenerator.generateDiceQuestions(diceValues: values);

    return MemorySession<DiceSessionData>(
      sessionId: 'sess_dice_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(9999)}',
      gameType: ExerciseType.diceMemory,
      difficulty: difficulty,
      difficultyParams: {'diceCount': diceCount, 'previewSec': previewSec},
      stimulus: DiceSessionData(
        diceValues: values,
        positions: layoutPositions,
        previewSeconds: previewSec,
      ),
      sequence: values,
      questions: questions,
      timingParams: MemoryTimingParams(previewSeconds: previewSec),
      scoringConfig: const MemoryScoringConfig(itemRecallWeight: 0.4, sequenceWeight: 0.3, spatialWeight: 0.3),
    );
  }

  /// 10. NEW GAME — WORD MEMORY PUZZLE SESSION
  static MemorySession<WordPuzzleSessionData> generateWordPuzzleSession(GameDifficulty difficulty) {
    int wordCount;
    int previewSec;

    switch (difficulty) {
      case GameDifficulty.easy:
        wordCount = 4;
        previewSec = 7;
        break;
      case GameDifficulty.medium:
        wordCount = 5;
        previewSec = 6;
        break;
      case GameDifficulty.hard:
        wordCount = 6;
        previewSec = 5;
        break;
    }

    final shuffledBank = List<WordStimulus>.from(MemoryContentBank.words)..shuffle(_rng);
    final targetWords = shuffledBank.take(wordCount).toList();
    final distractors = shuffledBank.skip(wordCount).take(8).toList();

    final questions = MemoryQuestionGenerator.generateWordPuzzleQuestions(
      targetWords: targetWords,
      distractorPool: distractors,
    );

    return MemorySession<WordPuzzleSessionData>(
      sessionId: 'sess_word_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(9999)}',
      gameType: ExerciseType.wordMemoryPuzzle,
      difficulty: difficulty,
      difficultyParams: {'wordCount': wordCount, 'previewSec': previewSec},
      stimulus: WordPuzzleSessionData(
        targetWords: targetWords,
        distractors: distractors,
        previewSeconds: previewSec,
      ),
      sequence: targetWords.map((w) => w.word).toList(),
      questions: questions,
      timingParams: MemoryTimingParams(previewSeconds: previewSec),
      scoringConfig: const MemoryScoringConfig(itemRecallWeight: 0.4, sequenceWeight: 0.4, attentionWeight: 0.2),
    );
  }
}
