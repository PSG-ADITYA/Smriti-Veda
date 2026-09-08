import '../models/game_difficulty.dart';
import '../services/session_engine/memory_session_generator.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_overlay.dart';

class AttentionTheme {
  final String title;
  final String targetName;
  final String targetEmoji;
  final String distractorName;
  final String distractorEmoji;
  final int totalCount;
  final int targetCount;
  final int timeLimitSeconds;

  const AttentionTheme({
    required this.title,
    required this.targetName,
    required this.targetEmoji,
    required this.distractorName,
    required this.distractorEmoji,
    required this.totalCount,
    required this.targetCount,
    required this.timeLimitSeconds,
  });
}

const List<AttentionTheme> kAttentionRounds = [
  AttentionTheme(
    title: 'Morning Sky Focus',
    targetName: 'Golden Sun',
    targetEmoji: '☀️',
    distractorName: 'Rain Cloud',
    distractorEmoji: '☁️',
    totalCount: 16, // 4x4
    targetCount: 4,
    timeLimitSeconds: 20,
  ),
  AttentionTheme(
    title: 'Spring Garden Search',
    targetName: 'Green Sprout',
    targetEmoji: '🌱',
    distractorName: 'Dry Leaf',
    distractorEmoji: '🍂',
    totalCount: 16, // 4x4
    targetCount: 5,
    timeLimitSeconds: 18,
  ),
  AttentionTheme(
    title: 'Sacred River Bloom',
    targetName: 'Lotus Flower',
    targetEmoji: '🪷',
    distractorName: 'River Stone',
    distractorEmoji: '🪨',
    totalCount: 20, // 4x5
    targetCount: 6,
    timeLimitSeconds: 16,
  ),
  AttentionTheme(
    title: 'Forest Canopy Scan',
    targetName: 'Singing Bird',
    targetEmoji: '🐦',
    distractorName: 'Pine Cone',
    distractorEmoji: '🪵',
    totalCount: 20, // 4x5
    targetCount: 7,
    timeLimitSeconds: 15,
  ),
];

class AttentionExerciseScreen extends StatefulWidget {
  const AttentionExerciseScreen({super.key});

  @override
  State<AttentionExerciseScreen> createState() => _AttentionExerciseScreenState();
}

class _AttentionExerciseScreenState extends State<AttentionExerciseScreen> {
  int _roundIndex = 0;
  bool _isPlaying = false;
  bool _isFinished = false;

  late List<bool> _cellIsTarget;
  final Set<int> _selectedIndices = {};
  int _secondsLeft = 0;
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();

  int _cumulativeScore = 0;


