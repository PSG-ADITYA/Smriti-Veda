import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../engine/exercise_engine.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/scoring_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_overlay.dart';

class SequenceRecallScreen extends StatefulWidget {
  const SequenceRecallScreen({super.key});

  @override
  State<SequenceRecallScreen> createState() => _SequenceRecallScreenState();
}

class _SequenceRecallScreenState extends State<SequenceRecallScreen> {
  late ExerciseEngine _engine;
  int _difficultyLevel = 1; // 1 = 4 items, 2 = 5 items, 3 = 6 items

  // Sample sequence pools
  final List<List<String>> _sequencePool = [
    ['7', '3', '9', '2'],
    ['Om', 'Shanti', 'Satya', 'Dharma'],
    ['4', '8', '1', '6', '5'],
    ['Ganga', 'Yamuna', 'Kaveri', 'Narmada', 'Godavari'],
  ];

  late List<String> _targetSequence;
  late List<String> _shuffledPool;
  final List<String> _userSequence = [];
  SequenceScoreResult? _result;

  @override
  void initState() {
    super.initState();
    _engine = ExerciseEngine();
    _loadSequence();
  }

  void _loadSequence() {
    _engine.reset();
    _userSequence.clear();
    _result = null;

    final index = (_difficultyLevel - 1) % _sequencePool.length;
    _targetSequence = List.from(_sequencePool[index]);
    _shuffledPool = List.from(_targetSequence)..shuffle();
  }

  void _startStudyPhase() {
    setState(() {
      _engine.startStudy();
    });
  }

  void _startRecallPhase() {
    setState(() {
      _engine.startRecall();
    });
  }

  void _onItemTapped(String item) {
    if (_engine.phase != ExercisePhase.recall) return;
    if (_userSequence.length >= _targetSequence.length) return;

    setState(() {
      _userSequence.add(item);
    });
  }

  void _removeLastItem() {
    if (_userSequence.isNotEmpty) {
      setState(() {
        _userSequence.removeLast();
      });
    }
  }

  void _clearUserSequence() {
    setState(() {
      _userSequence.clear();
    });
  }

