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
import '../widgets/dice_3d_widget.dart';
import '../widgets/difficulty_selector.dart';
import 'main_screen.dart';

enum DicePhase {
  ready,
  preview,
  recall,
  summary,
}

class DiceMemoryScreen extends StatefulWidget {
  const DiceMemoryScreen({super.key});

  @override
  State<DiceMemoryScreen> createState() => _DiceMemoryScreenState();
}

class _DiceMemoryScreenState extends State<DiceMemoryScreen> {
  GameDifficulty _difficulty = GameDifficulty.easy;
  DicePhase _phase = DicePhase.ready;

  late MemorySession<DiceSessionData> _session;
  int _secondsLeft = 0;
  Timer? _countdownTimer;
  final Stopwatch _stopwatch = Stopwatch();

  // Question State
  int _currentQuestionIndex = 0;
  final Map<String, dynamic> _userAnswers = {};
  int _mistakes = 0;
  SessionEvaluationResult? _evalResult;

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
    _session = MemorySessionGenerator.generateDiceSession(_difficulty);
    _phase = DicePhase.ready;
    _secondsLeft = _session.timingParams.previewSeconds;
    _currentQuestionIndex = 0;
    _userAnswers.clear();
    _mistakes = 0;
    _evalResult = null;
    setState(() {});
  }

  void _startObservation() {
    SoundService.playTap();
    setState(() {
      _phase = DicePhase.preview;
      _secondsLeft = _session.timingParams.previewSeconds;
    });

    SoundService.speak('Observe the numbers on the tabletop dice.');

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
      _phase = DicePhase.recall;
      _currentQuestionIndex = 0;
      _stopwatch.reset();
      _stopwatch.start();
    });
    SoundService.speak('The dice are covered. Answer the recall questions.');
  }

  void _onAnswerSelected(dynamic choice) async {
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
      });
    } else {
      _finishSession();
    }
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
        _phase = DicePhase.summary;
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
              screenLabel: '3D Dice Memory',
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
                    _buildTabletopArea(fontScale),
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

  Widget _buildTabletopArea(double fontScale) {
    final diceValues = _session.stimulus.diceValues;
    final positions = _session.stimulus.positions;
    final isFaceUp = _phase == DicePhase.preview;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200, maxHeight: 240),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0.0, -0.2),
          radius: 1.2,
          colors: [
            Color(0xFF386641), // Deep Felt Tabletop
            Color(0xFF1E3A24),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sandalwoodGold, width: 2.0),
        boxShadow: const [
          BoxShadow(color: Color(0x18000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tabletop felt watermark
          Text(
            'TABLETOP MEMORY',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 14 * fontScale,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          // Dice Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(diceValues.length, (i) {
                final pos = i < positions.length ? positions[i] : null;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Dice3DWidget(
                    value: diceValues[i],
                    isFaceUp: isFaceUp,
                    size: 64.0,
                    tiltX: pos?.tiltX ?? 0.15,
                    tiltY: pos?.tiltY ?? -0.12,
                    rotationZ: pos?.rotationZ ?? 0.05,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractivePanel(double fontScale) {
    switch (_phase) {
      case DicePhase.ready:
        return _buildReadyCard(fontScale);
      case DicePhase.preview:
        return _buildPreviewCard(fontScale);
      case DicePhase.recall:
        return _buildRecallCard(fontScale);
      case DicePhase.summary:
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
            'Memory Stimulus Challenge',
            style: GoogleFonts.newsreader(
              fontSize: 20 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoalText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You will observe ${_session.stimulus.diceValues.length} dice on the tabletop for ${_session.timingParams.previewSeconds} seconds. Remember their numbers, positions, and order.',
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
            'Memorize the Numbers & Order',
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
                'Recall Phase',
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
          // Options List
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
      ),
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
            child: const Icon(Icons.check_circle_rounded, color: AppColors.sageSecondary, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            'Session Complete!',
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
              _buildMetricPill('Spatial', '${((result?.spatialRecallScore ?? 1.0) * 100).toInt()}%', fontScale),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _startNewSession,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              'Play Another Session',
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
