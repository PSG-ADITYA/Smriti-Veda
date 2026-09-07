import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_overlay.dart';

class MemoryStory {
  final String title;
  final String region;
  final String body;
  final List<Map<String, dynamic>> questions;

  const MemoryStory({
    required this.title,
    required this.region,
    required this.body,
    required this.questions,
  });
}

const List<MemoryStory> kMemoryStories = [
  MemoryStory(
    title: 'Morning in the Jorhat Tea Gardens',
    region: 'Assam & North East',
    body: 'At sunrise, grandfather Bhupen walked through the fragrant green tea slopes of Jorhat. '
        'He heard a hill myna chirping from a tall bamboo grove. '
        'At the garden gate, he met his old schoolmate Dhiren and shared a steaming brass cup of cardamom tea '
        'before returning home with fresh sweet jaggery.',
    questions: [
      {
        'question': 'Where was grandfather Bhupen walking at sunrise?',
        'options': ['Tea slopes of Jorhat', 'Railway station', 'Busy city market', 'River ferry'],
        'correctIdx': 0,
      },
      {
        'question': 'What kind of bird did he hear chirping?',
        'options': ['Peacock', 'Hill Myna', 'Sparrow', 'Pigeon'],
        'correctIdx': 1,
      },
      {
        'question': 'What did he share with his schoolmate Dhiren?',
        'options': ['Cardamom tea', 'Coconut water', 'Sugarcane juice', 'Lassi'],
        'correctIdx': 0,
      },
      {
        'question': 'What did he bring home at the end of the walk?',
        'options': ['Fresh sweet jaggery', 'Bamboo basket', 'Newspaper', 'Flowers'],
        'correctIdx': 0,
      },
    ],
  ),
  MemoryStory(
    title: 'The Rongali Bihu Silk Gamosa',
    region: 'Assamese Heritage',
    body: 'Before the spring Bihu festival, grandmother Manorama sat by the wooden loom under the shaded jackfruit tree. '
        'She wove a white and red cotton gamosa with woven floral patterns. '
        'Her seven-year-old grandson Ankur brought her a bowl of roasted puffed rice. '
        'In the afternoon, the village dhol drummers passed by playing rhythmic festival beats.',
    questions: [
      {
        'question': 'Under which tree did grandmother sit with her loom?',
        'options': ['Neem tree', 'Jackfruit tree', 'Banyan tree', 'Pine tree'],
        'correctIdx': 1,
      },
      {
        'question': 'What colors were used for the traditional gamosa?',
        'options': ['White and red', 'Blue and yellow', 'Green and gold', 'Purple and black'],
        'correctIdx': 0,
      },
      {
        'question': 'What snack did grandson Ankur bring to her?',
        'options': ['Roasted puffed rice', 'Sweet laddu', 'Cut papayas', 'Biscuits'],
        'correctIdx': 0,
      },
      {
        'question': 'What traditional instrument did the village drummers play?',
        'options': ['Dhol', 'Flute', 'Tabla', 'Harmonium'],
        'correctIdx': 0,
      },
    ],
  ),
  MemoryStory(
    title: 'Sunset at Shillong Pine Lake',
    region: 'Meghalaya & Hills',
    body: 'On a cool autumn evening, uncle Subroto visited the tranquil waters of Ward\'s Lake in Shillong. '
        'Yellow pine leaves floated near the curved wooden bridge. '
        'He watched white ducks paddling across the water while enjoying a warm roasted corn cob seasoned with lemon. '
        'The church bells rang six times as dusk settled over the hills.',
    questions: [
      {
        'question': 'Which lake did uncle Subroto visit in Shillong?',
        'options': ['Ward\'s Lake', 'Dal Lake', 'Chilika Lake', 'Hussain Sagar'],
        'correctIdx': 0,
      },
      {
        'question': 'What floating near the wooden bridge caught his eye?',
        'options': ['Yellow pine leaves', 'Paper boats', 'Red roses', 'Water lilies'],
        'correctIdx': 0,
      },
      {
        'question': 'What evening snack did he enjoy by the water?',
        'options': ['Roasted corn with lemon', 'Samosa', 'Momos', 'Peanuts'],
        'correctIdx': 0,
      },
      {
        'question': 'How many times did the church bells ring at dusk?',
        'options': ['Six times', 'Four times', 'Ten times', 'Twelve times'],
        'correctIdx': 0,
      },
    ],
  ),
];

