import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../engine/exercise_engine.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

import '../services/sound_service.dart';
import '../widgets/confetti_overlay.dart';

class StoryMemoryScreen extends StatefulWidget {
  const StoryMemoryScreen({super.key});

  @override
  State<StoryMemoryScreen> createState() => _StoryMemoryScreenState();
}

class _StoryMemoryScreenState extends State<StoryMemoryScreen> {
  late ExerciseEngine _engine;

  final String _storyTitle = 'Ravi\'s Morning Walk';
  final String _storyBody =
      'Ravi went to the neighborhood garden at 6:30 in the morning. '
      'He met his friend Suresh under the neem tree and bought fresh apples before returning home.';

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Where did Ravi go in the morning?',
      'options': ['Neighborhood Garden', 'Railway Station', 'City Hospital', 'Bank'],
      'correctIdx': 0,
    },
    {
      'question': 'Who did Ravi meet under the neem tree?',
      'options': ['His brother Ramesh', 'His friend Suresh', 'Dr. Sharma', 'Nobody'],
      'correctIdx': 1,
    },
    {
      'question': 'What did Ravi buy before returning home?',
      'options': ['Sweets', 'Flowers', 'Fresh Apples', 'Milk'],
      'correctIdx': 2,
    },
  ];

  final Map<int, int> _userAnswers = {};
  double? _scorePercentage;

  @override
  void initState() {
    super.initState();
    _engine = ExerciseEngine();
  }

  void _startStudy() {
    SoundService.playTap();
    SoundService.speak('Story Recall. $_storyTitle. $_storyBody');
    setState(() => _engine.startStudy());
  }

  void _startRecall() {
    SoundService.playTap();
    setState(() => _engine.startRecall());
  }

  void _selectAnswer(int qIdx, int optIdx) {
    if (_engine.phase != ExercisePhase.recall) return;
    SoundService.playTap();
    setState(() {
      _userAnswers[qIdx] = optIdx;
    });
  }

  Future<void> _submit(AppState appState) async {
    int correctCount = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers[i] == _questions[i]['correctIdx']) {
        correctCount++;
      }
    }

    final double maxScore = _questions.length.toDouble();
    final double rawScore = correctCount.toDouble();
    final double percentage = (rawScore / maxScore) * 100.0;

    await _engine.finishAndLogAttempt(
      appState: appState,
      domain: ExerciseDomain.universalCognitive,
      type: ExerciseType.sequenceRecall,
      exerciseId: 'story_memory_ravi',
      responseMode: 'choice',
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
          title: 'Story Recall Excellent!',
          subtitle: 'You answered $correctCount out of ${_questions.length} questions correctly!',
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
              'Story Recall (कथा स्मरण)',
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
                      border: Border.all(color: AppColors.sandalwoodAccent, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.menu_book_outlined, color: AppColors.sandalwoodAccent, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Short Story Memory Exercise',
                          style: GoogleFonts.newsreader(fontSize: 22 * fontScale, fontWeight: FontWeight.bold, color: AppColors.sandalwoodAccent),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Read a short, familiar story. Afterwards, answer 3 simple comprehension questions to test your episodic memory.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.atkinsonHyperlegible(fontSize: 15 * fontScale),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.sandalwoodAccent),
                            icon: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                            label: Text('Read Story', style: GoogleFonts.atkinsonHyperlegible(fontSize: 18 * fontScale, fontWeight: FontWeight.bold, color: Colors.white)),
                            onPressed: _startStudy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_engine.phase == ExercisePhase.study) ...[
                  Text(
                    'READ & MEMORIZE THE STORY',
                    style: GoogleFonts.newsreader(fontSize: 15 * fontScale, fontWeight: FontWeight.bold, color: AppColors.sandalwoodAccent),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.sandalwoodAccent, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(_storyTitle, style: GoogleFonts.newsreader(fontSize: 20 * fontScale, fontWeight: FontWeight.bold, color: AppColors.sandalwoodAccent)),
                        const SizedBox(height: 14),
                        Text(
                          _storyBody,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.atkinsonHyperlegible(fontSize: 17 * fontScale, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.sandalwoodAccent),
                      icon: const Icon(Icons.visibility_off, color: Colors.white, size: 28),
                      label: Text('Start Questions (Hide Story)', style: GoogleFonts.atkinsonHyperlegible(fontSize: 18 * fontScale, fontWeight: FontWeight.bold, color: Colors.white)),
                      onPressed: _startRecall,
                    ),
                  ),
                ],

                if (_engine.phase == ExercisePhase.recall) ...[
                  ...List.generate(_questions.length, (qIdx) {
                    final q = _questions[qIdx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.sandalwoodAccent.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${qIdx + 1}. ${q['question']}', style: GoogleFonts.newsreader(fontSize: 17 * fontScale, fontWeight: FontWeight.bold, color: AppColors.sandalwoodAccent)),
                          const SizedBox(height: 12),
                          ...List.generate((q['options'] as List).length, (optIdx) {
                            final optText = q['options'][optIdx];
                            final isSelected = _userAnswers[qIdx] == optIdx;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected ? AppColors.sandalwoodAccent.withValues(alpha: 0.2) : (isDark ? AppColors.darkCard : AppColors.lightCard),
                                    side: BorderSide(color: isSelected ? AppColors.sandalwoodAccent : AppColors.sandalwoodAccent.withValues(alpha: 0.4), width: isSelected ? 2 : 1),
                                  ),
                                  onPressed: () => _selectAnswer(qIdx, optIdx),
                                  child: Text(optText, style: GoogleFonts.atkinsonHyperlegible(fontSize: 15 * fontScale, color: isDark ? Colors.white : AppColors.textLightPrimary)),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: _userAnswers.length == _questions.length ? AppColors.sandalwoodAccent : Colors.grey),
                      icon: const Icon(Icons.check, color: Colors.white, size: 28),
                      label: Text('Submit Answers', style: GoogleFonts.atkinsonHyperlegible(fontSize: 18 * fontScale, fontWeight: FontWeight.bold, color: Colors.white)),
                      onPressed: _userAnswers.length == _questions.length ? () => _submit(appState) : null,
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
                        Text('${_scorePercentage!.toInt()}% STORY COMPREHENSION', style: GoogleFonts.newsreader(fontSize: 22 * fontScale, fontWeight: FontWeight.bold, color: _scorePercentage! >= 60.0 ? Colors.green : Colors.orange)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.sandalwoodAccent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
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
