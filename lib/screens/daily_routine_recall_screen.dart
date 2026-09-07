import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_overlay.dart';

class RoutineRecallStep {
  final int correctOrder;
  final String title;
  final String timeText;
  final IconData icon;
  final String tip;

  const RoutineRecallStep({
    required this.correctOrder,
    required this.title,
    required this.timeText,
    required this.icon,
    required this.tip,
  });
}

class RoutineScenario {
  final String title;
  final String subtitle;
  final List<RoutineRecallStep> steps;

  const RoutineScenario({
    required this.title,
    required this.subtitle,
    required this.steps,
  });
}

const List<RoutineScenario> kRoutineScenarios = [
  RoutineScenario(
    title: 'Morning Wellness & Medicine Routine',
    subtitle: 'Put the morning steps in their healthy chronological order.',
    steps: [
      RoutineRecallStep(
        correctOrder: 1,
        title: 'Wake Up & Deep Breathing',
        timeText: '06:30 AM',
        icon: Icons.wb_sunny_rounded,
        tip: 'Start the day calmly with fresh air.',
      ),
      RoutineRecallStep(
        correctOrder: 2,
        title: 'Drink Warm Water / Herbal Tea',
        timeText: '07:00 AM',
        icon: Icons.local_drink_rounded,
        tip: 'Hydration supports circulation and focus.',
      ),
      RoutineRecallStep(
        correctOrder: 3,
        title: 'Morning Medicine & Light Stretch',
        timeText: '07:30 AM',
        icon: Icons.medication_rounded,
        tip: 'Take prescribed morning blood pressure/sugar dose.',
      ),
      RoutineRecallStep(
        correctOrder: 4,
        title: 'Wholesome Breakfast & Family Chat',
        timeText: '08:30 AM',
        icon: Icons.restaurant_rounded,
        tip: 'Nourish energy with porridge or idli/roti.',
      ),
    ],
  ),
  RoutineScenario(
    title: 'Afternoon & Active Engagement Routine',
    subtitle: 'Order the afternoon wellness and memory habits.',
    steps: [
      RoutineRecallStep(
        correctOrder: 1,
        title: 'Healthy Lunch with Greens',
        timeText: '01:00 PM',
        icon: Icons.lunch_dining_rounded,
        tip: 'Warm, easy-to-digest meal.',
      ),
      RoutineRecallStep(
        correctOrder: 2,
        title: 'Gentle Afternoon Rest / Nap',
        timeText: '02:00 PM',
        icon: Icons.bed_rounded,
        tip: '20-30 minutes quiet rest rejuvenates memory.',
      ),
      RoutineRecallStep(
        correctOrder: 3,
        title: 'Daily Cognitive Practice on Smriti Veda',
        timeText: '03:30 PM',
        icon: Icons.psychology_rounded,
        tip: 'Play Fruit Memory Path or Sequence Recall.',
      ),
      RoutineRecallStep(
        correctOrder: 4,
        title: 'Hydration & Evening Tea / Snack',
        timeText: '04:30 PM',
        icon: Icons.coffee_rounded,
        tip: 'Herbal ginger tea or fresh fruit slices.',
      ),
      RoutineRecallStep(
        correctOrder: 5,
        title: 'Garden Walk / Balcony Sunlight',
        timeText: '05:30 PM',
        icon: Icons.nature_people_rounded,
        tip: 'Gentle steps to maintain balance.',
      ),
    ],
  ),
  RoutineScenario(
    title: 'Evening & Night Rest Routine',
    subtitle: 'Sequence the tranquil evening wind-down steps.',
    steps: [
      RoutineRecallStep(
        correctOrder: 1,
        title: 'Family Phone Call or Reading',
        timeText: '06:30 PM',
        icon: Icons.phone_in_talk_rounded,
        tip: 'Connect with grandchildren or read a devotional poem.',
      ),
      RoutineRecallStep(
        correctOrder: 2,
        title: 'Light Dinner Before Sunset',
        timeText: '07:30 PM',
        icon: Icons.soup_kitchen_rounded,
        tip: 'Warm soup, khichdi, or steamed food.',
      ),
      RoutineRecallStep(
        correctOrder: 3,
        title: 'Night Medicine Check & Water',
        timeText: '08:30 PM',
        icon: Icons.medical_services_rounded,
        tip: 'Verify bedtime medicines are taken.',
      ),
      RoutineRecallStep(
        correctOrder: 4,
        title: 'Peaceful Sleep in Dark Quiet Room',
        timeText: '10:00 PM',
        icon: Icons.nightlight_round,
        tip: 'Ensure comfortable temperature and safety night-light.',
      ),
    ],
  ),
];

