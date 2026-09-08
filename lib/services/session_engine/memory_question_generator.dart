import 'dart:math';
import 'memory_session.dart';
import 'memory_content_bank.dart';

class MemoryQuestionGenerator {
  static final Random _rng = Random();

  /// Generates deterministic questions for 3D Dice Memory session.
  static List<MemoryRecallQuestion> generateDiceQuestions({
    required List<int> diceValues,
  }) {
    final List<MemoryRecallQuestion> questions = [];
    final count = diceValues.length;
    if (count < 2) return questions;

    // Helper to generate 4 distinct choices including correct
    List<String> makeOptions(String correct, List<String> pool) {
      final set = <String>{correct};
      final shuffledPool = List<String>.from(pool)..shuffle(_rng);
      for (final item in shuffledPool) {
        if (set.length >= 4) break;
        set.add(item);
      }
      // If pool didn't have enough
      int fallbackNum = 1;
      while (set.length < 4 && fallbackNum <= 6) {
        set.add('$fallbackNum');
        fallbackNum++;
      }
      final list = set.toList()..shuffle(_rng);
      return list;
    }

    // Question 1: Position-specific value
    if (count == 3) {
      // Middle die
      final correctVal = diceValues[1].toString();
      final opts = makeOptions(correctVal, ['1', '2', '3', '4', '5', '6']);
      questions.add(MemoryRecallQuestion(
        id: 'dice_mid',
        prompt: 'What number was on the middle die?',
        type: QuestionType.singleChoice,
        options: opts,
        correctIndex: opts.indexOf(correctVal),
        correctAnswerText: correctVal,
        metadata: {'targetPosition': 1},
      ));
    } else {
      // First or last die
      final askFirst = _rng.nextBool();
      final targetIdx = askFirst ? 0 : count - 1;
      final label = askFirst ? 'first (leftmost)' : 'last (rightmost)';
      final correctVal = diceValues[targetIdx].toString();
      final opts = makeOptions(correctVal, ['1', '2', '3', '4', '5', '6']);
      questions.add(MemoryRecallQuestion(
        id: 'dice_pos_$targetIdx',
        prompt: 'What number was on the $label die?',
        type: QuestionType.singleChoice,
        options: opts,
        correctIndex: opts.indexOf(correctVal),
        correctAnswerText: correctVal,
        metadata: {'targetPosition': targetIdx},
      ));
    }

    // Question 2: Which die showed value X?
    final chosenIdx = _rng.nextInt(count);
    final chosenVal = diceValues[chosenIdx];
    // Position labels
    final positionLabels = <String>[];
    for (int i = 0; i < count; i++) {
      if (i == 0) {
        positionLabels.add('Left die');
      } else if (i == count - 1) {
        positionLabels.add('Right die');
      } else {
        positionLabels.add('Die #${i + 1}');
      }
    }
    final correctPositionLabel = positionLabels[chosenIdx];
    final posOptions = List<String>.from(positionLabels)..shuffle(_rng);
    questions.add(MemoryRecallQuestion(
      id: 'dice_val_to_pos',
      prompt: 'Which die showed the number $chosenVal?',
      type: QuestionType.spatialPosition,
      options: posOptions,
      correctIndex: posOptions.indexOf(correctPositionLabel),
      correctAnswerText: correctPositionLabel,
      metadata: {'value': chosenVal, 'positionIndex': chosenIdx},
    ));

    // Question 3: Between two dice (if 3 or more dice)
    if (count >= 3) {
      final leftVal = diceValues[0];
      final rightVal = diceValues[count - 1];
      final betweenVal = diceValues[1].toString();
      final opts = makeOptions(betweenVal, ['1', '2', '3', '4', '5', '6']);
      questions.add(MemoryRecallQuestion(
        id: 'dice_between',
        prompt: 'What number was between die #1 ($leftVal) and die #$count ($rightVal)?',
        type: QuestionType.singleChoice,
        options: opts,
        correctIndex: opts.indexOf(betweenVal),
        correctAnswerText: betweenVal,
      ));
    }

    // Question 4: Full left-to-right order
    final correctOrderStr = diceValues.join(' - ');
    final orderSet = <String>{correctOrderStr};
    for (int i = 0; i < 6; i++) {
      if (orderSet.length >= 4) break;
      final shuffled = List<int>.from(diceValues)..shuffle(_rng);
      orderSet.add(shuffled.join(' - '));
    }
    while (orderSet.length < 4) {
      final fake = List<int>.generate(count, (_) => 1 + _rng.nextInt(6));
      orderSet.add(fake.join(' - '));
    }
    final orderOpts = orderSet.toList()..shuffle(_rng);
    questions.add(MemoryRecallQuestion(
      id: 'dice_full_order',
      prompt: 'What was the exact order of the numbers from left to right?',
      type: QuestionType.ordering,
      options: orderOpts,
      correctIndex: orderOpts.indexOf(correctOrderStr),
      correctAnswerText: correctOrderStr,
      targetOrder: diceValues.map((v) => v.toString()).toList(),
    ));

    return questions;
  }

