import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../engine/exercise_engine.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/scoring_service.dart';
import '../theme/app_theme.dart';

class RecognitionExerciseScreen extends StatefulWidget {
  const RecognitionExerciseScreen({super.key});

  @override
  State<RecognitionExerciseScreen> createState() => _RecognitionExerciseScreenState();
}

class _RecognitionExerciseScreenState extends State<RecognitionExerciseScreen> {
  late ExerciseEngine _engine;
  int _difficultyLevel = 1; // 1 = 3 targets + 3 distractors, 2 = 4 targets + 4 distractors

  // Sample Recognition Items with Icons
  final Map<String, IconData> _itemIcons = {
    'Lotus (कमल)': Icons.eco_outlined,
    'Lamp (दीपक)': Icons.lightbulb_outline,
    'Flute (बांसुरी)': Icons.music_note_outlined,
    'Conch (शंख)': Icons.campaign_outlined,
    'Bell (घंटी)': Icons.notifications_none_outlined,
    'Tree (वृक्ष)': Icons.park_outlined,
    'Sun (सूर्य)': Icons.wb_sunny_outlined,
    'Star (तारा)': Icons.star_outline,
  };

  late Set<String> _targetItems;
  late List<String> _testGrid;
  final Set<String> _selectedItems = {};
  RecognitionScoreResult? _result;

  @override
  void initState() {
    super.initState();
    _engine = ExerciseEngine();
    _loadRecognitionSet();
  }

  void _loadRecognitionSet() {
    _engine.reset();
    _selectedItems.clear();
    _result = null;

    final allKeys = _itemIcons.keys.toList();
    allKeys.shuffle();

    final targetCount = _difficultyLevel == 1 ? 3 : 4;
    _targetItems = Set.from(allKeys.take(targetCount));
    
    // Mix targets with distractors for the test grid
    _testGrid = List.from(allKeys.take(targetCount * 2))..shuffle();
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

  void _toggleSelection(String item) {
    if (_engine.phase != ExercisePhase.recall) return;

    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  Future<void> _submitAnswers(AppState appState) async {
    final res = ScoringService.computeRecognitionScore(_targetItems, _selectedItems);

    await _engine.finishAndLogAttempt(
      appState: appState,
      domain: ExerciseDomain.universalCognitive,
      type: ExerciseType.recognition,
      exerciseId: 'recog_level_$_difficultyLevel',
      responseMode: 'choice',
      rawScore: res.rawScore,
      maxScore: res.maxScore,
      metadata: {
        'difficultyLevel': _difficultyLevel,
        'targetItems': _targetItems.toList(),
        'selectedItems': _selectedItems.toList(),
      },
    );

    setState(() {
      _result = res;
    });
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
              'Recognition Memory (पहचान स्मृति)',
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
              children: [
                // Level selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [1, 2].map((lvl) {
                    final isSelected = _difficultyLevel == lvl;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text('Level $lvl (${lvl == 1 ? "3 Targets" : "4 Targets"})'),
                        selectedColor: AppColors.primarySaffron.withValues(alpha: 0.3),
                        checkmarkColor: AppColors.primarySaffron,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _difficultyLevel = lvl;
                              _loadRecognitionSet();
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
                        const Icon(Icons.grid_view_rounded, color: AppColors.primaryGold, size: 56),
                        const SizedBox(height: 16),
                        Text(
                          'Recognition Memory Exercise',
                          style: GoogleFonts.cinzel(
                            fontSize: 20 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Study the target symbols carefully. Afterwards, pick them out from a grid containing distractor items.',
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

                // PHASE 2: STUDY PHASE (Target Items Visible)
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
                        const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF3D6B58), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Study Phase: Remember these target symbols. Tap Ready when finished.',
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

                  // Target Items Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 100,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _targetItems.length,
                    itemBuilder: (context, idx) {
                      final item = _targetItems.elementAt(idx);
                      final icon = _itemIcons[item] ?? Icons.help_outline;

                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.primaryGold, width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, color: AppColors.primaryGold, size: 36),
                            const SizedBox(height: 6),
                            Text(
                              item,
                              style: GoogleFonts.outfit(
                                fontSize: 14 * fontScale,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textLightPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
                        'Ready for Test Grid',
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

                // PHASE 3: RECALL PHASE (Test Grid with Distractors)
                if (_engine.phase == ExercisePhase.recall) ...[
                  Text(
                    'SELECT THE REMEMBERED TARGET SYMBOLS',
                    style: GoogleFonts.cinzel(
                      fontSize: 15 * fontScale,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.primaryGold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 110,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _testGrid.length,
                    itemBuilder: (context, idx) {
                      final item = _testGrid[idx];
                      final icon = _itemIcons[item] ?? Icons.help_outline;
                      final isSelected = _selectedItems.contains(item);

                      return GestureDetector(
                        onTap: () => _toggleSelection(item),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primarySaffron.withValues(alpha: 0.2)
                                : (isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected ? AppColors.primarySaffron : AppColors.primaryGold.withValues(alpha: 0.4),
                              width: isSelected ? 2.5 : 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon,
                                color: isSelected ? AppColors.primarySaffron : (isDark ? Colors.white70 : Colors.black87),
                                size: 36,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item,
                                style: GoogleFonts.outfit(
                                  fontSize: 14 * fontScale,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected
                                      ? AppColors.primarySaffron
                                      : (isDark ? Colors.white : AppColors.textLightPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedItems.isNotEmpty ? AppColors.primarySaffron : Colors.grey,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.check, color: Colors.white, size: 28),
                      label: Text(
                        'Submit Selection',
                        style: GoogleFonts.outfit(
                          fontSize: 18 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: _selectedItems.isNotEmpty ? () => _submitAnswers(appState) : null,
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
                          _result!.percentage >= 60.0 ? Icons.verified_user_rounded : Icons.info_outline,
                          color: _result!.percentage >= 60.0 ? Colors.green : Colors.orange,
                          size: 64,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_result!.percentage.toInt()}% RECOGNITION SCORE',
                          style: GoogleFonts.cinzel(
                            fontSize: 22 * fontScale,
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
                                Text('Correct Targets', style: GoogleFonts.outfit(fontSize: 12 * fontScale, color: isDark ? Colors.white54 : Colors.black54)),
                                const SizedBox(height: 2),
                                Text('${_result!.correctSelectionsCount} / ${_result!.totalTargetItems}', style: GoogleFonts.outfit(fontSize: 18 * fontScale, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              children: [
                                Text('Distractors Picked', style: GoogleFonts.outfit(fontSize: 12 * fontScale, color: isDark ? Colors.white54 : Colors.black54)),
                                const SizedBox(height: 2),
                                Text('${_result!.falsePositivesCount}', style: GoogleFonts.outfit(fontSize: 18 * fontScale, fontWeight: FontWeight.bold, color: _result!.falsePositivesCount > 0 ? Colors.redAccent : Colors.green)),
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
                                    _loadRecognitionSet();
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
                                    _difficultyLevel = _difficultyLevel == 1 ? 2 : 1;
                                    _loadRecognitionSet();
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
