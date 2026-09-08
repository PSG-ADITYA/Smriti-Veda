import '../services/session_engine/memory_session_generator.dart';
import '../models/game_difficulty.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_overlay.dart';

class SequenceRound {
  final int level;
  final String title;
  final List<String> targetSequence;
  final int previewSeconds;

  const SequenceRound({
    required this.level,
    required this.title,
    required this.targetSequence,
    required this.previewSeconds,
  });
}

class SequenceDifficultyConfig {
  final GameDifficulty difficulty;
  final String title;
  final List<String> targetSequence;
  final int previewSeconds;

  const SequenceDifficultyConfig({
    required this.difficulty,
    required this.title,
    required this.targetSequence,
    required this.previewSeconds,
  });
}

const Map<GameDifficulty, SequenceDifficultyConfig> kSequenceDifficultyConfigs = {
  GameDifficulty.easy: SequenceDifficultyConfig(
    difficulty: GameDifficulty.easy,
    title: 'Three Sacred Rivers',
    targetSequence: ['Ganga 🌊', 'Yamuna 🌿', 'Brahmaputra 🏔️'],
    previewSeconds: 6,
  ),
  GameDifficulty.medium: SequenceDifficultyConfig(
    difficulty: GameDifficulty.medium,
    title: 'Five Morning Routine Steps',
    targetSequence: ['Dawn 🌅', 'Prayer 🪔', 'Water 💧', 'Walk 🚶', 'Tea ☕'],
    previewSeconds: 5,
  ),
  GameDifficulty.hard: SequenceDifficultyConfig(
    difficulty: GameDifficulty.hard,
    title: 'Six Memory Digits',
    targetSequence: ['7️⃣', '2️⃣', '9️⃣', '4️⃣', '1️⃣', '8️⃣'],
    previewSeconds: 5,
  ),
};

enum SequencePhase {
  preview,
  recall,
  summary,
}

class SequenceRecallScreen extends StatefulWidget {
  const SequenceRecallScreen({super.key});

  @override
  State<SequenceRecallScreen> createState() => _SequenceRecallScreenState();
}

class _SequenceRecallScreenState extends State<SequenceRecallScreen> {
  GameDifficulty _difficulty = GameDifficulty.easy;
  SequencePhase _phase = SequencePhase.preview;

  late List<String> _shuffledPool;
  final List<String> _userSequence = [];
  final Stopwatch _stopwatch = Stopwatch();
  double _scorePct = 0.0;
  int _cumulativeScore = 0;


  @override
  void initState() {
    super.initState();
    _initRound();
  }

  late List<String> _currentTargetSequence;
  String _currentSequenceTitle = '';

  void _initRound() {
    _phase = SequencePhase.preview;
    _userSequence.clear();
    final session = MemorySessionGenerator.generateSequenceSession(_difficulty);
    _currentTargetSequence = session.stimulus.targetSequence;
    _currentSequenceTitle = session.stimulus.title;
    _shuffledPool = List.from(_currentTargetSequence)..shuffle();
    _stopwatch.reset();
    _stopwatch.start();
    setState(() {});
  }

  void _startRecall() {
    SoundService.playTap();
    setState(() {
      _phase = SequencePhase.recall;
      _userSequence.clear();
    });
    SoundService.speak('Now assemble the sequence in the exact order you saw.');
  }

  void _addItem(String item) {
    if (_phase != SequencePhase.recall) return;
    if (_userSequence.length >= _currentTargetSequence.length) return;

    SoundService.playTap();
    setState(() {
      _userSequence.add(item);
    });
  }

  void _removeItem(int index) {
    if (_phase != SequencePhase.recall) return;
    SoundService.playTap();
    setState(() {
      _userSequence.removeAt(index);
    });
  }

  Future<void> _submit(AppState appState) async {
    _stopwatch.stop();

    int correctPositions = 0;
    for (int i = 0; i < _userSequence.length; i++) {
      if (i < _currentTargetSequence.length && _userSequence[i] == _currentTargetSequence[i]) {
        correctPositions++;
      }
    }

    final total = _currentTargetSequence.length;
    _scorePct = (correctPositions / total * 100.0);
    _cumulativeScore += _scorePct.toInt();

    setState(() {
      _phase = SequencePhase.summary;
    });

    if (_scorePct >= 70.0) {
      SoundService.playFanfare();
      if (mounted && _difficulty == GameDifficulty.hard) {
        ConfettiOverlay.show(
          context,
          title: 'Sequential Mastery! 🌟',
          subtitle: 'Completed Hard sequence with precision chaining!',
        );
      }
    } else {
      SoundService.playError();
    }

    // Log attempt into repository
    await appState.attemptRepository.logAttempt(
      ExerciseAttempt(
        id: 'att_seq_${DateTime.now().millisecondsSinceEpoch}',
        userId: appState.credentialId,
        domain: ExerciseDomain.universalCognitive,
        cognitiveDomain: CognitiveDomain.sequentialMemory,
        type: ExerciseType.sequenceRecall,
        exerciseId: 'sequence_recall_${_difficulty.name}',
        responseMode: 'choice',
        rawScore: correctPositions.toDouble(),
        maxScore: total.toDouble(),
        timeTakenMs: _stopwatch.elapsedMilliseconds,
      ),
    );
  }