  /// Generates deterministic questions for Word Memory Puzzle session.
  static List<MemoryRecallQuestion> generateWordPuzzleQuestions({
    required List<WordStimulus> targetWords,
    required List<WordStimulus> distractorPool,
  }) {
    final List<MemoryRecallQuestion> questions = [];
    final wordStrings = targetWords.map((w) => w.word).toList();
    if (wordStrings.isEmpty) return questions;

    List<String> makeWordOptions(String correct) {
      final set = <String>{correct};
      final pool = distractorPool.map((d) => d.word).where((w) => !wordStrings.contains(w)).toList()..shuffle(_rng);
      for (final w in pool) {
        if (set.length >= 4) break;
        set.add(w);
      }
      return set.toList()..shuffle(_rng);
    }

    // 1. Presence question: Which word was in the list?
    final presentTarget = wordStrings[_rng.nextInt(wordStrings.length)];
    final q1Options = makeWordOptions(presentTarget);
    questions.add(MemoryRecallQuestion(
      id: 'word_seen',
      prompt: 'Which of these words was shown in your memory card set?',
      type: QuestionType.singleChoice,
      options: q1Options,
      correctIndex: q1Options.indexOf(presentTarget),
      correctAnswerText: presentTarget,
    ));

    // 2. Sequential question: What came after X?
    if (wordStrings.length >= 3) {
      final idx = _rng.nextInt(wordStrings.length - 1); // Not the last one
      final anchorWord = wordStrings[idx];
      final afterWord = wordStrings[idx + 1];
      final otherChoices = List<String>.from(wordStrings)..remove(anchorWord);
      final set = <String>{afterWord};
      for (final w in otherChoices..shuffle(_rng)) {
        if (set.length >= 4) break;
        set.add(w);
      }
      final opts = set.toList()..shuffle(_rng);
      questions.add(MemoryRecallQuestion(
        id: 'word_after',
        prompt: 'What word came immediately after "$anchorWord"?',
        type: QuestionType.singleChoice,
        options: opts,
        correctIndex: opts.indexOf(afterWord),
        correctAnswerText: afterWord,
      ));
    }

    // 3. First word question
    final firstWord = wordStrings.first;
    final otherFirstChoices = List<String>.from(wordStrings);
    final firstOpts = (otherFirstChoices.take(4).toList())..shuffle(_rng);
    if (!firstOpts.contains(firstWord)) firstOpts[0] = firstWord;
    firstOpts.shuffle(_rng);
    questions.add(MemoryRecallQuestion(
      id: 'word_first',
      prompt: 'What was the very first word in the sequence?',
      type: QuestionType.singleChoice,
      options: firstOpts,
      correctIndex: firstOpts.indexOf(firstWord),
      correctAnswerText: firstWord,
    ));

    // 4. Missing word question
    if (wordStrings.length >= 4) {
      final missingIdx = 1 + _rng.nextInt(wordStrings.length - 2); // interior item
      final missingWord = wordStrings[missingIdx];
      final sequenceWithBlank = List<String>.from(wordStrings);
      sequenceWithBlank[missingIdx] = '____';
      final qOpts = makeWordOptions(missingWord);
      questions.add(MemoryRecallQuestion(
        id: 'word_missing',
        prompt: 'Which word belongs in the blank?\n${sequenceWithBlank.join(" ➔ ")}',
        type: QuestionType.missingElement,
        options: qOpts,
        correctIndex: qOpts.indexOf(missingWord),
        correctAnswerText: missingWord,
      ));
    }

    // 5. Arrange in original order question
    questions.add(MemoryRecallQuestion(
      id: 'word_reorder',
      prompt: 'Arrange the words in their original sequence:',
      type: QuestionType.ordering,
      options: List<String>.from(wordStrings)..shuffle(_rng),
      correctIndex: 0,
      correctAnswerText: wordStrings.join(', '),
      targetOrder: wordStrings,
    ));

    return questions;
  }
}