class DailyRoutineRecallScreen extends StatefulWidget {
  const DailyRoutineRecallScreen({super.key});

  @override
  State<DailyRoutineRecallScreen> createState() => _DailyRoutineRecallScreenState();
}

class _DailyRoutineRecallScreenState extends State<DailyRoutineRecallScreen> {
  int _scenarioIndex = 0;
  late List<RoutineRecallStep> _shuffledSteps;
  final List<RoutineRecallStep> _selectedOrder = [];
  bool _isSubmitted = false;
  double _score = 0.0;
  final Stopwatch _stopwatch = Stopwatch();

  RoutineScenario get _currentScenario => kRoutineScenarios[_scenarioIndex];

  @override
  void initState() {
    super.initState();
    _loadScenario();
  }

  void _loadScenario() {
    _shuffledSteps = List<RoutineRecallStep>.from(_currentScenario.steps)..shuffle();
    _selectedOrder.clear();
    _isSubmitted = false;
    _score = 0.0;
    _stopwatch.reset();
    _stopwatch.start();
    setState(() {});
  }

  void _tapStep(RoutineRecallStep step) {
    if (_isSubmitted) return;
    SoundService.playTap();

    setState(() {
      if (_selectedOrder.contains(step)) {
        _selectedOrder.remove(step);
      } else {
        _selectedOrder.add(step);
      }
    });
  }

