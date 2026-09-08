import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_difficulty.dart';
import '../providers/app_state.dart';
import '../services/session_engine/memory_session.dart';
import '../services/session_engine/memory_session_generator.dart';
import '../services/session_engine/memory_scoring_engine.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/difficulty_selector.dart';
import 'main_screen.dart';

enum WordGamePhase {
  ready,
  preview,
  recall,
  summary,
}

class WordMemoryPuzzleScreen extends StatefulWidget {
  const WordMemoryPuzzleScreen({super.key});

  @override
  State<WordMemoryPuzzleScreen> createState() => _WordMemoryPuzzleScreenState();
}

class _WordMemoryPuzzleScreenState extends State<WordMemoryPuzzleScreen> {
  GameDifficulty _difficulty = GameDifficulty.easy;
  WordGamePhase _phase = WordGamePhase.ready;

  late MemorySession<WordPuzzleSessionData> _session;
  int _secondsLeft = 0;
  Timer? _countdownTimer;
  final Stopwatch _stopwatch = Stopwatch();

  // Question State
  int _currentQuestionIndex = 0;
  final Map<String, dynamic> _userAnswers = {};
  int _mistakes = 0;
  SessionEvaluationResult? _evalResult;

  // Interactive Reorder State (for ordering questions)
  List<String> _userOrderItems = [];

