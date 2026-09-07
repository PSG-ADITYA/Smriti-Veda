import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_overlay.dart';

enum PatternPhase {
  ready,
  preview,
  recall,
  roundSummary,
}

class PatternLevelConfig {
  final int level;
  final int gridSize;
  final int activeTiles;
  final int previewSeconds;

  const PatternLevelConfig({
    required this.level,
    required this.gridSize,
    required this.activeTiles,
    required this.previewSeconds,
  });
}

class PatternMemoryScreen extends StatefulWidget {
  const PatternMemoryScreen({super.key});

  @override
  State<PatternMemoryScreen> createState() => _PatternMemoryScreenState();
}

class _PatternMemoryScreenState extends State<PatternMemoryScreen> {
  final List<PatternLevelConfig> _levels = const [
    PatternLevelConfig(level: 1, gridSize: 3, activeTiles: 3, previewSeconds: 4),
    PatternLevelConfig(level: 2, gridSize: 3, activeTiles: 4, previewSeconds: 3),
    PatternLevelConfig(level: 3, gridSize: 4, activeTiles: 5, previewSeconds: 4),
    PatternLevelConfig(level: 4, gridSize: 4, activeTiles: 6, previewSeconds: 3),
  ];

  int _levelIndex = 0;
  PatternPhase _phase = PatternPhase.ready;
  late Set<int> _targetPattern;
  final Set<int> _userSelections = {};

  int _previewSecondsRemaining = 0;
  Timer? _countdownTimer;
  final Stopwatch _stopwatch = Stopwatch();

  int _cumulativeScore = 0;
  double? _lastRoundAccuracy;

  PatternLevelConfig get _currentConfig => _levels[_levelIndex];
  int get _cellCount => _currentConfig.gridSize * _currentConfig.gridSize;

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _initLevel() {
    _countdownTimer?.cancel();
    final config = _currentConfig;
    final random = Random();
    final all = List<int>.generate(config.gridSize * config.gridSize, (i) => i)..shuffle(random);
    _targetPattern = all.take(config.activeTiles).toSet();

    _userSelections.clear();
    _previewSecondsRemaining = config.previewSeconds;
    _phase = PatternPhase.ready;
    _lastRoundAccuracy = null;
    setState(() {});
  }