enum StoryPhase {
  reading,
  quiz,
  summary,
}

class StoryMemoryScreen extends StatefulWidget {
  const StoryMemoryScreen({super.key});

  @override
  State<StoryMemoryScreen> createState() => _StoryMemoryScreenState();
}

class _StoryMemoryScreenState extends State<StoryMemoryScreen> {
  int _storyIndex = 0;
  StoryPhase _phase = StoryPhase.reading;
  bool _isSpeaking = false;
  final Map<int, int> _userAnswers = {};
  final Stopwatch _stopwatch = Stopwatch();
  double _scorePct = 0.0;

  MemoryStory get _currentStory => kMemoryStories[_storyIndex];

  @override
  void initState() {
    super.initState();
    _loadStory();
  }

  @override
  void dispose() {
    SoundService.stop();
    super.dispose();
  }

  void _loadStory() {
    SoundService.stop();
    _phase = StoryPhase.reading;
    _isSpeaking = false;
    _userAnswers.clear();
    _stopwatch.reset();
    _stopwatch.start();
    setState(() {});
  }

  void _toggleSpeak() {
    if (_isSpeaking) {
      SoundService.stop();
      setState(() => _isSpeaking = false);
    } else {
      SoundService.speak('${_currentStory.title}. ${_currentStory.body}');
      setState(() => _isSpeaking = true);
    }
  }

  void _startQuiz() {
    SoundService.stop();
    SoundService.playTap();
    setState(() {
      _isSpeaking = false;
      _phase = StoryPhase.quiz;
    });
  }

  void _selectAnswer(int qIdx, int optIdx) {
    if (_phase != StoryPhase.quiz) return;
    SoundService.playTap();
    setState(() {
      _userAnswers[qIdx] = optIdx;
    });
  }

  Future<void> _submitQuiz(AppState appState) async {
    _stopwatch.stop();

    int correct = 0;
    for (int i = 0; i < _currentStory.questions.length; i++) {
      if (_userAnswers[i] == _currentStory.questions[i]['correctIdx']) {
        correct++;
      }
    }

    final double maxScore = _currentStory.questions.length.toDouble();
    final double rawScore = correct.toDouble();
    _scorePct = (rawScore / maxScore) * 100.0;

    setState(() {
      _phase = StoryPhase.summary;
    });

    if (_scorePct >= 65.0) {
      SoundService.playFanfare();
      if (mounted) {
        ConfettiOverlay.show(
          context,
          title: 'Great Auditory Recall! 📖',
          subtitle: 'Answered $correct of ${_currentStory.questions.length} questions correctly!',
        );
      }
    } else {
      SoundService.playError();
    }

    // Log attempt into repository
    await appState.attemptRepository.logAttempt(
      ExerciseAttempt(
        id: 'att_story_${DateTime.now().millisecondsSinceEpoch}',
        userId: appState.credentialId,
        domain: ExerciseDomain.universalCognitive,
        cognitiveDomain: CognitiveDomain.auditoryRecall,
        type: ExerciseType.storyMemory,
        exerciseId: 'story_memory_idx_${_storyIndex + 1}',
        responseMode: 'choice',
        rawScore: rawScore,
        maxScore: maxScore,
        timeTakenMs: _stopwatch.elapsedMilliseconds,
      ),
    );
  }

