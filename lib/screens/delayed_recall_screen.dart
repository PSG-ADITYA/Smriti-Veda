import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../engine/exercise_engine.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class DelayedRecallScreen extends StatefulWidget {
  const DelayedRecallScreen({super.key});

  @override
  State<DelayedRecallScreen> createState() => _DelayedRecallScreenState();
}

class _DelayedRecallScreenState extends State<DelayedRecallScreen> {
  late ExerciseEngine _engine;

  final List<Map<String, dynamic>> _targetItems = [
    {'name': 'Silver Keys', 'icon': Icons.vpn_key},
    {'name': 'Reading Glasses', 'icon': Icons.visibility},
    {'name': 'Leather Wallet', 'icon': Icons.account_balance_wallet},
  ];

  final List<Map<String, dynamic>> _options = [
    {'name': 'Silver Keys', 'icon': Icons.vpn_key},
    {'name': 'Tea Cup', 'icon': Icons.local_cafe},
    {'name': 'Reading Glasses', 'icon': Icons.visibility},
    {'name': 'Golden Watch', 'icon': Icons.watch},
    {'name': 'Leather Wallet', 'icon': Icons.account_balance_wallet},
    {'name': 'Fountain Pen', 'icon': Icons.create},
  ];

  final Set<String> _selectedItems = {};
  bool _inIntermediaryTask = false;
  double? _scorePercentage;

  @override
  void initState() {
    super.initState();
    _engine = ExerciseEngine();
  }

  void _startStudy() {
    setState(() {
      _engine.startStudy();
    });
  }

  void _proceedToDistractor() {
    setState(() {
      _inIntermediaryTask = true;
    });
  }

  void _proceedToDelayedRecall() {
    setState(() {
      _inIntermediaryTask = false;
      _engine.startRecall();
    });
  }

  void _toggleOption(String name) {
    if (_engine.phase != ExercisePhase.recall) return;
    setState(() {
      if (_selectedItems.contains(name)) {
        _selectedItems.remove(name);
      } else {
        if (_selectedItems.length < _targetItems.length) {
          _selectedItems.add(name);
        }
      }
    });
  }

  Future<void> _submit(AppState appState) async {
    final targetNames = _targetItems.map((e) => e['name'] as String).toSet();
    int correctCount = 0;
    for (final sel in _selectedItems) {
      if (targetNames.contains(sel)) {
        correctCount++;
      }
    }

    final double maxScore = targetNames.length.toDouble();
    final double rawScore = correctCount.toDouble();
    final double pct = (rawScore / maxScore) * 100.0;

    await _engine.finishAndLogAttempt(
      appState: appState,
      domain: ExerciseDomain.universalCognitive,
      type: ExerciseType.sequenceRecall,
      exerciseId: 'delayed_recall_v1',
      responseMode: 'delayed_choice',
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
          'Delayed Recall',
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
                  const Icon(Icons.history_toggle_off, color: AppColors.sageSecondary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Memorize items, complete a brief distractor activity, then recall the items later.',
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
                      const Icon(Icons.timer, size: 56, color: AppColors.terracottaPrimary),
                      const SizedBox(height: 16),
                      Text(
                        'Delayed Memory Retention',
                        style: GoogleFonts.newsreader(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoalText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'First, memorize 3 personal everyday items. You will recall them after a short delay.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 16,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _startStudy,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracottaPrimary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Memorize 3 Items',
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
            ] else if (_engine.phase == ExercisePhase.study) ...[
              if (!_inIntermediaryTask) ...[
                Text(
                  'Memorize these 3 items carefully:',
                  style: GoogleFonts.newsreader(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoalText,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: _targetItems.map((item) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.terracottaPrimary),
                        ),
                        child: Column(
                          children: [
                            Icon(item['icon'] as IconData, size: 40, color: AppColors.terracottaPrimary),
                            const SizedBox(height: 8),
                            Text(
                              item['name'] as String,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _proceedToDistractor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracottaPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'I Have Memorized Them',
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ] else ...[
                // Intermediary task
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
                        const Icon(Icons.extension, size: 48, color: AppColors.sageSecondary),
                        const SizedBox(height: 16),
                        Text(
                          'Short Intermediate Delay',
                          style: GoogleFonts.newsreader(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoalText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Quick mental check before recall:\nWhat day of the week is today?',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 16,
                            color: AppColors.charcoalText,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _proceedToDelayedRecall,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sageSecondary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Proceed to Delayed Recall',
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
            ] else if (_engine.phase == ExercisePhase.recall) ...[
              Text(
                'What were the 3 objects you saw earlier?',
                style: GoogleFonts.newsreader(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoalText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select exactly 3 items (${_selectedItems.length}/3 chosen)',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 15,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                itemCount: _options.length,
                itemBuilder: (context, idx) {
                  final opt = _options[idx];
                  final name = opt['name'] as String;
                  final isSelected = _selectedItems.contains(name);

                  return GestureDetector(
                    onTap: () => _toggleOption(name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.terracottaPrimary.withValues(alpha: 0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.terracottaPrimary
                              : AppColors.sandalwoodGold.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            opt['icon'] as IconData,
                            color: isSelected ? AppColors.terracottaPrimary : AppColors.secondaryText,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: AppColors.charcoalText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _selectedItems.length == 3 ? () => _submit(appState) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracottaPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Submit Delayed Recall',
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
                        'Delayed Recall Completed!',
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
                        'Delayed recall exercises strengthen long-term episodic memory pathways.',
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
