import '../services/session_engine/memory_session_generator.dart';
import '../models/game_difficulty.dart';
import '../widgets/difficulty_selector.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_overlay.dart';

class FruitItem {
  final String id;
  final String name;
  final String emoji;
  final Color color;

  const FruitItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
  });
}

const List<FruitItem> kAvailableFruits = [
  FruitItem(id: 'apple', name: 'Apple', emoji: '🍎', color: Color(0xFFD32F2F)),
  FruitItem(id: 'banana', name: 'Banana', emoji: '🍌', color: Color(0xFFF57F17)),
  FruitItem(id: 'grapes', name: 'Grapes', emoji: '🍇', color: Color(0xFF7B1FA2)),
  FruitItem(id: 'orange', name: 'Orange', emoji: '🍊', color: Color(0xFFE65100)),
  FruitItem(id: 'watermelon', name: 'Watermelon', emoji: '🍉', color: Color(0xFF2E7D32)),
  FruitItem(id: 'mango', name: 'Mango', emoji: '🥭', color: Color(0xFFEF6C00)),
  FruitItem(id: 'pineapple', name: 'Pineapple', emoji: '🍍', color: Color(0xFFF9A825)),
  FruitItem(id: 'strawberry', name: 'Strawberry', emoji: '🍓', color: Color(0xFFC2185B)),
  FruitItem(id: 'coconut', name: 'Coconut', emoji: '🥥', color: Color(0xFF5D4037)),
  FruitItem(id: 'guava', name: 'Guava', emoji: '🍐', color: Color(0xFF558B2F)),
];

enum FruitGamePhase {
  ready,
  preview,
  navigation,
  levelComplete,
  gameSummary,
}

class FruitDifficultyConfig {
  final GameDifficulty difficulty;
  final int gridSize; // 3 for 3x3, 4 for 4x4
  final int fruitCount;
  final int previewSeconds;
  final String description;

  const FruitDifficultyConfig({
    required this.difficulty,
    required this.gridSize,
    required this.fruitCount,
    required this.previewSeconds,
    required this.description,
  });
}

const Map<GameDifficulty, FruitDifficultyConfig> kFruitDifficultyConfigs = {
  GameDifficulty.easy: FruitDifficultyConfig(
    difficulty: GameDifficulty.easy,
    gridSize: 3,
    fruitCount: 3,
    previewSeconds: 6,
    description: '3 fruits on a 3x3 garden path (6s memorization)',
  ),
  GameDifficulty.medium: FruitDifficultyConfig(
    difficulty: GameDifficulty.medium,
    gridSize: 4,
    fruitCount: 5,
    previewSeconds: 5,
    description: '5 fruits on a 4x4 garden path (5s memorization)',
  ),
  GameDifficulty.hard: FruitDifficultyConfig(
    difficulty: GameDifficulty.hard,
    gridSize: 4,
    fruitCount: 7,
    previewSeconds: 4,
    description: '7 fruits on a 4x4 garden path (4s memorization)',
  ),
};

class FruitMemoryPathScreen extends StatefulWidget {
  const FruitMemoryPathScreen({super.key});

  @override
  State<FruitMemoryPathScreen> createState() => _FruitMemoryPathScreenState();
}

class _FruitMemoryPathScreenState extends State<FruitMemoryPathScreen> {
  GameDifficulty _difficulty = GameDifficulty.easy;
  FruitGamePhase _phase = FruitGamePhase.ready;

  FruitDifficultyConfig get _currentConfig => kFruitDifficultyConfigs[_difficulty]!;

  // Level State (Stored Internally & Immutable during round)
  late int _gridSize;
  late int _cellCount;
  late List<int> _targetPathIndices;
  late List<FruitItem> _targetFruits;
  late Map<int, FruitItem> _gridFruitMap;

  // Gameplay State
  int _userStep = 0; // Current position in the sequence user needs to find
  final Set<int> _discoveredCells = {};
  int? _lastTappedIndex;
  bool _lastTapWasError = false;
  int _mistakesCount = 0;
  int _previewSecondsRemaining = 6;
  Timer? _countdownTimer;
  final Stopwatch _stopwatch = Stopwatch();

  // Accumulated metrics
  int _totalCorrectSteps = 0;
  int _totalMistakes = 0;
  int _cumulativeScore = 0;