  @override
  void initState() {
    super.initState();
    _startNewSession();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startNewSession() {
    _countdownTimer?.cancel();
    _session = MemorySessionGenerator.generateWordPuzzleSession(_difficulty);
    _phase = WordGamePhase.ready;
    _secondsLeft = _session.timingParams.previewSeconds;
    _currentQuestionIndex = 0;
    _userAnswers.clear();
    _mistakes = 0;
    _evalResult = null;
    _userOrderItems = [];
    setState(() {});
  }

  void _startObservation() {
    SoundService.playTap();
    setState(() {
      _phase = WordGamePhase.preview;
      _secondsLeft = _session.timingParams.previewSeconds;
    });

    SoundService.speak('Memorize the words and their sequence.');

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
        _startRecall();
      }
    });
  }

  void _startRecall() {
    SoundService.playSuccess();
    setState(() {
      _phase = WordGamePhase.recall;
      _currentQuestionIndex = 0;
      _initCurrentQuestion();
      _stopwatch.reset();
      _stopwatch.start();
    });
    SoundService.speak('The words are hidden. Answer the memory questions.');
  }

  void _initCurrentQuestion() {
    if (_currentQuestionIndex < _session.questions.length) {
      final q = _session.questions[_currentQuestionIndex];
      if (q.type == QuestionType.ordering) {
        _userOrderItems = List<String>.from(q.options);
      }
    }
  }

  void _onAnswerSelected(dynamic choice) {
    SoundService.playTap();
    final q = _session.questions[_currentQuestionIndex];
    final isCorrect = q.isCorrect(choice);
    _userAnswers[q.id] = choice;

    if (!isCorrect) {
      _mistakes++;
      SoundService.playError();
    } else {
      SoundService.playSuccess();
    }

    if (_currentQuestionIndex < _session.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _initCurrentQuestion();
      });
    } else {
      _finishSession();
    }
  }

  void _onConfirmOrder() {
    _onAnswerSelected(List<String>.from(_userOrderItems));
  }

  void _finishSession() async {
    _stopwatch.stop();
    final result = await MemoryScoringEngine.evaluateQuestionSession(
      session: _session,
      userAnswers: _userAnswers,
      timeTakenMs: _stopwatch.elapsedMilliseconds,
      mistakes: _mistakes,
    );

    if (mounted) {
      setState(() {
        _evalResult = result;
        _phase = WordGamePhase.summary;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final fontScale = appState.fontScale;

    return Scaffold(
      backgroundColor: AppColors.canvasIvory,
      body: SafeArea(
        child: Column(
          children: [
            const SmritiAppBar(
              screenLabel: 'Word Memory Puzzle',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: DifficultySelector(
                selected: _difficulty,
                onChanged: (newDiff) {
                  setState(() {
                    _difficulty = newDiff;
                    _startNewSession();
                  });
                },
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    _buildCardsArea(fontScale),
                    const SizedBox(height: 16),
                    _buildInteractivePanel(fontScale),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsArea(double fontScale) {
    final targetWords = _session.stimulus.targetWords;
    final isPreview = _phase == WordGamePhase.preview;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sandalwoodGold, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'WORD SEQUENCE DECK',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.terracottaSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${targetWords.length} Words',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 11 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.terracottaPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Word Cards Flow
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(targetWords.length, (idx) {
              final item = targetWords[idx];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isPreview ? Colors.white : const Color(0xFFEBE6DD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPreview ? AppColors.terracottaPrimary : AppColors.borderSubtle,
                    width: isPreview ? 1.5 : 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isPreview ? AppColors.terracottaSoft : const Color(0xFFD6D0C4),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 11 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: isPreview ? AppColors.terracottaPrimary : AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPreview ? item.word : '••••••',
                      style: GoogleFonts.newsreader(
                        fontSize: 16 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: isPreview ? AppColors.charcoalText : AppColors.secondaryText,
                        letterSpacing: isPreview ? 0.5 : 2.0,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractivePanel(double fontScale) {
    switch (_phase) {
      case WordGamePhase.ready:
        return _buildReadyCard(fontScale);
      case WordGamePhase.preview:
        return _buildPreviewCard(fontScale);
      case WordGamePhase.recall:
        return _buildRecallCard(fontScale);
      case WordGamePhase.summary:
        return _buildSummaryCard(fontScale);
    }
  }

  Widget _buildReadyCard(double fontScale) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Text(
            'Ready to Begin?',
            style: GoogleFonts.newsreader(
              fontSize: 20 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoalText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You will observe ${_session.stimulus.targetWords.length} familiar everyday words for ${_session.timingParams.previewSeconds} seconds. Retain the exact sequence in your mind.',
            textAlign: TextAlign.center,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 14 * fontScale,
              color: AppColors.secondaryText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _startObservation,
            icon: const Icon(Icons.play_circle_fill_rounded),
            label: Text(
              'Start Memorizing (${_session.timingParams.previewSeconds}s)',
              style: TextStyle(fontSize: 15 * fontScale, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracottaPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(double fontScale) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.terracottaPrimary),
      ),
      child: Column(
        children: [
          Text(
            'Memorize the Words in Order',
            style: GoogleFonts.newsreader(
              fontSize: 18 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.terracottaPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$_secondsLeft',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 48 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.terracottaPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Seconds Remaining',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 13 * fontScale,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecallCard(double fontScale) {
    if (_currentQuestionIndex >= _session.questions.length) return const SizedBox.shrink();
    final q = _session.questions[_currentQuestionIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Question ${_currentQuestionIndex + 1} of ${_session.questions.length}',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.terracottaPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Sequential Memory',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 12 * fontScale,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            q.prompt,
            style: GoogleFonts.newsreader(
              fontSize: 18 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoalText,
            ),
          ),
          const SizedBox(height: 16),
          if (q.type == QuestionType.ordering) ...[
            _buildOrderingUI(fontScale),
          ] else ...[
            // Standard choices
            Column(
              children: q.options.map((opt) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _onAnswerSelected(opt),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.charcoalText,
                        side: const BorderSide(color: AppColors.borderSubtle, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text(
                        opt,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 15 * fontScale,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderingUI(double fontScale) {
    return Column(
      children: [
        ...List.generate(_userOrderItems.length, (idx) {
          final word = _userOrderItems[idx];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceCream,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.sandalwoodGold),
            ),
            child: Row(
              children: [
                Text(
                  '${idx + 1}.',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontWeight: FontWeight.bold,
                    color: AppColors.terracottaPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    word,
                    style: GoogleFonts.newsreader(
                      fontSize: 16 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoalText,
                    ),
                  ),
                ),
                if (idx > 0)
                  IconButton(
                    icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() {
                        final temp = _userOrderItems[idx];
                        _userOrderItems[idx] = _userOrderItems[idx - 1];
                        _userOrderItems[idx - 1] = temp;
                      });
                    },
                  ),
                if (idx < _userOrderItems.length - 1)
                  IconButton(
                    icon: const Icon(Icons.arrow_downward_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() {
                        final temp = _userOrderItems[idx];
                        _userOrderItems[idx] = _userOrderItems[idx + 1];
                        _userOrderItems[idx + 1] = temp;
                      });
                    },
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _onConfirmOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.terracottaPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            'Confirm Word Order',
            style: TextStyle(fontSize: 15 * fontScale, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(double fontScale) {
    final result = _evalResult;
    final score = result?.scorePct.toInt() ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sageSecondary),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sageSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_rounded, color: AppColors.sageSecondary, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            'Word Puzzle Complete!',
            style: GoogleFonts.newsreader(
              fontSize: 22 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoalText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Overall Accuracy: $score%',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 18 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.sageSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricPill('Item Recall', '${((result?.itemRecallScore ?? 1.0) * 100).toInt()}%', fontScale),
              _buildMetricPill('Sequence', '${((result?.sequenceRecallScore ?? 1.0) * 100).toInt()}%', fontScale),
              _buildMetricPill('Attention', '${((result?.attentionScore ?? 1.0) * 100).toInt()}%', fontScale),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _startNewSession,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              'Play Another Word Session',
              style: TextStyle(fontSize: 15 * fontScale, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracottaPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Return to Practice',
              style: TextStyle(fontSize: 14 * fontScale, color: AppColors.secondaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, double fontScale) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 16 * fontScale,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoalText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 11 * fontScale,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}