  @override
  void initState() {
    super.initState();
    _setupRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  AttentionTheme? _dynamicRound;
  AttentionTheme get _activeTheme => _dynamicRound ?? kAttentionRounds.first;

  void _setupRound() {
    _timer?.cancel();
    final session = MemorySessionGenerator.generateAttentionSession(GameDifficulty.medium);
    _dynamicRound = AttentionTheme(
      title: session.stimulus.theme.title,
      targetName: session.stimulus.theme.targetName,
      targetEmoji: session.stimulus.theme.targetEmoji,
      distractorName: session.stimulus.theme.distractorName,
      distractorEmoji: session.stimulus.theme.distractorEmoji,
      totalCount: session.stimulus.totalCount,
      targetCount: session.stimulus.targetCount,
      timeLimitSeconds: session.stimulus.timeLimitSeconds,
    );
    _secondsLeft = _activeTheme.timeLimitSeconds;
    _isPlaying = false;
    _isFinished = false;
    _selectedIndices.clear();
    _cellIsTarget = session.stimulus.targetLocations;
    setState(() {});
  }

  void _startRound() {
    SoundService.playTap();
    setState(() {
      _isPlaying = true;
      _isFinished = false;
      _selectedIndices.clear();
      _stopwatch.reset();
      _stopwatch.start();
    });

    SoundService.speak('Find and tap all ${_activeTheme.targetCount} ${_activeTheme.targetName}s.');

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        t.cancel();
        _finishRound(AppStateScope.of(context));
      }
    });
  }

  void _tapCell(int index) {
    if (!_isPlaying || _isFinished) return;

    final isTarget = _cellIsTarget[index];
    if (isTarget) {
      SoundService.playTap();
    } else {
      SoundService.playError();
    }

    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });

    // Check if user found all targets
    int targetsFound = 0;
    for (final idx in _selectedIndices) {
      if (_cellIsTarget[idx]) targetsFound++;
    }
    if (targetsFound >= _activeTheme.targetCount) {
      _timer?.cancel();
      _finishRound(AppStateScope.of(context));
    }
  }

  Future<void> _finishRound(AppState appState) async {
    _stopwatch.stop();
    _timer?.cancel();

    int correct = 0;
    int falseClicks = 0;

    for (final idx in _selectedIndices) {
      if (_cellIsTarget[idx]) {
        correct++;
      } else {
        falseClicks++;
      }
    }

    final double rawScore = (correct - falseClicks).clamp(0, _activeTheme.targetCount).toDouble();
    final double maxScore = _activeTheme.targetCount.toDouble();
    final double pct = (rawScore / maxScore) * 100.0;
    _cumulativeScore += pct.toInt();

    setState(() {
      _isPlaying = false;
      _isFinished = true;
    });

    if (pct >= 60.0) {
      SoundService.playFanfare();
      if (mounted && _roundIndex == kAttentionRounds.length - 1) {
        ConfettiOverlay.show(
          context,
          title: 'Master of Focus! 🎯',
          subtitle: 'Completed all attention rounds with stellar concentration!',
        );
      }
    } else {
      SoundService.playError();
    }

    // Log attempt into repository
    await appState.attemptRepository.logAttempt(
      ExerciseAttempt(
        id: 'att_att_${DateTime.now().millisecondsSinceEpoch}',
        userId: appState.credentialId,
        domain: ExerciseDomain.universalCognitive,
        cognitiveDomain: CognitiveDomain.attentionFocus,
        type: ExerciseType.attention,
        exerciseId: 'attention_focus_round_${_roundIndex + 1}',
        responseMode: 'visual_tap',
        rawScore: rawScore,
        maxScore: maxScore,
        timeTakenMs: _stopwatch.elapsedMilliseconds,
      ),
    );
  }

  void _nextRoundOrReset() {
    if (_roundIndex < kAttentionRounds.length - 1) {
      _roundIndex++;
    } else {
      _roundIndex = 0;
      _cumulativeScore = 0;
    }
    _setupRound();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final fontScale = appState.fontScale;

    int correctSelected = 0;
    for (final idx in _selectedIndices) {
      if (_cellIsTarget[idx]) correctSelected++;
    }

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
          'Attention & Focus Challenge',
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
              color: AppColors.sandalwoodGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.center_focus_strong_rounded, size: 16, color: AppColors.sandalwoodGold),
                const SizedBox(width: 4),
                Text(
                  'Attention & Focus',
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
              // Round Header Card
              Container(
                padding: const EdgeInsets.all(14),
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
                          Text(
                            'ROUND ${_roundIndex + 1} OF ${kAttentionRounds.length}',
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 11 * fontScale,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: AppColors.terracottaPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _activeTheme.title,
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
                    if (_isPlaying)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _secondsLeft <= 5 ? AppColors.terracottaPrimary : AppColors.sageSecondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${_secondsLeft}s',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.sandalwoodGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Score: $_cumulativeScore',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 14 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoalText,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Target Prompt Ribbon
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.canvasIvory,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Text(_activeTheme.targetEmoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Find all ${_activeTheme.targetCount} ${_activeTheme.targetName}s ($correctSelected found)',
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 14 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoalText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Attention Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activeTheme.totalCount,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final isTarget = _cellIsTarget[index];
                  final isSelected = _selectedIndices.contains(index);

                  Color bg = Colors.white;
                  Border border = Border.all(color: Colors.black12);

                  if (_isPlaying && isSelected) {
                    bg = isTarget
                        ? AppColors.sageSecondary.withValues(alpha: 0.2)
                        : AppColors.terracottaPrimary.withValues(alpha: 0.2);
                    border = Border.all(
                      color: isTarget ? AppColors.sageSecondary : AppColors.terracottaPrimary,
                      width: 2,
                    );
                  }

                  if (_isFinished) {
                    if (isTarget && isSelected) {
                      bg = AppColors.sageSecondary.withValues(alpha: 0.25);
                      border = Border.all(color: AppColors.sageSecondary, width: 2);
                    } else if (!isTarget && isSelected) {
                      bg = AppColors.terracottaPrimary.withValues(alpha: 0.25);
                      border = Border.all(color: AppColors.terracottaPrimary, width: 2);
                    } else if (isTarget && !isSelected) {
                      bg = AppColors.sandalwoodGold.withValues(alpha: 0.25);
                      border = Border.all(color: AppColors.sandalwoodGold, width: 2);
                    }
                  }

                  return GestureDetector(
                    onTap: () => _tapCell(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(14),
                        border: border,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          isTarget ? _activeTheme.targetEmoji : _activeTheme.distractorEmoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Controls
              if (!_isPlaying && !_isFinished)
                ElevatedButton.icon(
                  onPressed: _startRound,
                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                  label: Text(
                    'Start Round (${_activeTheme.timeLimitSeconds}s Timer)',
                    style: GoogleFonts.atkinsonHyperlegible(fontSize: 16 * fontScale, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracottaPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                )
              else if (_isPlaying)
                OutlinedButton.icon(
                  onPressed: () => _finishRound(appState),
                  icon: const Icon(Icons.done_all_rounded),
                  label: Text(
                    'Done / Finish Now ($correctSelected of ${_activeTheme.targetCount})',
                    style: GoogleFonts.atkinsonHyperlegible(fontSize: 15 * fontScale, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              else if (_isFinished)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.sageSecondary),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Round Complete!',
                        style: GoogleFonts.newsreader(
                          fontSize: 20 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoalText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Found $correctSelected of ${_activeTheme.targetCount} targets accurately.',
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
                          _roundIndex < kAttentionRounds.length - 1 ? 'Proceed to Next Round' : 'Play Again',
                          style: GoogleFonts.atkinsonHyperlegible(fontSize: 15 * fontScale, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
