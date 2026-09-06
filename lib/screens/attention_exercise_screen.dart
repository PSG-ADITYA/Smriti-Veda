import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../engine/exercise_engine.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

import '../services/sound_service.dart';
import '../widgets/confetti_overlay.dart';

class AttentionExerciseScreen extends StatefulWidget {
  const AttentionExerciseScreen({super.key});

  @override
  State<AttentionExerciseScreen> createState() => _AttentionExerciseScreenState();
}

class _AttentionExerciseScreenState extends State<AttentionExerciseScreen> {
  late ExerciseEngine _engine;

  final List<Map<String, dynamic>> _items = [
    {'type': 'target', 'shape': 'circle', 'color': AppColors.sageSecondary, 'icon': Icons.circle},
    {'type': 'distractor', 'shape': 'square', 'color': AppColors.terracottaPrimary, 'icon': Icons.square},
    {'type': 'target', 'shape': 'circle', 'color': AppColors.sageSecondary, 'icon': Icons.circle},
    {'type': 'distractor', 'shape': 'square', 'color': AppColors.terracottaPrimary, 'icon': Icons.square},
    {'type': 'distractor', 'shape': 'square', 'color': AppColors.terracottaPrimary, 'icon': Icons.square},
    {'type': 'target', 'shape': 'circle', 'color': AppColors.sageSecondary, 'icon': Icons.circle},
    {'type': 'target', 'shape': 'circle', 'color': AppColors.sageSecondary, 'icon': Icons.circle},
    {'type': 'distractor', 'shape': 'square', 'color': AppColors.terracottaPrimary, 'icon': Icons.square},
    {'type': 'target', 'shape': 'circle', 'color': AppColors.sageSecondary, 'icon': Icons.circle},
  ];

  final Set<int> _selectedIndices = {};
  double? _scorePercentage;

  @override
  void initState() {
    super.initState();
    _engine = ExerciseEngine();
  }

  void _startExercise() {
    SoundService.playTap();
    setState(() => _engine.startRecall());
  }

  void _toggleSelect(int index) {
    if (_engine.phase != ExercisePhase.recall) return;
    SoundService.playFlip();
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  Future<void> _submit(AppState appState) async {
    int targetCount = _items.where((e) => e['type'] == 'target').length;
    int correctSelected = 0;
    int wrongSelected = 0;

    for (int i = 0; i < _items.length; i++) {
      final isTarget = _items[i]['type'] == 'target';
      final isSelected = _selectedIndices.contains(i);

      if (isTarget && isSelected) {
        correctSelected++;
      } else if (!isTarget && isSelected) {
        wrongSelected++;
      }
    }

    double rawScore = (correctSelected - wrongSelected).clamp(0, targetCount).toDouble();
    double pct = (rawScore / targetCount) * 100.0;

    await _engine.finishAndLogAttempt(
      appState: appState,
      domain: ExerciseDomain.universalCognitive,
      type: ExerciseType.sequenceRecall,
      exerciseId: 'attention_focus_v1',
      responseMode: 'visual_tap',
      rawScore: rawScore,
      maxScore: targetCount.toDouble(),
    );

    setState(() {
      _scorePercentage = pct;
    });

    if (pct >= 60.0) {
      SoundService.playFanfare();
      if (mounted) {
        ConfettiOverlay.show(
          context,
          title: 'Great Focus!',
          subtitle: 'You found $correctSelected out of $targetCount circles accurately!',
        );
      }
    } else {
      SoundService.playError();
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
          'Attention & Focus',
          style: GoogleFonts.newsreader(
            color: AppColors.charcoalText,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.sageSecondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.sageSecondary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.center_focus_strong, color: AppColors.sageSecondary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tap ONLY the Green Circles. Ignore the Terracotta Squares.',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoalText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_engine.phase == ExercisePhase.setup) ...[
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.sandalwoodGold.withValues(alpha: 0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.visibility, size: 56, color: AppColors.terracottaPrimary),
                      const SizedBox(height: 16),
                      Text(
                        'Visual Selective Attention',
                        style: GoogleFonts.newsreader(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoalText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This exercise trains concentration and response inhibition by requiring you to select target shapes while filtering out distractors.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 16,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _startExercise,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracottaPrimary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Start Focus Grid',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_engine.phase == ExercisePhase.recall) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _items.length,
                itemBuilder: (context, idx) {
                  final item = _items[idx];
                  final isSelected = _selectedIndices.contains(idx);

                  return GestureDetector(
                    onTap: () => _toggleSelect(idx),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (item['color'] as Color).withValues(alpha: 0.2)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? item['color'] as Color
                              : AppColors.sandalwoodGold.withValues(alpha: 0.3),
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          item['icon'] as IconData,
                          size: 48,
                          color: item['color'] as Color,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _submit(appState),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracottaPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Submit Selection',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else if (_engine.phase == ExercisePhase.complete) ...[
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.sageSecondary.withValues(alpha: 0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 64, color: AppColors.sageSecondary),
                      const SizedBox(height: 16),
                      Text(
                        'Attention Test Completed!',
                        style: GoogleFonts.newsreader(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoalText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Accuracy: ${_scorePercentage?.toStringAsFixed(0)}%',
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.terracottaPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Great focus! Regular practice improves visual attention and mental clarity.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 15,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracottaPrimary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Return to Practice',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