  Future<void> _submitSequence(AppState appState) async {
    final res = ScoringService.computeSequenceScore(_targetSequence, _userSequence);

    await _engine.finishAndLogAttempt(
      appState: appState,
      domain: ExerciseDomain.universalCognitive,
      type: ExerciseType.sequenceRecall,
      exerciseId: 'seq_level_$_difficultyLevel',
      responseMode: 'choice',
      rawScore: res.rawScore,
      maxScore: res.maxScore,
      metadata: {
        'difficultyLevel': _difficultyLevel,
        'targetSequence': _targetSequence.join(', '),
        'userSequence': _userSequence.join(', '),
      },
    );

    setState(() {
      _result = res;
    });

    if (res.percentage >= 70.0 && mounted) {
      ConfettiOverlay.of(context)?.triggerCelebration(
        title: 'Sequence Mastered! 🎉',
        subtitle: 'Score: ${res.percentage.toInt()}% (${res.rawScore.toInt()} of ${res.maxScore.toInt()} items in order!)',
      );
    } else {
      SoundService().playErrorSound();
    }
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fontScale = appState.fontScale;

    return ListenableBuilder(
      listenable: _engine,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Sequence Recall (अनुक्रम स्मृति)',
              style: GoogleFonts.cinzel(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGold,
                fontSize: 18 * fontScale,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Level selector chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [1, 2, 3].map((lvl) {
                    final isSelected = _difficultyLevel == lvl;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text('Level $lvl (${lvl + 3} Items)'),
                        selectedColor: AppColors.primarySaffron.withValues(alpha: 0.3),
                        checkmarkColor: AppColors.primarySaffron,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _difficultyLevel = lvl;
                              _loadSequence();
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // PHASE 1: SETUP PHASE
                if (_engine.phase == ExercisePhase.setup) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.format_list_numbered_rounded, color: AppColors.primaryGold, size: 56),
                        const SizedBox(height: 16),
                        Text(
                          'Sequence Recall Exercise',
                          style: GoogleFonts.cinzel(
                            fontSize: 20 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Memorize the sequence items in exact order. Then reconstruct them from memory.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14 * fontScale,
                            color: isDark ? Colors.white70 : AppColors.textLightSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primarySaffron,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                            label: Text(
                              'Start Study Phase',
                              style: GoogleFonts.outfit(
                                fontSize: 18 * fontScale,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: _startStudyPhase,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // PHASE 2: STUDY PHASE (Sequence Visible)
                if (_engine.phase == ExercisePhase.study) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D6B58).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF3D6B58).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.visibility_outlined, color: Color(0xFF3D6B58), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Study Phase: Memorize the exact order of items below, then tap Ready for Recall.',
                            style: GoogleFonts.outfit(
                              fontSize: 13 * fontScale,
                              color: isDark ? Colors.white70 : AppColors.textLightPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Target Sequence Display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.primaryGold, width: 2),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(_targetSequence.length, (idx) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primarySaffron.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primarySaffron, width: 1.5),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${idx + 1}',
                                style: GoogleFonts.outfit(
                                  fontSize: 12 * fontScale,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primarySaffron,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _targetSequence[idx],
                                style: GoogleFonts.outfit(
                                  fontSize: 22 * fontScale,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.textLightPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primarySaffron,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
                      label: Text(
                        'Ready for Recall (Hide Sequence)',
                        style: GoogleFonts.outfit(
                          fontSize: 18 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: _startRecallPhase,
                    ),
                  ),
                ],

                // PHASE 3: RECALL PHASE (Sequence Hidden)
                if (_engine.phase == ExercisePhase.recall) ...[
                  Text(
                    'RECONSTRUCT THE SEQUENCE',
                    style: GoogleFonts.cinzel(
                      fontSize: 16 * fontScale,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.primaryGold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Selected User Sequence Box
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 90),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.6), width: 1.5),
                    ),
                    child: _userSequence.isEmpty
                        ? Center(
                            child: Text(
                              'Tap items below in order',
                              style: GoogleFonts.outfit(
                                fontSize: 15 * fontScale,
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        : Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: List.generate(_userSequence.length, (idx) {
                              return Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: AppColors.primaryGold,
                                  child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                                ),
                                label: Text(
                                  _userSequence[idx],
                                  style: GoogleFonts.outfit(
                                    fontSize: 16 * fontScale,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() {
                                    _userSequence.removeAt(idx);
                                  });
                                },
                              );
                            }),
                          ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.undo, color: Colors.orangeAccent),
                        label: const Text('Undo Last'),
                        onPressed: _userSequence.isNotEmpty ? _removeLastItem : null,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.clear_all, color: Colors.redAccent),
                        label: const Text('Clear All'),
                        onPressed: _userSequence.isNotEmpty ? _clearUserSequence : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Shuffled Choice Items Pool
                  Text(
                    'Available Items:',
                    style: GoogleFonts.outfit(fontSize: 14 * fontScale, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _shuffledPool.map((item) {
                      final countInUser = _userSequence.where((x) => x == item).length;
                      final countInTarget = _targetSequence.where((x) => x == item).length;
                      final isDisabled = countInUser >= countInTarget;

                      return SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDisabled
                                ? (isDark ? Colors.white12 : Colors.black12)
                                : (isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard),
                            foregroundColor: isDisabled
                                ? (isDark ? Colors.white24 : Colors.black26)
                                : (isDark ? Colors.white : AppColors.textLightPrimary),
                            side: BorderSide(
                              color: isDisabled ? Colors.transparent : AppColors.primaryGold,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: isDisabled ? null : () => _onItemTapped(item),
                          child: Text(
                            item,
                            style: GoogleFonts.outfit(
                              fontSize: 18 * fontScale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _userSequence.length == _targetSequence.length
                            ? AppColors.primarySaffron
                            : Colors.grey,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.check, color: Colors.white, size: 28),
                      label: Text(
                        'Submit Answer',
                        style: GoogleFonts.outfit(
                          fontSize: 18 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: _userSequence.length == _targetSequence.length
                          ? () => _submitSequence(appState)
                          : null,
                    ),
                  ),
                ],

                // PHASE 4: FEEDBACK & RESULTS PHASE
                if (_engine.phase == ExercisePhase.feedback && _result != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _result!.percentage >= 60.0 ? Colors.green : Colors.orange,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _result!.percentage >= 60.0 ? Icons.stars_rounded : Icons.replay_circle_filled_rounded,
                          color: _result!.percentage >= 60.0 ? Colors.green : Colors.orange,
                          size: 64,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_result!.percentage.toInt()}% SCORE',
                          style: GoogleFonts.cinzel(
                            fontSize: 26 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: _result!.percentage >= 60.0 ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _result!.feedbackText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 15 * fontScale,
                            color: isDark ? Colors.white70 : AppColors.textLightPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text('Exact Matches', style: GoogleFonts.outfit(fontSize: 12 * fontScale, color: isDark ? Colors.white54 : Colors.black54)),
                                const SizedBox(height: 2),
                                Text('${_result!.exactMatchesCount} / ${_result!.totalItems}', style: GoogleFonts.outfit(fontSize: 18 * fontScale, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              children: [
                                Text('Time Taken', style: GoogleFonts.outfit(fontSize: 12 * fontScale, color: isDark ? Colors.white54 : Colors.black54)),
                                const SizedBox(height: 2),
                                Text('${(_engine.timeTakenMs / 1000).toStringAsFixed(1)}s', style: GoogleFonts.outfit(fontSize: 18 * fontScale, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Try Again'),
                                onPressed: () {
                                  setState(() {
                                    _loadSequence();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primarySaffron,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                                label: const Text('Next Level', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  setState(() {
                                    _difficultyLevel = (_difficultyLevel % 3) + 1;
                                    _loadSequence();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
