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
  FruitItem(id: 'apple', name: 'Apple', emoji: '🍎', color: Color(0xFFE63946)),
  FruitItem(id: 'banana', name: 'Banana', emoji: '🍌', color: Color(0xFFE9C46A)),
  FruitItem(id: 'mango', name: 'Mango', emoji: '🥭', color: Color(0xFFF4A261)),
  FruitItem(id: 'grapes', name: 'Grapes', emoji: '🍇', color: Color(0xFF7209B7)),
  FruitItem(id: 'orange', name: 'Orange', emoji: '🍊', color: Color(0xFFFB8500)),
  FruitItem(id: 'strawberry', name: 'Strawberry', emoji: '🍓', color: Color(0xFFD90429)),
  FruitItem(id: 'coconut', name: 'Coconut', emoji: '🥥', color: Color(0xFF6C584C)),
  FruitItem(id: 'pomegranate', name: 'Pomegranate', emoji: '🫐', color: Color(0xFF3A0CA3)),
];

enum FruitGamePhase {
  ready,
  preview,
  navigation,
  levelComplete,
  gameSummary,
}

class FruitLevelConfig {
  final int level;
  final int gridSize; // 3 for 3x3, 4 for 4x4
  final int fruitCount;
  final int previewSeconds;

  const FruitLevelConfig({
    required this.level,
    required this.gridSize,
    required this.fruitCount,
    required this.previewSeconds,
  });
}

class FruitMemoryPathScreen extends StatefulWidget {
  const FruitMemoryPathScreen({super.key});

  @override
  State<FruitMemoryPathScreen> createState() => _FruitMemoryPathScreenState();
}

class _FruitMemoryPathScreenState extends State<FruitMemoryPathScreen> {
  final List<FruitLevelConfig> _levels = const [
    FruitLevelConfig(level: 1, gridSize: 3, fruitCount: 3, previewSeconds: 5),
    FruitLevelConfig(level: 2, gridSize: 3, fruitCount: 4, previewSeconds: 4),
    FruitLevelConfig(level: 3, gridSize: 4, fruitCount: 5, previewSeconds: 4),
    FruitLevelConfig(level: 4, gridSize: 4, fruitCount: 6, previewSeconds: 3),
  ];

  int _currentLevelIdx = 0;
  FruitGamePhase _phase = FruitGamePhase.ready;

  // Level State
  late int _gridSize;
  late int _cellCount;
  late List<int> _targetPathIndices;
  late List<FruitItem> _targetFruits;
  late Map<int, FruitItem> _gridFruitMap;

  // Gameplay State
  int _avatarPosition = 0;
  int _nextFruitIndex = 0;
  final Set<int> _discoveredCells = {};
  int _mistakesCount = 0;
  int _previewSecondsRemaining = 0;
  Timer? _countdownTimer;
  final Stopwatch _stopwatch = Stopwatch();

  // Accumulated metrics
  int _totalCorrectSteps = 0;
  int _totalMistakes = 0;
  int _cumulativeScore = 0;

  FruitLevelConfig get _currentConfig => _levels[_currentLevelIdx];

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
    _gridSize = config.gridSize;
    _cellCount = _gridSize * _gridSize;

    // Generate non-overlapping random cells for path
    final allIndices = List<int>.generate(_cellCount, (i) => i)..shuffle();
    _targetPathIndices = allIndices.take(config.fruitCount).toList();

    // Pick distinct fruits
    final shuffledFruits = List<FruitItem>.from(kAvailableFruits)..shuffle();
    _targetFruits = shuffledFruits.take(config.fruitCount).toList();

    _gridFruitMap = {};
    for (int i = 0; i < config.fruitCount; i++) {
      _gridFruitMap[_targetPathIndices[i]] = _targetFruits[i];
    }

