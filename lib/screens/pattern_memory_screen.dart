import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../engine/exercise_engine.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

import '../services/sound_service.dart';
import '../widgets/confetti_overlay.dart';

class PatternMemoryScreen extends StatefulWidget {
  const PatternMemoryScreen({super.key});

  @override
  State<PatternMemoryScreen> createState() => _PatternMemoryScreenState();
}

class _PatternMemoryScreenState extends State<PatternMemoryScreen> {
  late ExerciseEngine _engine;

  // 3x3 Grid Matrix (0 to 8)
  final Set<int> _targetPattern = {0, 2, 4, 6, 8}; // X pattern
  final Set<int> _userPattern = {};
  double? _scorePercentage;

  @override
  void initState() {
    super.initState();
    _engine = ExerciseEngine();
  }

  void _startStudy() {
    SoundService.playTap();
    setState(() => _engine.startStudy());
  }

  void _startRecall() {
    SoundService.playTap();
    setState(() {
      _userPattern.clear();
      _engine.startRecall();
    });
  }

  void _toggleCell(int index) {
    if (_engine.phase != ExercisePhase.recall) return;
    SoundService.playFlip();
    setState(() {
      if (_userPattern.contains(index)) {
        _userPattern.remove(index);
      } else {
        _userPattern.add(index);
      }
    });
  }

  Future<void> _submit(AppState appState) async {
    int correctTaps = 0;
    int falseTaps = 0;

    for (final cell in _userPattern) {
      if (_targetPattern.contains(cell)) {
        correctTaps++;
      } else {
        falseTaps++;
      }
    }

    final double rawScore = (correctTaps - falseTaps).clamp(0, _targetPattern.length).toDouble();
    final double maxScore = _targetPattern.length.toDouble();
    final double percentage = (rawScore / maxScore) * 100.0;

    await _engine.finishAndLogAttempt(
      appState: appState,
      domain: ExerciseDomain.universalCognitive,
      type: ExerciseType.recognition,
      exerciseId: 'pattern_memory_grid',
      responseMode: 'action',
      rawScore: rawScore,
      maxScore: maxScore,
    );

    setState(() {
      _scorePercentage = percentage;
    });

    if (percentage >= 60.0) {
      SoundService.playFanfare();
      if (mounted) {
        ConfettiOverlay.show(
          context,
          title: 'Pattern Mastered!',
          subtitle: 'You accurately reconstructed the visual grid pattern!',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fontScale = appState.fontScale;

    return ListenableBuilder(
      listenable: _engine,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Pattern Memory (पैटर्न स्मृति)',
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
                      border: Border.all(color: AppColors.sageSecondary, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.grid_3x3_rounded, color: AppColors.sageSecondary, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Visual Grid Pattern Memory',
                          style: GoogleFonts.newsreader(fontSize: 22 * fontScale, fontWeight: FontWeight.bold, color: AppColors.sageSecondary),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Study the illuminated cells on the grid. Reconstruct the pattern accurately when the cells turn off.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.atkinsonHyperlegible(fontSize: 15 * fontScale),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.sageSecondary),
                            icon: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                            label: Text('Start Study Phase', style: GoogleFonts.atkinsonHyperlegible(fontSize: 18 * fontScale, fontWeight: FontWeight.bold, color: Colors.white)),
                            onPressed: _startStudy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_engine.phase == ExercisePhase.study || _engine.phase == ExercisePhase.recall) ...[
                  Text(
                    _engine.phase == ExercisePhase.study ? 'STUDY THE ILLUMINATED PATTERN' : 'RECONSTRUCT THE PATTERN',
                    style: GoogleFonts.newsreader(fontSize: 15 * fontScale, fontWeight: FontWeight.bold, color: AppColors.sageSecondary),
                  ),
                  const SizedBox(height: 20),

                  // 3x3 Grid Container
                  Container(
                    width: 280,
                    height: 280,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.sageSecondary, width: 2),
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: 9,
                      itemBuilder: (context, idx) {
                        final isHighlighted = _engine.phase == ExercisePhase.study
                            ? _targetPattern.contains(idx)
                            : _userPattern.contains(idx);

                        return GestureDetector(
                          onTap: _engine.phase == ExercisePhase.recall ? () => _toggleCell(idx) : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isHighlighted ? AppColors.sageSecondary : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isHighlighted ? AppColors.sageSecondary : (isDark ? Colors.white24 : Colors.black26),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: isHighlighted
                                  ? const Icon(Icons.circle, color: Colors.white, size: 28)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),

                  if (_engine.phase == ExercisePhase.study)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.sageSecondary),
                        icon: const Icon(Icons.visibility_off, color: Colors.white, size: 28),
                        label: Text('Hide Pattern (Start Recall)', style: GoogleFonts.atkinsonHyperlegible(fontSize: 18 * fontScale, fontWeight: FontWeight.bold, color: Colors.white)),
                        onPressed: _startRecall,
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.sageSecondary),
                        icon: const Icon(Icons.check, color: Colors.white, size: 28),
                        label: Text('Submit Pattern', style: GoogleFonts.atkinsonHyperlegible(fontSize: 18 * fontScale, fontWeight: FontWeight.bold, color: Colors.white)),
                        onPressed: () => _submit(appState),
                      ),
                    ),
                ],

                if (_engine.phase == ExercisePhase.feedback && _scorePercentage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _scorePercentage! >= 60.0 ? Colors.green : Colors.orange, width: 2),
                    ),
                    child: Column(
                      children: [
                        Icon(_scorePercentage! >= 60.0 ? Icons.stars : Icons.info, color: _scorePercentage! >= 60.0 ? Colors.green : Colors.orange, size: 64),
                        const SizedBox(height: 12),
                        Text('${_scorePercentage!.toInt()}% PATTERN ACCURACY', style: GoogleFonts.newsreader(fontSize: 22 * fontScale, fontWeight: FontWeight.bold, color: _scorePercentage! >= 60.0 ? Colors.green : Colors.orange)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.sageSecondary, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: () => setState(() => _engine.reset()),
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