  Future<void> _submit(AppState appState) async {
    _stopwatch.stop();
    int correctMatches = 0;
    for (int i = 0; i < _selectedOrder.length; i++) {
      if (_selectedOrder[i].correctOrder == i + 1) {
        correctMatches++;
      }
    }

    final totalExpected = _currentScenario.steps.length;
    final percentage = totalExpected > 0 ? (correctMatches / totalExpected * 100.0) : 0.0;

    setState(() {
      _isSubmitted = true;
      _score = percentage;
    });

    if (percentage >= 70.0) {
      SoundService.playFanfare();
      if (mounted) {
        ConfettiOverlay.show(
          context,
          title: 'Routine Mastered! ⏰',
          subtitle: 'You arranged the steps in ideal chronological order ($correctMatches of $totalExpected correct)!',
        );
      }
    } else {
      SoundService.playError();
    }

    // Log attempt into repository
    await appState.attemptRepository.logAttempt(
      ExerciseAttempt(
        id: 'att_routine_${DateTime.now().millisecondsSinceEpoch}',
        userId: appState.credentialId,
        domain: ExerciseDomain.everydayMemory,
        cognitiveDomain: CognitiveDomain.prospectiveMemory,
        type: ExerciseType.dailyRoutineRecall,
        exerciseId: 'routine_scenario_${_scenarioIndex + 1}',
        responseMode: 'choice',
        rawScore: correctMatches.toDouble(),
        maxScore: totalExpected.toDouble(),
        timeTakenMs: _stopwatch.elapsedMilliseconds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final fontScale = appState.fontScale;

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
          'Daily Routine Recall',
          style: GoogleFonts.newsreader(
            fontSize: 20 * fontScale,
            fontWeight: FontWeight.bold,
            color: AppColors.terracottaPrimary,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.terracottaPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled_rounded, size: 16, color: AppColors.terracottaPrimary),
                const SizedBox(width: 4),
                Text(
                  'Prospective Memory',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.terracottaPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scenario Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sandalwoodGold.withOpacity(0.4)),
                  boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SCENARIO ${_scenarioIndex + 1} OF ${kRoutineScenarios.length}',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 11 * fontScale,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppColors.terracottaPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentScenario.title,
                      style: GoogleFonts.newsreader(
                        fontSize: 18 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoalText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentScenario.subtitle,
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 13 * fontScale,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Selected Ordering Tray
              Text(
                'YOUR CHOSEN ORDER (${_selectedOrder.length} of ${_currentScenario.steps.length}):',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 12 * fontScale,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.charcoalText,
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedOrder.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12, style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: Text(
                      'Tap the activities below in the order they should happen.',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 13 * fontScale,
                        fontStyle: FontStyle.italic,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: List.generate(_selectedOrder.length, (idx) {
                    final step = _selectedOrder[idx];
                    final isCorrect = _isSubmitted && step.correctOrder == idx + 1;
                    final isWrong = _isSubmitted && step.correctOrder != idx + 1;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? AppColors.sageSecondary.withOpacity(0.15)
                            : isWrong
                                ? AppColors.terracottaPrimary.withOpacity(0.15)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCorrect
                              ? AppColors.sageSecondary
                              : isWrong
                                  ? AppColors.terracottaPrimary
                                  : AppColors.sandalwoodGold,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.terracottaPrimary,
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(step.icon, color: AppColors.charcoalText, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              step.title,
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 14 * fontScale,
                                fontWeight: FontWeight.bold,
                                color: AppColors.charcoalText,
                              ),
                            ),
                          ),
                          if (_isSubmitted)
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect ? AppColors.sageSecondary : AppColors.terracottaPrimary,
                              size: 20,
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.close, size: 18, color: Colors.black45),
                              onPressed: () => _tapStep(step),
                            ),
                        ],
                      ),
                    );
                  }),
                ),

              const SizedBox(height: 20),

              // Pool of Steps
              Text(
                'AVAILABLE ACTIVITIES (TAP TO ADD):',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 12 * fontScale,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.charcoalText,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: _shuffledSteps.map((step) {
                  final isAlreadySelected = _selectedOrder.contains(step);
                  return GestureDetector(
                    onTap: isAlreadySelected ? null : () => _tapStep(step),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isAlreadySelected ? 0.4 : 1.0,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.sandalwoodGold.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(step.icon, color: AppColors.sandalwoodGold, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.title,
                                    style: GoogleFonts.atkinsonHyperlegible(
                                      fontSize: 14 * fontScale,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.charcoalText,
                                    ),
                                  ),
                                  Text(
                                    step.tip,
                                    style: GoogleFonts.atkinsonHyperlegible(
                                      fontSize: 12 * fontScale,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.add_circle_outline, color: AppColors.terracottaPrimary),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // Action Buttons
              if (!_isSubmitted)
                ElevatedButton.icon(
                  onPressed: _selectedOrder.length == _currentScenario.steps.length
                      ? () => _submit(appState)
                      : null,
                  icon: const Icon(Icons.check_circle_outline, size: 22),
                  label: Text(
                    'Check Routine Sequence',
                    style: GoogleFonts.atkinsonHyperlegible(fontSize: 16 * fontScale, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracottaPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                )
              else
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _score >= 70.0
                            ? AppColors.sageSecondary.withOpacity(0.12)
                            : AppColors.terracottaPrimary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _score >= 70.0
                            ? 'Excellent sequencing! Score: ${_score.toInt()}%.'
                            : 'Good effort! Review the sequence numbers and try again.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 14 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: _score >= 70.0 ? AppColors.sageSecondary : AppColors.terracottaPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _loadScenario,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Try Again'),
                          ),
                        ),
                        if (_scenarioIndex < kRoutineScenarios.length - 1) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _scenarioIndex++;
                                _loadScenario();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.sageSecondary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Next Scenario'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
