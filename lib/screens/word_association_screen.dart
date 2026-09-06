import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../engine/exercise_engine.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class WordAssociationScreen extends StatefulWidget {
  const WordAssociationScreen({super.key});

  @override
  State<WordAssociationScreen> createState() => _WordAssociationScreenState();
}

class _WordAssociationScreenState extends State<WordAssociationScreen> {
  late ExerciseEngine _engine;

  final List<Map<String, dynamic>> _pairs = [
    {
      'word': 'RAIN',
      'icon': Icons.water_drop,
      'options': ['UMBRELLA', 'SAND', 'SHOE', 'CLOCK'],
      'correctIdx': 0,
      'explanation': 'Rain is associated with an Umbrella for shelter.',
    },
    {
      'word': 'SUN',
      'icon': Icons.wb_sunny,
      'options': ['ICE', 'SUNGLASSES', 'BED', 'BOOK'],
      'correctIdx': 1,
      'explanation': 'Sun is associated with Sunglasses for light protection.',
    },
    {
      'word': 'DOCTOR',
      'icon': Icons.local_hospital,
      'options': ['GUITAR', 'PLANT', 'MEDICINE', 'PENCIL'],
      'correctIdx': 2,
      'explanation': 'Doctor is associated with Medicine for treatment.',
    },
    {
      'word': 'TEA',
      'icon': Icons.coffee,
      'options': ['CUP', 'BICYCLE', 'SHIRT', 'HAMMER'],
      'correctIdx': 0,
      'explanation': 'Tea is served in a Cup.',
    },
  ];

  final Map<int, int> _userAnswers = {};
  double? _scorePercentage;

  @override
  void initState() {
    super.initState();
    _engine = ExerciseEngine();
  }

  void _startRecall() {
    setState(() => _engine.startRecall());
  }

  void _selectOption(int pairIdx, int optionIdx) {
    if (_engine.phase != ExercisePhase.recall) return;
    setState(() {
      _userAnswers[pairIdx] = optionIdx;
    });
  }

  Future<void> _submit(AppState appState) async {
    int correct = 0;
    for (int i = 0; i < _pairs.length; i++) {
      if (_userAnswers[i] == _pairs[i]['correctIdx']) {
        correct++;
      }
    }

    final double maxScore = _pairs.length.toDouble();
    final double rawScore = correct.toDouble();
    final double pct = (rawScore / maxScore) * 100.0;

    await _engine.finishAndLogAttempt(
      appState: appState,
      domain: ExerciseDomain.universalCognitive,
      type: ExerciseType.sequenceRecall,
      exerciseId: 'word_association_v1',
      responseMode: 'choice',
      rawScore: rawScore,
      maxScore: maxScore,
    );

    setState(() {
      _scorePercentage = pct;
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
          'Word Association',
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
                  const Icon(Icons.link, color: AppColors.sageSecondary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Connect pairs of concepts to strengthen semantic memory pathways.',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 15,
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
                      const Icon(Icons.psychology, size: 56, color: AppColors.terracottaPrimary),
                      const SizedBox(height: 16),
                      Text(
                        'Semantic Link Game',
                        style: GoogleFonts.newsreader(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoalText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select the word logically associated with the given target word.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 16,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _startRecall,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracottaPrimary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Begin Activity',
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
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pairs.length,
                itemBuilder: (context, idx) {
                  final p = _pairs[idx];
                  final selected = _userAnswers[idx];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.sandalwoodGold.withValues(alpha: 0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(p['icon'] as IconData, color: AppColors.terracottaPrimary),
                              const SizedBox(width: 8),
                              Text(
                                p['word'] as String,
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.charcoalText,
                                ),
                              ),
                              const Text('  ➔  ?'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate((p['options'] as List).length, (optIdx) {
                              final optionText = p['options'][optIdx] as String;
                              final isSelected = selected == optIdx;

                              return ChoiceChip(
                                label: Text(
                                  optionText,
                                  style: GoogleFonts.atkinsonHyperlegible(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.white : AppColors.charcoalText,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: AppColors.terracottaPrimary,
                                backgroundColor: AppColors.canvasIvory,
                                onSelected: (_) => _selectOption(idx, optIdx),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _userAnswers.length == _pairs.length
                    ? () => _submit(appState)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracottaPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Submit Associations',
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
                        'Activity Complete!',
                        style: GoogleFonts.newsreader(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoalText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Score: ${_scorePercentage?.toStringAsFixed(0)}%',
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.terracottaPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your word association effort builds rich connection pathways in daily memory recall.',
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