  void _nextStoryOrReset() {
    if (_storyIndex < kMemoryStories.length - 1) {
      _storyIndex++;
    } else {
      _storyIndex = 0;
    }
    _loadStory();
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
          'Story Recall Exercise',
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
              color: AppColors.sageSecondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.record_voice_over_rounded, size: 16, color: AppColors.sageSecondary),
                const SizedBox(width: 4),
                Text(
                  'Auditory Recall',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoalText,
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
              // Story Card Header
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
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.terracottaPrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _currentStory.region.toUpperCase(),
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 10 * fontScale,
                              fontWeight: FontWeight.bold,
                              color: AppColors.terracottaPrimary,
                            ),
                          ),
                        ),
                        Text(
                          'STORY ${_storyIndex + 1} OF ${kMemoryStories.length}',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 11 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentStory.title,
                      style: GoogleFonts.newsreader(
                        fontSize: 20 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoalText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Phase 1: Reading & Listening
              if (_phase == StoryPhase.reading) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentStory.body,
                        style: GoogleFonts.newsreader(
                          fontSize: 18 * fontScale,
                          height: 1.6,
                          color: AppColors.charcoalText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // TTS audio prompter
                      ElevatedButton.icon(
                        onPressed: _toggleSpeak,
                        icon: Icon(_isSpeaking ? Icons.pause_rounded : Icons.volume_up_rounded, size: 22),
                        label: Text(
                          _isSpeaking ? 'Pause Story Audio' : 'Listen to Story Narration (TTS)',
                          style: GoogleFonts.atkinsonHyperlegible(fontSize: 14 * fontScale, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sageSecondary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _startQuiz,
                  icon: const Icon(Icons.quiz_rounded, size: 22),
                  label: Text(
                    'I Am Ready ➔ Start Recall Questions',
                    style: GoogleFonts.atkinsonHyperlegible(fontSize: 16 * fontScale, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracottaPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],

              // Phase 2: Quiz
              if (_phase == StoryPhase.quiz) ...[
                Text(
                  'COMPREHENSION & EPISODIC RECALL:',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.charcoalText,
                  ),
                ),
                const SizedBox(height: 10),
                Column(
                  children: List.generate(_currentStory.questions.length, (qIdx) {
                    final q = _currentStory.questions[qIdx];
                    final selectedOpt = _userAnswers[qIdx];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${qIdx + 1}. ${q['question']}',
                            style: GoogleFonts.newsreader(
                              fontSize: 16 * fontScale,
                              fontWeight: FontWeight.bold,
                              color: AppColors.charcoalText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Column(
                            children: List.generate((q['options'] as List).length, (optIdx) {
                              final isSelected = selectedOpt == optIdx;
                              return GestureDetector(
                                onTap: () => _selectAnswer(qIdx, optIdx),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.terracottaPrimary.withOpacity(0.12) : AppColors.canvasIvory,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? AppColors.terracottaPrimary : Colors.black12,
                                      width: isSelected ? 1.8 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                        color: isSelected ? AppColors.terracottaPrimary : Colors.black38,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          q['options'][optIdx],
                                          style: GoogleFonts.atkinsonHyperlegible(
                                            fontSize: 14 * fontScale,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: AppColors.charcoalText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _userAnswers.length == _currentStory.questions.length
                      ? () => _submitQuiz(appState)
                      : null,
                  icon: const Icon(Icons.check_circle_outline, size: 22),
                  label: Text(
                    'Check Recall Answers',
                    style: GoogleFonts.atkinsonHyperlegible(fontSize: 16 * fontScale, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sageSecondary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],

              // Phase 3: Summary
              if (_phase == StoryPhase.summary) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.terracottaPrimary),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Recall Score: ${_scorePct.toInt()}%',
                        style: GoogleFonts.newsreader(
                          fontSize: 22 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: AppColors.terracottaPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your Auditory Recall and Comprehension performance has been recorded.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.atkinsonHyperlegible(fontSize: 13 * fontScale, color: AppColors.secondaryText),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _loadStory,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Read Again'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _nextStoryOrReset,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.terracottaPrimary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                _storyIndex < kMemoryStories.length - 1 ? 'Next Story ➔' : 'Restart Story 1',
                                style: GoogleFonts.atkinsonHyperlegible(fontSize: 14 * fontScale, fontWeight: FontWeight.bold),
                              ),
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
      ),
    );
  }
}
