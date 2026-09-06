import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../engine/exercise_engine.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/scoring_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_overlay.dart';

class ObjectMemoryScreen extends StatefulWidget {
  const ObjectMemoryScreen({super.key});

  @override
  State<ObjectMemoryScreen> createState() => _ObjectMemoryScreenState();
}

class _ObjectMemoryScreenState extends State<ObjectMemoryScreen> {
  late ExerciseEngine _engine;

  final Map<String, IconData> _tableObjects = const {
    'Keys (चाबी)': Icons.vpn_key_outlined,
    'Glasses (चश्मा)': Icons.visibility_outlined,
    'Book (पुस्तक)': Icons.menu_book_outlined,
    'Watch (घड़ी)': Icons.watch_later_outlined,
    'Cup (प्याला)': Icons.coffee_outlined,
  };

  final Map<String, IconData> _distractorObjects = const {
    'Pen (कलम)': Icons.edit_outlined,
    'Lamp (दीपक)': Icons.lightbulb_outline,
    'Umbrella (छाता)': Icons.beach_access_outlined,
  };

  late Set<String> _targetSet;
  late List<String> _choiceGrid;
  final Set<String> _userSelections = {};
  RecognitionScoreResult? _result;

  @override
  void initState() {
    super.initState();
    _engine = ExerciseEngine();
    _loadScene();
  }

  void _loadScene() {
    _engine.reset();
    _userSelections.clear();
    _result = null;

    _targetSet = Set.from(_tableObjects.keys);
    _choiceGrid = [..._tableObjects.keys, ..._distractorObjects.keys]..shuffle();
  }

  void _startStudy() {
    SoundService().playTapSound();
    setState(() => _engine.startStudy());
  }

  void _startRecall() {
    SoundService().playFlipSound();
    setState(() => _engine.startRecall());
  }

  void _toggleSelection(String item) {
    if (_engine.phase != ExercisePhase.recall) return;
    SoundService().playTapSound();
    setState(() {
      if (_userSelections.contains(item)) {
        _userSelections.remove(item);
      } else {
        _userSelections.add(item);
      }
    });
  }

  Future<void> _submit(AppState appState) async {
    final res = ScoringService.computeRecognitionScore(_targetSet, _userSelections);

    await _engine.finishAndLogAttempt(
      appState: appState,
      domain: ExerciseDomain.universalCognitive,
      type: ExerciseType.recognition,
      exerciseId: 'object_memory_table',
      responseMode: 'choice',
      rawScore: res.rawScore,
      maxScore: res.maxScore,
    );

    setState(() {
      _result = res;
    });

    if (res.percentage >= 60.0 && mounted) {
      ConfettiOverlay.of(context)?.triggerCelebration(
        title: 'Object Recall Mastered! 🎉',
        subtitle: 'Score: ${res.percentage.toInt()}% (${res.correctSelectionsCount} of ${_targetSet.length} table objects remembered!)',
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
              'Object Memory (वस्तु स्मृति)',
              style: GoogleFonts.newsreader(fontWeight: FontWeight.bold, fontSize: 20 * fontScale),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (_engine.phase == ExercisePhase.setup) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.terracottaPrimary, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.table_restaurant_outlined, color: AppColors.terracottaPrimary, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Table Object Memory',
                          style: GoogleFonts.newsreader(fontSize: 22 * fontScale, fontWeight: FontWeight.bold, color: AppColors.terracottaPrimary),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Study the 5 everyday objects placed on the table. After they disappear, identify which objects were present.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.atkinsonHyperlegible(fontSize: 15 * fontScale),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracottaPrimary),
                            icon: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                            label: Text('Start Study Phase', style: GoogleFonts.atkinsonHyperlegible(fontSize: 18 * fontScale, fontWeight: FontWeight.bold, color: Colors.white)),
                            onPressed: _startStudy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_engine.phase == ExercisePhase.study) ...[
                  Text(
                    'STUDY THE OBJECTS ON THE TABLE',
                    style: GoogleFonts.newsreader(fontSize: 15 * fontScale, fontWeight: FontWeight.bold, color: AppColors.terracottaPrimary),
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
                    itemCount: _targetSet.length,
                    itemBuilder: (context, idx) {
                      final item = _targetSet.elementAt(idx);
                      final icon = _tableObjects[item] ?? Icons.category;
                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.terracottaPrimary, width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, size: 36, color: AppColors.terracottaPrimary),
                            const SizedBox(height: 6),
                            Text(item, style: GoogleFonts.atkinsonHyperlegible(fontSize: 14 * fontScale, fontWeight: FontWeight.bold)),
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
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracottaPrimary),
                      icon: const Icon(Icons.visibility_off, color: Colors.white, size: 28),
                      label: Text('Hide Table (Start Test)', style: GoogleFonts.atkinsonHyperlegible(fontSize: 18 * fontScale, fontWeight: FontWeight.bold, color: Colors.white)),
                      onPressed: _startRecall,
                    ),
                  ),
                ],

                if (_engine.phase == ExercisePhase.recall) ...[
                  Text(
                    'WHAT WAS ON THE TABLE?',
                    style: GoogleFonts.newsreader(fontSize: 15 * fontScale, fontWeight: FontWeight.bold, color: AppColors.terracottaPrimary),
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
                    itemCount: _choiceGrid.length,
                    itemBuilder: (context, idx) {
                      final item = _choiceGrid[idx];
                      final icon = _tableObjects[item] ?? _distractorObjects[item] ?? Icons.category;
                      final isSelected = _userSelections.contains(item);

                      return GestureDetector(
                        onTap: () => _toggleSelection(item),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.terracottaPrimary.withValues(alpha: 0.2) : (isDark ? AppColors.darkCard : AppColors.lightCard),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? AppColors.terracottaPrimary : AppColors.terracottaPrimary.withValues(alpha: 0.4), width: isSelected ? 2.5 : 1.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, size: 36, color: isSelected ? AppColors.terracottaPrimary : (isDark ? Colors.white70 : Colors.black87)),
                              const SizedBox(height: 6),
                              Text(item, style: GoogleFonts.atkinsonHyperlegible(fontSize: 14 * fontScale, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
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
                      style: ElevatedButton.styleFrom(backgroundColor: _userSelections.isNotEmpty ? AppColors.terracottaPrimary : Colors.grey),
                      icon: const Icon(Icons.check, color: Colors.white, size: 28),
                      label: Text('Submit Answer', style: GoogleFonts.atkinsonHyperlegible(fontSize: 18 * fontScale, fontWeight: FontWeight.bold, color: Colors.white)),
                      onPressed: _userSelections.isNotEmpty ? () => _submit(appState) : null,
                    ),
                  ),
                ],

                if (_engine.phase == ExercisePhase.feedback && _result != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _result!.percentage >= 60.0 ? Colors.green : Colors.orange, width: 2),
                    ),
                    child: Column(
                      children: [
                        Icon(_result!.percentage >= 60.0 ? Icons.stars : Icons.info, color: _result!.percentage >= 60.0 ? Colors.green : Colors.orange, size: 64),
                        const SizedBox(height: 12),
                        Text('${_result!.percentage.toInt()}% OBJECT ACCURACY', style: GoogleFonts.newsreader(fontSize: 22 * fontScale, fontWeight: FontWeight.bold, color: _result!.percentage >= 60.0 ? Colors.green : Colors.orange)),
                        const SizedBox(height: 8),
                        Text(_result!.feedbackText, textAlign: TextAlign.center, style: GoogleFonts.atkinsonHyperlegible(fontSize: 15 * fontScale)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracottaPrimary, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text('Play Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: () => setState(_loadScene),
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