    _avatarPosition = _targetPathIndices.first;
    _nextFruitIndex = 0;
    _discoveredCells.clear();
    _mistakesCount = 0;
    _previewSecondsRemaining = config.previewSeconds;
    _phase = FruitGamePhase.ready;
    setState(() {});
  }

  void _startPreviewPhase() {
    SoundService.playTap();
    setState(() {
      _phase = FruitGamePhase.preview;
      _previewSecondsRemaining = _currentConfig.previewSeconds;
    });

    SoundService.speak(
      'Memorize the fruit locations. You have ${_currentConfig.previewSeconds} seconds.',
    );

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
      _nextFruitIndex = 0;
      _stopwatch.reset();
      _stopwatch.start();
    });

    SoundService.speak(
      'Now navigate your character. Find the ${_targetFruits.first.name} first.',
    );
  }

  void _onCellTapped(int index) {
    if (_phase != FruitGamePhase.navigation) return;

    final targetCell = _targetPathIndices[_nextFruitIndex];
    final expectedFruit = _targetFruits[_nextFruitIndex];

    setState(() {
      _avatarPosition = index;
    });

    if (index == targetCell) {
      // Correct step!
      SoundService.playTap();
      setState(() {
        _discoveredCells.add(index);
        _nextFruitIndex++;
        _totalCorrectSteps++;
      });

      if (_nextFruitIndex >= _targetFruits.length) {
        // Level complete!
        _stopwatch.stop();
        _handleLevelSuccess();
      } else {
        SoundService.speak('Good! Next find the ${_targetFruits[_nextFruitIndex].name}.');
      }
    } else {
      // Mistake
      SoundService.playError();
      setState(() {
        _mistakesCount++;
        _totalMistakes++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 900),
          backgroundColor: AppColors.terracottaPrimary,
          content: Text(
            'Not there! Look for ${expectedFruit.emoji} ${expectedFruit.name}.',
            style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      );
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
    if (_currentLevelIdx < _levels.length - 1) {
      _currentLevelIdx++;
      _initLevel();
    } else {
      // Game completely finished!
      _phase = FruitGamePhase.gameSummary;
      final totalSteps = _totalCorrectSteps + _totalMistakes;
      final accuracy = totalSteps > 0 ? (_totalCorrectSteps / totalSteps * 100.0) : 100.0;
      final maxPossibleScore = _levels.length * 100.0;

      // Log real attempt into repository
      await appState.attemptRepository.logAttempt(
        ExerciseAttempt(
          id: 'att_fruit_${DateTime.now().millisecondsSinceEpoch}',
          userId: appState.credentialId,
          domain: ExerciseDomain.universalCognitive,
          cognitiveDomain: CognitiveDomain.spatialMemory,
          type: ExerciseType.fruitMemoryPath,
          exerciseId: 'fruit_memory_path_flagship',
          responseMode: 'action',
          rawScore: _cumulativeScore.toDouble(),
          maxScore: maxPossibleScore,
          timeTakenMs: _stopwatch.elapsedMilliseconds,
          metadata: {
            'levelsCompleted': _levels.length,
            'accuracy': accuracy.toInt(),
            'mistakes': _totalMistakes,
          },
        ),
      );

      setState(() {});

      if (mounted) {
        ConfettiOverlay.show(
          context,
          title: 'Spatial Master! 🏆',
          subtitle: 'Completed all ${_levels.length} levels with ${accuracy.toInt()}% accuracy!',
        );
      }
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
          'Fruit Memory Path',
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
              color: AppColors.terracottaPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.explore_rounded, size: 16, color: AppColors.terracottaPrimary),
                const SizedBox(width: 4),
                Text(
                  'Spatial Memory',
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card: Level & Instructions
              _buildHeaderCard(fontScale),
              const SizedBox(height: 14),

              // Target Path Sequence Ribbon
              _buildTargetSequenceRibbon(fontScale),
              const SizedBox(height: 16),

              // The Main Interactive Grid
              _buildGrid(fontScale),
              const SizedBox(height: 18),

              // Bottom Action Area
              _buildBottomControls(appState, fontScale),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(double fontScale) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.terracottaPrimary.withOpacity(0.2)),
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
                  'LEVEL ${_currentLevelIdx + 1} OF ${_levels.length}',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 11 * fontScale,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppColors.terracottaPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_currentConfig.gridSize}x${_currentConfig.gridSize} Garden Path (${_currentConfig.fruitCount} Fruits)',
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
          if (_phase == FruitGamePhase.preview)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.terracottaPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    '${_previewSecondsRemaining}s',
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 18 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.sageSecondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
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
    );
  }

  Widget _buildTargetSequenceRibbon(double fontScale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.canvasIvory,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sandalwoodGold.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_rounded, size: 16, color: AppColors.sandalwoodGold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'TARGET PATH SEQUENCE (IN ORDER):',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 11 * fontScale,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.charcoalText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_targetFruits.length, (i) {
                final fruit = _targetFruits[i];
                final isDone = _discoveredCells.contains(_targetPathIndices[i]);
                final isCurrent = _phase == FruitGamePhase.navigation && _nextFruitIndex == i;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.sageSecondary
                          : isCurrent
                              ? AppColors.terracottaPrimary
                              : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrent ? AppColors.terracottaPrimary : Colors.black12,
                        width: isCurrent ? 2 : 1,
                      ),
                      boxShadow: isCurrent
                          ? [BoxShadow(color: AppColors.terracottaPrimary.withOpacity(0.3), blurRadius: 6)]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${i + 1}. ',
                          style: TextStyle(
                            fontSize: 12 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: (isDone || isCurrent) ? Colors.white : AppColors.secondaryText,
                          ),
                        ),
                        Text(
                          fruit.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fruit.name,
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 13 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: (isDone || isCurrent) ? Colors.white : AppColors.charcoalText,
                          ),
                        ),
                        if (isDone) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.check_circle, size: 14, color: Colors.white),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(double fontScale) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F2E7), // Warm sandstone paver surface
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.sandalwoodGold.withOpacity(0.4), width: 2),
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
            final isDiscovered = _discoveredCells.contains(index);
            final isAvatarHere = _avatarPosition == index && _phase == FruitGamePhase.navigation;
            final isPreviewing = _phase == FruitGamePhase.preview;

            return GestureDetector(
              onTap: () => _onCellTapped(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: (isPreviewing && hasFruit)
                      ? fruit.color.withOpacity(0.18)
                      : isDiscovered
                          ? AppColors.sageSecondary.withOpacity(0.2)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isAvatarHere
                        ? AppColors.terracottaPrimary
                        : (isPreviewing && hasFruit)
                            ? fruit.color
                            : isDiscovered
                                ? AppColors.sageSecondary
                                : AppColors.sandalwoodGold.withOpacity(0.3),
                    width: (isAvatarHere || (isPreviewing && hasFruit)) ? 2.5 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Preview Mode: Display the fruit and its sequence badge
                    if (isPreviewing && hasFruit) ...[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(fruit.emoji, style: TextStyle(fontSize: _gridSize == 3 ? 32 : 24)),
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
                      ),
                      Positioned(
                        top: 4,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: fruit.color,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${_targetPathIndices.indexOf(index) + 1}',
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ]
                    // Discovered during navigation
                    else if (isDiscovered && hasFruit) ...[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(fruit.emoji, style: TextStyle(fontSize: _gridSize == 3 ? 30 : 22)),
                          const SizedBox(height: 2),
                          const Icon(Icons.check_circle_rounded, color: AppColors.sageSecondary, size: 16),
                        ],
                      ),
                    ]
                    // Hidden paver during navigation
                    else ...[
                      Icon(
                        Icons.yard_outlined,
                        color: Colors.black.withOpacity(0.08),
                        size: _gridSize == 3 ? 28 : 20,
                      ),
                    ],

                    // Avatar Pin (Always visible on current cell during navigation)
                    if (isAvatarHere)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.terracottaPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.directions_walk_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomControls(AppState appState, double fontScale) {
    if (_phase == FruitGamePhase.ready) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sandalwoodGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: AppColors.sandalwoodGold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Observe the fruit path for ${_currentConfig.previewSeconds} seconds, then guide your character across them in order.',
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 13 * fontScale,
                      color: AppColors.charcoalText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _startPreviewPhase,
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: Text(
              'Start ${_currentConfig.previewSeconds}s Memory Preview',
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
      );
    }

    if (_phase == FruitGamePhase.preview) {
      return Center(
        child: Text(
          'Memorize positions! Navigation starts automatically...',
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 14 * fontScale,
            fontStyle: FontStyle.italic,
            color: AppColors.secondaryText,
          ),
        ),
      );
    }

    if (_phase == FruitGamePhase.navigation) {
      final currentExpectedFruit = _targetFruits[_nextFruitIndex];
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.terracottaPrimary.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.terracottaPrimary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Text(currentExpectedFruit.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step ${_nextFruitIndex + 1} of ${_targetFruits.length}',
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 12 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: AppColors.terracottaPrimary,
                    ),
                  ),
                  Text(
                    'Tap the cell where ${currentExpectedFruit.name} was placed',
                    style: GoogleFonts.newsreader(
                      fontSize: 15 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoalText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_phase == FruitGamePhase.levelComplete) {
      final isLastLevel = _currentLevelIdx >= _levels.length - 1;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.sageSecondary, width: 2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.sageSecondary, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Level ${_currentLevelIdx + 1} Path Cleared! 🌟',
                    style: GoogleFonts.newsreader(
                      fontSize: 18 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoalText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Mistakes made: $_mistakesCount • Time: ${(_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s',
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 14 * fontScale,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => _advanceOrFinish(appState),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sageSecondary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isLastLevel ? 'View Final Results' : 'Proceed to Level ${_currentLevelIdx + 2}',
                style: GoogleFonts.atkinsonHyperlegible(fontSize: 15 * fontScale, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    // Summary Phase
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.terracottaPrimary, width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.military_tech_rounded, size: 48, color: AppColors.sandalwoodGold),
          const SizedBox(height: 8),
          Text(
            'Exercise Completed!',
            style: GoogleFonts.newsreader(
              fontSize: 22 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.terracottaPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Final Score: $_cumulativeScore / ${_levels.length * 100}',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 16 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoalText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your Spatial Memory & Working Memory scores have been updated in your profile.',
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
                child: OutlinedButton(
                  onPressed: () {
                    _currentLevelIdx = 0;
                    _cumulativeScore = 0;
                    _totalCorrectSteps = 0;
                    _totalMistakes = 0;
                    _initLevel();
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Replay'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracottaPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