  void _startPreview() {
    SoundService.playTap();
    setState(() {
      _phase = PatternPhase.preview;
      _previewSecondsRemaining = _currentConfig.previewSeconds;
    });

    SoundService.speak('Memorize the illuminated pattern.');

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_previewSecondsRemaining > 1) {
        setState(() {
          _previewSecondsRemaining--;
        });
      } else {
        timer.cancel();
        _startRecall();
      }
    });
  }

  void _startRecall() {
    SoundService.playSuccess();
    setState(() {
      _phase = PatternPhase.recall;
      _userSelections.clear();
      _stopwatch.reset();
      _stopwatch.start();
    });
    SoundService.speak('Now tap the tiles that were lit.');
  }

  void _toggleTile(int index) {
    if (_phase != PatternPhase.recall) return;
    SoundService.playTap();

    setState(() {
      if (_userSelections.contains(index)) {
        _userSelections.remove(index);
      } else {
        _userSelections.add(index);
      }
    });
  }

  Future<void> _submitPattern(AppState appState) async {
    _stopwatch.stop();

    int correct = 0;
    int mistakes = 0;

    for (final index in _userSelections) {
      if (_targetPattern.contains(index)) {
        correct++;
      } else {
        mistakes++;
      }
    }

    final double rawScore = (correct - mistakes).clamp(0, _targetPattern.length).toDouble();
    final double maxScore = _targetPattern.length.toDouble();
    final double accuracy = (rawScore / maxScore) * 100.0;
    final int roundPoints = (accuracy).toInt();
    _cumulativeScore += roundPoints;

    setState(() {
      _phase = PatternPhase.roundSummary;
      _lastRoundAccuracy = accuracy;
    });

    if (accuracy >= 65.0) {
      SoundService.playFanfare();
      if (mounted && _levelIndex == _levels.length - 1) {
        ConfettiOverlay.show(
          context,
          title: 'Pattern Visionary! 🌟',
          subtitle: 'You mastered all ${_levels.length} grid matrix tiers!',
        );
      }
    } else {
      SoundService.playError();
    }

    // Log attempt into repository
    await appState.attemptRepository.logAttempt(
      ExerciseAttempt(
        id: 'att_pat_${DateTime.now().millisecondsSinceEpoch}',
        userId: appState.credentialId,
        domain: ExerciseDomain.universalCognitive,
        cognitiveDomain: CognitiveDomain.workingMemory,
        type: ExerciseType.patternRecall,
        exerciseId: 'pattern_memory_tier_${_levelIndex + 1}',
        responseMode: 'action',
        rawScore: rawScore,
        maxScore: maxScore,
        timeTakenMs: _stopwatch.elapsedMilliseconds,
      ),
    );
  }

  void _nextTierOrRestart() {
    if (_levelIndex < _levels.length - 1) {
      _levelIndex++;
      _initLevel();
    } else {
      _levelIndex = 0;
      _cumulativeScore = 0;
      _initLevel();
    }
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
          'Pattern Memory Grid',
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
              color: AppColors.sageSecondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.grid_on_rounded, size: 16, color: AppColors.sageSecondary),
                const SizedBox(width: 4),
                Text(
                  'Working Memory',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sageSecondary,
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
              // Tier Indicator Header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sandalwoodGold.withOpacity(0.4)),
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
                            'TIER ${_levelIndex + 1} OF ${_levels.length}',
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 11 * fontScale,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: AppColors.terracottaPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_currentConfig.gridSize}x${_currentConfig.gridSize} Matrix (${_currentConfig.activeTiles} Tiles)',
                            style: GoogleFonts.newsreader(
                              fontSize: 16 * fontScale,
                              fontWeight: FontWeight.bold,
                              color: AppColors.charcoalText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_phase == PatternPhase.preview)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.terracottaPrimary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_previewSecondsRemaining}s',
                          style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.sageSecondary.withOpacity(0.15),
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

              // Grid Container
              AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F3EC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.sandalwoodGold.withOpacity(0.4), width: 1.5),
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _cellCount,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _currentConfig.gridSize,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final isTarget = _targetPattern.contains(index);
                      final isSelected = _userSelections.contains(index);
                      final isPreview = _phase == PatternPhase.preview;
                      final isSummary = _phase == PatternPhase.roundSummary;

                      Color tileBg = Colors.white;
                      Border border = Border.all(color: Colors.black12);

                      if (isPreview && isTarget) {
                        tileBg = AppColors.sandalwoodGold;
                        border = Border.all(color: AppColors.sandalwoodGold, width: 2.5);
                      } else if (!isPreview && isSelected) {
                        tileBg = AppColors.terracottaPrimary;
                        border = Border.all(color: AppColors.terracottaPrimary, width: 2.5);
                      }

                      if (isSummary) {
                        if (isTarget && isSelected) {
                          tileBg = AppColors.sageSecondary;
                          border = Border.all(color: AppColors.sageSecondary, width: 2.5);
                        } else if (!isTarget && isSelected) {
                          tileBg = AppColors.terracottaPrimary;
                          border = Border.all(color: AppColors.terracottaPrimary, width: 2.5);
                        } else if (isTarget && !isSelected) {
                          tileBg = AppColors.sandalwoodGold.withOpacity(0.4);
                          border = Border.all(color: AppColors.sandalwoodGold, width: 2);
                        }
                      }

                      return GestureDetector(
                        onTap: () => _toggleTile(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: tileBg,
                            borderRadius: BorderRadius.circular(14),
                            border: border,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4),
                            ],
                          ),
                          child: Center(
                            child: isSummary
                                ? (isTarget && isSelected)
                                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                                    : (!isTarget && isSelected)
                                        ? const Icon(Icons.close, color: Colors.white, size: 24)
                                        : (isTarget && !isSelected)
                                            ? const Icon(Icons.help_outline, color: AppColors.charcoalText, size: 20)
                                            : null
                                : (isPreview && isTarget)
                                    ? const Icon(Icons.lightbulb, color: Colors.white, size: 24)
                                    : isSelected
                                        ? const Icon(Icons.touch_app, color: Colors.white, size: 20)
                                        : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Control State
              if (_phase == PatternPhase.ready)
                ElevatedButton.icon(
                  onPressed: _startPreview,
                  icon: const Icon(Icons.visibility_rounded),
                  label: Text(
                    'Preview Pattern (${_currentConfig.previewSeconds}s)',
                    style: GoogleFonts.atkinsonHyperlegible(fontSize: 16 * fontScale, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracottaPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                )
              else if (_phase == PatternPhase.preview)
                Center(
                  child: Text(
                    'Memorize the illuminated tiles...',
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 14 * fontScale,
                      fontStyle: FontStyle.italic,
                      color: AppColors.secondaryText,
                    ),
                  ),
                )
              else if (_phase == PatternPhase.recall)
                ElevatedButton.icon(
                  onPressed: _userSelections.isNotEmpty ? () => _submitPattern(appState) : null,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    'Submit Pattern (${_userSelections.length} Selected)',
                    style: GoogleFonts.atkinsonHyperlegible(fontSize: 16 * fontScale, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sageSecondary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                )
              else if (_phase == PatternPhase.roundSummary)
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
                        'Tier Accuracy: ${_lastRoundAccuracy?.toInt() ?? 0}%',
                        style: GoogleFonts.newsreader(
                          fontSize: 18 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoalText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Green = Correct, Orange = Distractor, Gold Outline = Missed',
                        style: GoogleFonts.atkinsonHyperlegible(fontSize: 12 * fontScale, color: AppColors.secondaryText),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: _nextTierOrRestart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracottaPrimary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _levelIndex < _levels.length - 1 ? 'Proceed to Next Tier' : 'Restart Challenge',
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