  void _nextRoundOrReset() {
    if (_difficulty == GameDifficulty.easy) {
      _difficulty = GameDifficulty.medium;
    } else if (_difficulty == GameDifficulty.medium) {
      _difficulty = GameDifficulty.hard;
    }
    _initRound();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final fontScale = appState.fontScale;

    return Scaffold(
      backgroundColor: AppColors.canvasIvory,
      appBar: AppBar(
        backgroundColor: AppColors.canvasIvory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoalText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sequence Recall',
          style: GoogleFonts.newsreader(
            fontSize: 20 * fontScale,
            fontWeight: FontWeight.bold,
            color: AppColors.terracottaPrimary,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.sageSecondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.format_list_numbered_rounded, size: 16, color: AppColors.sageSecondary),
                const SizedBox(width: 4),
                Text(
                  'Sequential Memory',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoalText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.4)),
                  boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_difficulty.label.toUpperCase()} DIFFICULTY',
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 11 * fontScale,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: AppColors.terracottaPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentSequenceTitle,
                            style: GoogleFonts.newsreader(
                              fontSize: 17 * fontScale,
                              fontWeight: FontWeight.bold,
                              color: AppColors.charcoalText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.sageSecondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Score: $_cumulativeScore',
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 14 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sageSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Phase 1: Preview Sequence
              if (_phase == SequencePhase.preview) ...[
                Text(
                  'MEMORIZE THIS EXACT SEQUENCE FROM LEFT TO RIGHT:',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.charcoalText,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.terracottaPrimary.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: List.generate(_currentTargetSequence.length, (idx) {
                      final item = _currentTargetSequence[idx];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.terracottaPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.terracottaPrimary),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.terracottaPrimary,
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                item,
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 16 * fontScale,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.charcoalText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _startRecall,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 22),
                  label: Text(
                    'I Remember The Order ➔ Start Recall',
                    style: GoogleFonts.atkinsonHyperlegible(fontSize: 16 * fontScale, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracottaPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],

              // Phase 2: Recall & Summary
              if (_phase == SequencePhase.recall || _phase == SequencePhase.summary) ...[
                Text(
                  'YOUR ASSEMBLED SEQUENCE (${_userSequence.length} of ${_currentTargetSequence.length}):',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.charcoalText,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  constraints: const BoxConstraints(minHeight: 80),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.sandalwoodGold),
                  ),
                  child: _userSequence.isEmpty
                      ? Center(
                          child: Text(
                            'Tap the items below in the correct order',
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 13 * fontScale,
                              fontStyle: FontStyle.italic,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate(_userSequence.length, (idx) {
                            final item = _userSequence[idx];
                            final isSummary = _phase == SequencePhase.summary;
                            final isCorrect = isSummary && _currentTargetSequence[idx] == item;
                            final isWrong = isSummary && _currentTargetSequence[idx] != item;

                            return GestureDetector(
                              onTap: isSummary ? null : () => _removeItem(idx),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isCorrect
                                      ? AppColors.sageSecondary.withValues(alpha: 0.15)
                                      : isWrong
                                          ? AppColors.terracottaPrimary.withValues(alpha: 0.15)
                                          : AppColors.canvasIvory,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCorrect
                                        ? AppColors.sageSecondary
                                        : isWrong
                                            ? AppColors.terracottaPrimary
                                            : AppColors.terracottaPrimary,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 11,
                                      backgroundColor: AppColors.terracottaPrimary,
                                      child: Text(
                                        '${idx + 1}',
                                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item,
                                      style: GoogleFonts.atkinsonHyperlegible(
                                        fontSize: 15 * fontScale,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.charcoalText,
                                      ),
                                    ),
                                    if (!isSummary) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.close, size: 16, color: Colors.black45),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                ),
                const SizedBox(height: 18),

                if (_phase == SequencePhase.recall) ...[
                  Text(
                    'AVAILABLE ITEMS (TAP TO ADD):',
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 12 * fontScale,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.charcoalText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _shuffledPool.map((item) {
                      final isSelected = _userSequence.contains(item);
                      return GestureDetector(
                        onTap: isSelected ? null : () => _addItem(item),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isSelected ? 0.3 : 1.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Text(
                              item,
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 14 * fontScale,
                                fontWeight: FontWeight.bold,
                                color: AppColors.charcoalText,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _userSequence.length == _currentTargetSequence.length
                        ? () => _submit(appState)
                        : null,
                    icon: const Icon(Icons.check_circle_outline, size: 22),
                    label: Text(
                      'Check Sequence Order',
                      style: GoogleFonts.atkinsonHyperlegible(fontSize: 16 * fontScale, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sageSecondary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.sandalwoodGold),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Score: ${_scorePct.toInt()}%',
                          style: GoogleFonts.newsreader(
                            fontSize: 22 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: AppColors.terracottaPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sequential recall precision has been logged into your profile.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.atkinsonHyperlegible(fontSize: 13 * fontScale, color: AppColors.secondaryText),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: _nextRoundOrReset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.terracottaPrimary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            _difficulty != GameDifficulty.hard ? 'Next Difficulty ➔' : 'Play Again',
                            style: GoogleFonts.atkinsonHyperlegible(fontSize: 15 * fontScale, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