  @override
  void initState() {
    super.initState();
    _initRound();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _initRound() {
    _countdownTimer?.cancel();
    final session = MemorySessionGenerator.generateFruitSession(_difficulty);
    _gridSize = session.stimulus.gridSize;
    _cellCount = _gridSize * _gridSize;
    _targetPathIndices = session.stimulus.pathIndices;

    _targetFruits = session.stimulus.fruits.map((f) => FruitItem(
      id: f.id,
      name: f.name,
      emoji: f.emoji,
      color: f.color,
    )).toList();

    _gridFruitMap = {};
    for (int i = 0; i < _targetPathIndices.length; i++) {
      _gridFruitMap[_targetPathIndices[i]] = _targetFruits[i];
    }

    _userStep = 0;
    _discoveredCells.clear();
    _lastTappedIndex = null;
    _lastTapWasError = false;
    _mistakesCount = 0;
    _previewSecondsRemaining = _currentConfig.previewSeconds; // Strict 5s memorization
    _phase = FruitGamePhase.ready;
    setState(() {});
  }

  void _startPreviewPhase() {
    SoundService.playTap();
    setState(() {
      _phase = FruitGamePhase.preview;
      _previewSecondsRemaining = _currentConfig.previewSeconds;
    });

    SoundService.speak('Memorize the fruit path. You have 5 seconds.');

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_previewSecondsRemaining > 1) {
        setState(() {
          _previewSecondsRemaining--;
        });
      } else {
        timer.cancel();
        _startNavigationPhase();
      }
    });
  }

  void _startNavigationPhase() {
    SoundService.playSuccess();
    setState(() {
      _phase = FruitGamePhase.navigation;
      _discoveredCells.clear();
      _userStep = 0;
      _lastTappedIndex = null;
      _lastTapWasError = false;
      _stopwatch.reset();
      _stopwatch.start();
    });

    SoundService.speak('Now reproduce the fruit sequence from memory.');
  }

  void _onCellTapped(int index) {
    if (_phase != FruitGamePhase.navigation) return;
    if (_discoveredCells.contains(index)) return; // Already solved

    final targetCell = _targetPathIndices[_userStep];

    setState(() {
      _lastTappedIndex = index;
    });

    if (index == targetCell) {
      // Correct step!
      SoundService.playTap();
      setState(() {
        _lastTapWasError = false;
        _discoveredCells.add(index);
        _userStep++;
        _totalCorrectSteps++;
      });

      if (_userStep >= _targetFruits.length) {
        // Level completely solved!
        _stopwatch.stop();
        _handleLevelSuccess();
      }
    } else {
      // Mistake: Wrong cell tapped
      SoundService.playError();
      setState(() {
        _lastTapWasError = true;
        _mistakesCount++;
        _totalMistakes++;
      });

      // Clear error flash after 500ms
      Timer(const Duration(milliseconds: 600), () {
        if (mounted && _lastTappedIndex == index) {
          setState(() {
            _lastTapWasError = false;
            _lastTappedIndex = null;
          });
        }
      });
    }
  }

  void _handleLevelSuccess() {
    final levelPoints = (100 - (_mistakesCount * 15)).clamp(40, 100);
    _cumulativeScore += levelPoints;

    SoundService.playFanfare();
    setState(() {
      _phase = FruitGamePhase.levelComplete;
    });
  }

  Future<void> _advanceOrFinish(AppState appState) async {
    _phase = FruitGamePhase.gameSummary;
    final maxPossibleScore = _targetFruits.length * 100.0;

    if (mounted) {
      ConfettiOverlay.show(
        context,
        title: 'Fruit Path Champion! 🍎',
        subtitle: 'Completed ${_difficulty.label} path with $_totalCorrectSteps correct path steps!',
      );
    }
    await appState.attemptRepository.logAttempt(
      ExerciseAttempt(
        id: 'att_fruit_${DateTime.now().millisecondsSinceEpoch}',
        userId: appState.credentialId,
        domain: ExerciseDomain.universalCognitive,
        cognitiveDomain: CognitiveDomain.spatialMemory,
        type: ExerciseType.fruitMemoryPath,
        exerciseId: 'fruit_memory_path_${_difficulty.name}',
        responseMode: 'action',
        rawScore: _cumulativeScore.toDouble(),
        maxScore: maxPossibleScore,
        timeTakenMs: _stopwatch.elapsedMilliseconds,
        metadata: {
          'difficulty': _difficulty.name,
          'mistakesCount': _totalMistakes,
        },
      ),
    );
    setState(() {});
  }

  void _restartWholeGame() {
    SoundService.playTap();
    _cumulativeScore = 0;
    _totalCorrectSteps = 0;
    _totalMistakes = 0;
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
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.charcoalText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Fruit Memory Path',
          style: GoogleFonts.newsreader(
            fontSize: 22 * fontScale,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoalText,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.terracottaPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.route_rounded, size: 16, color: AppColors.terracottaPrimary),
                const SizedBox(width: 4),
                Text(
                  'Spatial Recall',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.terracottaPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderStatusCard(fontScale),
              const SizedBox(height: 14),
              _buildSequenceBar(fontScale),
              const SizedBox(height: 14),
              _buildGameBoard(fontScale),
              const SizedBox(height: 16),
              _buildBottomControls(appState, fontScale),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header Status Card ──
  Widget _buildHeaderStatusCard(double fontScale) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.4)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.terracottaSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${_difficulty.label.toUpperCase()} DIFFICULTY • ${_currentConfig.gridSize}×${_currentConfig.gridSize} GARDEN',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 11 * fontScale,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.terracottaPrimary,
                  ),
                ),
              ),
              Text(
                'Score: $_cumulativeScore',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 13 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sageSecondary,
                ),
              ),
            ],
          ),
          if (_phase == FruitGamePhase.ready) ...[
            const SizedBox(height: 10),
            DifficultySelector(
              selected: _difficulty,
              onChanged: (d) {
                setState(() {
                  _difficulty = d;
                  _initRound();
                });
              },
            ),
          ],
          const SizedBox(height: 8),
          Text(
            _phase == FruitGamePhase.preview
                ? 'Memorize the path of fruits! (${_previewSecondsRemaining}s left)'
                : _phase == FruitGamePhase.navigation
                    ? 'Step along the garden pavers in the exact fruit sequence.'
                    : 'Study the fruit path for 5 seconds, then tap each fruit in order.',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 14 * fontScale,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoalText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Sequence Indicator (Shows fruits with arrows: 🍎 → 🍌 → 🍇, NEVER NUMBERS) ──
  Widget _buildSequenceBar(double fontScale) {
    final isPreview = _phase == FruitGamePhase.preview;
    final isNav = _phase == FruitGamePhase.navigation;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPreview
              ? AppColors.terracottaPrimary
              : AppColors.sandalwoodGold.withValues(alpha: 0.4),
          width: isPreview ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isPreview
                      ? 'FRUIT PATH SEQUENCE (5-SEC PREVIEW):'
                      : 'REPRODUCE SEQUENCE IN ORDER:',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 11 * fontScale,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isPreview ? AppColors.terracottaPrimary : AppColors.secondaryText,
                ),
              ),
              ),
              if (isPreview)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.terracottaPrimary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$_previewSecondsRemaining s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Fruit Sequence Flow: 🍎 → 🍌 → 🍇 (NO numbers on the fruits)
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: List.generate(_targetFruits.length, (idx) {
              final fruit = _targetFruits[idx];
              final isDiscovered = _userStep > idx;
              final isCurrent = _userStep == idx && isNav;

              // What icon to display: during preview, show all fruits. During nav, show discovered ones or ❓
              final showFruit = isPreview || isDiscovered;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDiscovered
                          ? AppColors.sageSecondary.withValues(alpha: 0.15)
                          : isCurrent
                              ? AppColors.terracottaPrimary.withValues(alpha: 0.15)
                              : isPreview
                                  ? fruit.color.withValues(alpha: 0.12)
                                  : const Color(0xFFF3F1ED),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDiscovered
                            ? AppColors.sageSecondary
                            : isCurrent
                                ? AppColors.terracottaPrimary
                                : isPreview
                                    ? fruit.color
                                    : AppColors.borderSubtle,
                        width: (isCurrent || isPreview) ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          showFruit ? fruit.emoji : '❓',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          showFruit ? fruit.name : 'Secret',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 12 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: showFruit ? AppColors.charcoalText : AppColors.secondaryText,
                          ),
                        ),
                        if (isDiscovered) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.check, size: 14, color: AppColors.sageSecondary),
                        ],
                      ],
                    ),
                  ),
                  if (idx < _targetFruits.length - 1) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.black26),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Game Board (Paver Garden Grid) ──
  Widget _buildGameBoard(double fontScale) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F2E7), // Warm sandstone paver ground
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.4), width: 2),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _cellCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _gridSize,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final fruit = _gridFruitMap[index];
            final hasFruit = fruit != null;
            final isPreview = _phase == FruitGamePhase.preview;
            final isDiscovered = _discoveredCells.contains(index);
            final isErrorTap = _lastTappedIndex == index && _lastTapWasError;

            return GestureDetector(
              onTap: () => _onCellTapped(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isErrorTap
                      ? Colors.redAccent.withValues(alpha: 0.2)
                      : (isPreview && hasFruit)
                          ? fruit.color.withValues(alpha: 0.18)
                          : isDiscovered
                              ? AppColors.sageSecondary.withValues(alpha: 0.2)
                              : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isErrorTap
                        ? Colors.redAccent
                        : (isPreview && hasFruit)
                            ? fruit.color
                            : isDiscovered
                                ? AppColors.sageSecondary
                                : AppColors.sandalwoodGold.withValues(alpha: 0.35),
                    width: (isPreview && hasFruit) || isDiscovered || isErrorTap ? 2.0 : 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: isPreview && hasFruit
                      // NO NUMBERS! The fruit emoji and name represent the sequence itself
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              fruit.emoji,
                              style: TextStyle(fontSize: _gridSize == 3 ? 34 : 26),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fruit.name,
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: (_gridSize == 3 ? 12 : 10) * fontScale,
                                fontWeight: FontWeight.bold,
                                color: AppColors.charcoalText,
                              ),
                            ),
                          ],
                        )
                      : isDiscovered && hasFruit
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  fruit.emoji,
                                  style: TextStyle(fontSize: _gridSize == 3 ? 32 : 24),
                                ),
                                const SizedBox(height: 2),
                                const Icon(Icons.check_circle_rounded, color: AppColors.sageSecondary, size: 16),
                              ],
                            )
                          : Icon(
                              Icons.yard_outlined,
                              color: Colors.black.withValues(alpha: 0.08),
                              size: _gridSize == 3 ? 28 : 20,
                            ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Bottom Controls & Feedback ──
  Widget _buildBottomControls(AppState appState, double fontScale) {
    if (_phase == FruitGamePhase.ready) {
      return ElevatedButton.icon(
        onPressed: _startPreviewPhase,
        icon: const Icon(Icons.visibility_rounded, size: 22),
        label: Text(
          'Start 5-Second Memorization',
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 16 * fontScale,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.terracottaPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }

    if (_phase == FruitGamePhase.preview) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        child: Text(
          'Memorize the fruits! Pavers will hide in $_previewSecondsRemaining seconds...',
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 14 * fontScale,
            fontWeight: FontWeight.bold,
            color: AppColors.terracottaPrimary,
          ),
        ),
      );
    }

    if (_phase == FruitGamePhase.navigation) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Found: $_userStep of ${_targetFruits.length} fruits',
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 14 * fontScale,
                fontWeight: FontWeight.bold,
                color: AppColors.charcoalText,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              SoundService.playTap();
              _initRound();
            },
            icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.secondaryText),
            label: Text(
              'Restart Round',
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 13 * fontScale,
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      );
    }

    if (_phase == FruitGamePhase.levelComplete) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.sageSecondary, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6)],
        ),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                const Icon(Icons.stars_rounded, color: AppColors.sageSecondary, size: 28),
                Text(
                  'Round Mastered!',
                  style: GoogleFonts.newsreader(
                    fontSize: 20 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoalText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'You navigated all ${_targetFruits.length} fruits in sequence from memory! (Mistakes: $_mistakesCount)',
              textAlign: TextAlign.center,
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 13 * fontScale,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      SoundService.playTap();
                      _initRound();
                    },
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: Text(
                      'Replay Round',
                      style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.charcoalText,
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: AppColors.sandalwoodGold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _advanceOrFinish(appState),
                    icon: const Icon(Icons.emoji_events_rounded, size: 18),
                    label: Text(
                      'View Summary',
                      style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracottaPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }



    // Game Summary
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.terracottaPrimary, width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events_rounded, color: AppColors.terracottaPrimary, size: 48),
          const SizedBox(height: 8),
          Text(
            'Fruit Memory Path Complete! 🍎',
            style: GoogleFonts.newsreader(
              fontSize: 22 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoalText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Total Score: $_cumulativeScore • Total Mistakes: $_totalMistakes',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 14 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _restartWholeGame,
            icon: const Icon(Icons.replay_rounded, size: 20),
            label: Text(
              'Play Again',
              style: GoogleFonts.atkinsonHyperlegible(fontSize: 15 * fontScale, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracottaPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
