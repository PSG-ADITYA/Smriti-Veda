import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/song_generation_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_overlay.dart';

enum MemoryMelodyPhase {
  intro,
  playback,
  taskItemRecall,
  taskSequenceRecall,
  taskEventOrdering,
  taskAttention,
  delayedInterlude,
  taskDelayedRecall,
  results,
}

class MemoryMelodyScreen extends StatefulWidget {
  final String? initialTheme;
  const MemoryMelodyScreen({super.key, this.initialTheme});

  @override
  State<MemoryMelodyScreen> createState() => _MemoryMelodyScreenState();
}

class _MemoryMelodyScreenState extends State<MemoryMelodyScreen> with TickerProviderStateMixin {
  MemoryMelodyPhase _phase = MemoryMelodyPhase.intro;
  bool _isLoading = false;

  SongContent? _song;
  int _currentLineIndex = 0;
  Timer? _playbackTimer;
  bool _isPlaying = false;

  // Multi-dimensional scoring
  int _itemRecallScore = 0;
  int _sequenceRecallScore = 0;
  int _eventOrderingScore = 0;
  int _attentionScore = 0;
  int _delayedRecallScore = 0;

  // Selected answers for each question
  String? _selectedItemAnswer;
  String? _selectedSequenceAnswer;
  String? _selectedAttentionAnswer;
  String? _selectedDelayedAnswer;

  // Event ordering state
  List<EventOrderStep> _userOrderedEvents = [];

  // Delayed interlude countdown
  int _interludeRemainingSeconds = 8;
  Timer? _interludeTimer;

  // Voice Speech-To-Text
  stt.SpeechToText? _speech;
  bool _isSpeechInitialized = false;
  bool _isListening = false;
  String _voiceTranscript = '';
  String? _voiceError;

  final Stopwatch _totalStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _initStt();
    _loadSong();
  }

  void _initStt() async {
    _speech = stt.SpeechToText();
    try {
      _isSpeechInitialized = await _speech!.initialize(
        onError: (val) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _voiceError = 'Voice note: ${val.errorMsg}';
            });
          }
        },
        onStatus: (val) {
          if ((val == 'done' || val == 'notListening') && _isListening && mounted) {
            setState(() => _isListening = false);
          }
        },
      );
    } catch (_) {
      _isSpeechInitialized = false;
    }
  }

  Future<void> _loadSong() async {
    setState(() => _isLoading = true);
    final songService = SongGenerationService();
    final song = await songService.generateSong(
      theme: widget.initialTheme ?? 'Morning Wellness',
      difficulty: 'Medium',
      patientName: 'Friend',
    );

    if (mounted) {
      // Shuffle events for the ordering challenge
      final shuffledEvents = List<EventOrderStep>.from(song.events)..shuffle();
      setState(() {
        _song = song;
        _userOrderedEvents = shuffledEvents;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _interludeTimer?.cancel();
    _speech?.stop();
    _isListening = false;
    SoundService.stop();
    super.dispose();
  }

  // ── Speech Recognition ─────────────────────────────────────────────────────

  void _startListening({required Function(String) onMatched}) async {
    if (!_isSpeechInitialized || _speech == null) {
      setState(() => _voiceError = "Microphone isn't available. Please tap your answer.");
      return;
    }

    setState(() {
      _isListening = true;
      _voiceError = null;
      _voiceTranscript = '';
    });

    try {
      await _speech!.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _voiceTranscript = result.recognizedWords;
            });
            onMatched(result.recognizedWords);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _voiceError = 'Could not start microphone. Please tap your answer.';
        });
      }
    }
  }

  void _stopListening() async {
    if (_speech?.isListening == true) {
      await _speech?.stop();
    }
    _isListening = false;
    if (mounted) {
      setState(() {});
    }
  }

  // ── Playback Engine ────────────────────────────────────────────────────────

  void _startPlayback() {
    if (_song == null) return;
    _totalStopwatch.start();
    SoundService.stop();

    setState(() {
      _phase = MemoryMelodyPhase.playback;
      _isPlaying = true;
      _currentLineIndex = 0;
    });

    _playLine(0);
  }

  void _playLine(int index) {
    if (!mounted || _song == null) return;
    if (index >= _song!.lines.length) {
      setState(() {
        _isPlaying = false;
      });
      return;
    }

    setState(() {
      _currentLineIndex = index;
    });

    final line = _song!.lines[index];
    SoundService.speak(line, languageCode: 'en-US');
    SoundService.playTap();

    // Line duration paced for seniors (6.0 seconds per stanza line)
    _playbackTimer?.cancel();
    _playbackTimer = Timer(const Duration(milliseconds: 6200), () {
      if (mounted && _isPlaying) {
        _playLine(index + 1);
      }
    });
  }

  void _replaySong() {
    _startPlayback();
  }

  void _proceedToTasks() {
    _playbackTimer?.cancel();
    SoundService.stop();
    setState(() {
      _isPlaying = false;
      _phase = MemoryMelodyPhase.taskItemRecall;
    });
  }

  // ── Answer Handling & Multi-Stage Scoring ──────────────────────────────────

  void _handleItemAnswer(String answer) {
    if (_song == null || _song!.questions.isEmpty) return;
    _stopListening();
    final q = _song!.questions[0];
    final isCorrect = answer.trim().toLowerCase().contains(q.correctAnswer.toLowerCase());

    setState(() {
      _selectedItemAnswer = answer;
      _itemRecallScore = isCorrect ? 100 : 40;
    });

    if (isCorrect) {
      SoundService.playSuccess();
    } else {
      SoundService.playTap();
    }

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _phase = MemoryMelodyPhase.taskSequenceRecall);
      }
    });
  }

  void _handleSequenceAnswer(String answer) {
    if (_song == null || _song!.questions.length < 2) return;
    final q = _song!.questions[1];
    final isCorrect = answer.trim().toLowerCase().contains(q.correctAnswer.toLowerCase());

    setState(() {
      _selectedSequenceAnswer = answer;
      _sequenceRecallScore = isCorrect ? 100 : 35;
    });

    if (isCorrect) {
      SoundService.playSuccess();
    } else {
      SoundService.playTap();
    }

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _phase = MemoryMelodyPhase.taskEventOrdering);
      }
    });
  }

  void _submitEventOrdering() {
    int correctCount = 0;
    for (int i = 0; i < _userOrderedEvents.length; i++) {
      if (_userOrderedEvents[i].correctOrder == (i + 1)) {
        correctCount++;
      }
    }

    final score = ((correctCount / _userOrderedEvents.length) * 100).round();
    setState(() {
      _eventOrderingScore = score;
    });

    if (score >= 75) {
      SoundService.playSuccess();
    } else {
      SoundService.playTap();
    }

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _phase = MemoryMelodyPhase.taskAttention);
      }
    });
  }

  void _handleAttentionAnswer(String answer) {
    if (_song == null || _song!.questions.length < 3) return;
    final q = _song!.questions[2];
    final isCorrect = answer.trim().toLowerCase().contains(q.correctAnswer.toLowerCase());

    setState(() {
      _selectedAttentionAnswer = answer;
      _attentionScore = isCorrect ? 100 : 30;
    });

    if (isCorrect) {
      SoundService.playSuccess();
    } else {
      SoundService.playTap();
    }

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _startDelayedInterlude();
      }
    });
  }

  void _startDelayedInterlude() {
    setState(() {
      _phase = MemoryMelodyPhase.delayedInterlude;
      _interludeRemainingSeconds = 8;
    });

    _interludeTimer?.cancel();
    _interludeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_interludeRemainingSeconds <= 1) {
        timer.cancel();
        setState(() => _phase = MemoryMelodyPhase.taskDelayedRecall);
      } else {
        setState(() => _interludeRemainingSeconds--);
      }
    });
  }

  void _handleDelayedAnswer(String answer, AppState appState) {
    if (_song == null) return;
    final q = _song!.delayedQuestion;
    final isCorrect = answer.trim().toLowerCase().contains(q.correctAnswer.toLowerCase());

    setState(() {
      _selectedDelayedAnswer = answer;
      _delayedRecallScore = isCorrect ? 100 : 40;
    });

    if (isCorrect) {
      SoundService.playSuccess();
    } else {
      SoundService.playTap();
    }

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        _finishGame(appState);
      }
    });
  }

  Future<void> _finishGame(AppState appState) async {
    _totalStopwatch.stop();
    final durationSeconds = _totalStopwatch.elapsed.inSeconds.clamp(15, 300);

    // Compute combined weighted overall score
    final double overall = (
      _itemRecallScore * 0.25 +
      _sequenceRecallScore * 0.25 +
      _eventOrderingScore * 0.20 +
      _attentionScore * 0.15 +
      _delayedRecallScore * 0.15
    );

    final finalScore = overall.round().clamp(30, 100);

    // Save Attempt with detailed sub-scores in metadata
    final attempt = ExerciseAttempt(
      id: 'melody_${DateTime.now().millisecondsSinceEpoch}',
      userId: appState.credentialId,
      domain: ExerciseDomain.universalCognitive,
      type: ExerciseType.memoryMelody,
      cognitiveDomain: CognitiveDomain.auditoryRecall,
      exerciseId: 'memory_melody_${_song?.id ?? 'default'}',
      responseMode: _voiceTranscript.isNotEmpty ? 'voice' : 'choice',
      rawScore: finalScore.toDouble(),
      maxScore: 100.0,
      timeTakenMs: _totalStopwatch.elapsedMilliseconds,
      metadata: {
        'itemRecallScore': _itemRecallScore.toDouble(),
        'sequenceRecallScore': _sequenceRecallScore.toDouble(),
        'eventOrderingScore': _eventOrderingScore.toDouble(),
        'attentionScore': _attentionScore.toDouble(),
        'delayedRecallScore': _delayedRecallScore.toDouble(),
        'songTheme': _song?.theme ?? 'Wellness',
        'durationSeconds': durationSeconds,
      },
    );

    await appState.attemptRepository.logAttempt(attempt);
    SoundService.playFanfare();
    if (mounted) {
      ConfettiOverlay.show(
        context,
        title: 'Melody Master! 🎵',
        subtitle: 'Scored $finalScore% across auditory & delayed memory tasks!',
      );
    }

    if (mounted) {
      setState(() {
        _phase = MemoryMelodyPhase.results;
      });
    }
  }

  // ── UI Builders ────────────────────────────────────────────────────────────

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
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.charcoalText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Memory Melody',
          style: GoogleFonts.newsreader(
            fontSize: 22 * fontScale,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF8F5C86), // Warm Plum
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF8F5C86)),
            tooltip: 'Audio Info',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Memory Melody combines rhythmic auditory verses with synchronized multi-stage recall.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState(fontScale)
            : _buildPhaseContent(appState, fontScale),
      ),
    );
  }

  Widget _buildLoadingState(double fontScale) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF8F5C86)),
          const SizedBox(height: 20),
          Text(
            'Preparing Melodic Memory Verse...',
            style: GoogleFonts.newsreader(
              fontSize: 18 * fontScale,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoalText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Composing regional rhymes and cognitive probes',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 14 * fontScale,
              color: AppColors.charcoalText.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseContent(AppState appState, double fontScale) {
    switch (_phase) {
      case MemoryMelodyPhase.intro:
        return _buildIntroView(fontScale);
      case MemoryMelodyPhase.playback:
        return _buildPlaybackView(fontScale);
      case MemoryMelodyPhase.taskItemRecall:
        return _buildItemRecallView(fontScale);
      case MemoryMelodyPhase.taskSequenceRecall:
        return _buildSequenceRecallView(fontScale);
      case MemoryMelodyPhase.taskEventOrdering:
        return _buildEventOrderingView(fontScale);
      case MemoryMelodyPhase.taskAttention:
        return _buildAttentionView(fontScale);
      case MemoryMelodyPhase.delayedInterlude:
        return _buildDelayedInterludeView(fontScale);
      case MemoryMelodyPhase.taskDelayedRecall:
        return _buildDelayedRecallView(appState, fontScale);
      case MemoryMelodyPhase.results:
        return _buildResultsView(fontScale);
    }
  }

  // 1. Intro View
  Widget _buildIntroView(double fontScale) {
    final song = _song!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF8F5C86).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF8F5C86).withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                const Icon(Icons.music_note_rounded, size: 54, color: Color(0xFF8F5C86)),
                const SizedBox(height: 12),
                Text(
                  song.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.newsreader(
                    fontSize: 22 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8F5C86),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8F5C86).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Theme: ${song.theme} • Auditory Recall',
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 13 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8F5C86),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildInstructionBullet(Icons.hearing_rounded, 'Listen to the 25-second melodic verse carefully.', fontScale),
          _buildInstructionBullet(Icons.menu_book_rounded, 'Remember the items mentioned, such as food or objects.', fontScale),
          _buildInstructionBullet(Icons.format_list_numbered_rounded, 'Track the order of activities that took place.', fontScale),
          _buildInstructionBullet(Icons.mic_rounded, 'You can speak your answers or simply tap the screen.', fontScale),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8F5C86),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 58),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
            ),
            onPressed: _startPlayback,
            icon: const Icon(Icons.play_arrow_rounded, size: 28),
            label: Text(
              'Begin Listening',
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 18 * fontScale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionBullet(IconData icon, String text, double fontScale) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: const Color(0xFF8F5C86)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 15 * fontScale,
                color: AppColors.charcoalText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Playback View
  Widget _buildPlaybackView(double fontScale) {
    final song = _song!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Memory Phase: Listening',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 14 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8F5C86),
                ),
              ),
              if (_isPlaying)
                Row(
                  children: [
                    const Icon(Icons.graphic_eq_rounded, color: Color(0xFF8F5C86), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'Singing / Speaking...',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 12 * fontScale,
                        color: const Color(0xFF8F5C86),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: song.lines.length,
              itemBuilder: (context, i) {
                final isCurrent = i == _currentLineIndex && _isPlaying;
                final isPast = i < _currentLineIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFF8F5C86).withValues(alpha: 0.16)
                        : isPast
                            ? Colors.white.withValues(alpha: 0.8)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrent
                          ? const Color(0xFF8F5C86)
                          : isPast
                              ? Colors.grey.shade300
                              : Colors.grey.shade200,
                      width: isCurrent ? 2.5 : 1.0,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: const Color(0xFF8F5C86).withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCurrent
                              ? const Color(0xFF8F5C86)
                              : Colors.grey.shade200,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          song.lines[i],
                          style: GoogleFonts.newsreader(
                            fontSize: 17 * fontScale,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                            color: isCurrent
                                ? const Color(0xFF8F5C86)
                                : AppColors.charcoalText,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8F5C86),
                    side: const BorderSide(color: Color(0xFF8F5C86)),
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _replaySong,
                  icon: const Icon(Icons.replay_rounded),
                  label: Text('Listen Again', style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8F5C86),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _proceedToTasks,
                  icon: const Icon(Icons.check_rounded),
                  label: Text('Ready to Recall', style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Task A: Item Recall View
  Widget _buildItemRecallView(double fontScale) {
    final q = _song!.questions[0];
    return _buildQuestionScaffold(
      stepTitle: 'Task 1 of 4 • Item Recall',
      question: q.question,
      hint: q.hint,
      options: q.options,
      selectedAnswer: _selectedItemAnswer,
      onSelect: _handleItemAnswer,
      fontScale: fontScale,
      allowVoice: true,
    );
  }

  // 4. Task B: Sequence Recall View
  Widget _buildSequenceRecallView(double fontScale) {
    final q = _song!.questions[1];
    return _buildQuestionScaffold(
      stepTitle: 'Task 2 of 4 • Sequence Recall',
      question: q.question,
      hint: q.hint,
      options: q.options,
      selectedAnswer: _selectedSequenceAnswer,
      onSelect: _handleSequenceAnswer,
      fontScale: fontScale,
      allowVoice: false,
    );
  }

  // 5. Task C: Event Ordering View
  Widget _buildEventOrderingView(double fontScale) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Task 3 of 4 • Event Ordering',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 14 * fontScale,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8F5C86),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Arrange these events in the exact order they happened:',
            style: GoogleFonts.newsreader(
              fontSize: 18 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoalText,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: _userOrderedEvents.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _userOrderedEvents.removeAt(oldIndex);
                  _userOrderedEvents.insert(newIndex, item);
                });
                SoundService.playTap();
              },
              itemBuilder: (context, index) {
                final step = _userOrderedEvents[index];
                return Card(
                  key: ValueKey(step.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 1,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF8F5C86).withValues(alpha: 0.15),
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8F5C86),
                        ),
                      ),
                    ),
                    title: Text(
                      step.text,
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 15 * fontScale,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoalText,
                      ),
                    ),
                    trailing: const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8F5C86),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _submitEventOrdering,
            icon: const Icon(Icons.check_circle_rounded),
            label: Text(
              'Submit Event Order',
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 16 * fontScale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 6. Task D: Attention View
  Widget _buildAttentionView(double fontScale) {
    final q = _song!.questions[2];
    return _buildQuestionScaffold(
      stepTitle: 'Task 4 of 4 • Attention to Detail',
      question: q.question,
      hint: q.hint,
      options: q.options,
      selectedAnswer: _selectedAttentionAnswer,
      onSelect: _handleAttentionAnswer,
      fontScale: fontScale,
      allowVoice: false,
    );
  }

  // 7. Delayed Interlude View (Buffer phase)
  Widget _buildDelayedInterludeView(double fontScale) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8F5C86).withValues(alpha: 0.12),
                border: Border.all(color: const Color(0xFF8F5C86), width: 2),
              ),
              child: Center(
                child: Text(
                  '$_interludeRemainingSeconds',
                  style: GoogleFonts.newsreader(
                    fontSize: 42 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8F5C86),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Gentle Breathing Pause...',
              style: GoogleFonts.newsreader(
                fontSize: 22 * fontScale,
                fontWeight: FontWeight.bold,
                color: AppColors.charcoalText,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Breathe in calmly and rest your eyes.\nA surprise delayed memory recall question will appear next.',
              textAlign: TextAlign.center,
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 15 * fontScale,
                color: AppColors.charcoalText.withValues(alpha: 0.75),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 8. Task E: Delayed Recall View
  Widget _buildDelayedRecallView(AppState appState, double fontScale) {
    final q = _song!.delayedQuestion;
    return _buildQuestionScaffold(
      stepTitle: 'Final Challenge • Delayed Recall',
      question: q.question,
      hint: q.hint,
      options: q.options,
      selectedAnswer: _selectedDelayedAnswer,
      onSelect: (ans) => _handleDelayedAnswer(ans, appState),
      fontScale: fontScale,
      allowVoice: true,
    );
  }

  // Shared Question Builder
  Widget _buildQuestionScaffold({
    required String stepTitle,
    required String question,
    required String hint,
    required List<String> options,
    required String? selectedAnswer,
    required Function(String) onSelect,
    required double fontScale,
    required bool allowVoice,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            stepTitle,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 13 * fontScale,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8F5C86),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question,
            style: GoogleFonts.newsreader(
              fontSize: 20 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoalText,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hint: $hint',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 13 * fontScale,
              fontStyle: FontStyle.italic,
              color: AppColors.charcoalText.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 20),
          if (allowVoice) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening ? Colors.red : const Color(0xFF8F5C86),
                      size: 28,
                    ),
                    onPressed: () {
                      if (_isListening) {
                        _stopListening();
                      } else {
                        _startListening(onMatched: onSelect);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isListening
                          ? 'Listening... speak your answer'
                          : (_voiceTranscript.isNotEmpty
                              ? 'Heard: "$_voiceTranscript"'
                              : 'Tap microphone to speak answer'),
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 14 * fontScale,
                        color: _isListening ? Colors.red : AppColors.charcoalText,
                        fontWeight: _isListening ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_voiceError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _voiceError!,
                  style: GoogleFonts.atkinsonHyperlegible(fontSize: 12 * fontScale, color: Colors.orange.shade800),
                ),
              ),
            const SizedBox(height: 16),
          ],
          ...options.map((opt) {
            final isChosen = selectedAnswer == opt;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: selectedAnswer == null ? () => onSelect(opt) : null,
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: isChosen ? const Color(0xFF8F5C86).withValues(alpha: 0.15) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isChosen ? const Color(0xFF8F5C86) : Colors.grey.shade300,
                      width: isChosen ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isChosen ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: isChosen ? const Color(0xFF8F5C86) : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          opt,
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 16 * fontScale,
                            fontWeight: isChosen ? FontWeight.bold : FontWeight.w500,
                            color: isChosen ? const Color(0xFF8F5C86) : AppColors.charcoalText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // 9. Results View
  Widget _buildResultsView(double fontScale) {
    final overall = (
      _itemRecallScore * 0.25 +
      _sequenceRecallScore * 0.25 +
      _eventOrderingScore * 0.20 +
      _attentionScore * 0.15 +
      _delayedRecallScore * 0.15
    ).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.celebration_rounded, size: 64, color: Color(0xFF8F5C86)),
          const SizedBox(height: 12),
          Text(
            'Memory Melody Complete!',
            textAlign: TextAlign.center,
            style: GoogleFonts.newsreader(
              fontSize: 24 * fontScale,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8F5C86),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Overall Cognitive Score: $overall%',
            textAlign: TextAlign.center,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 18 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoalText,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cognitive Dimension Breakdown',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 15 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoalText,
                  ),
                ),
                const SizedBox(height: 14),
                _buildDimensionRow('🎵 Item Recall', _itemRecallScore, fontScale),
                _buildDimensionRow('🔢 Sequence Recall', _sequenceRecallScore, fontScale),
                _buildDimensionRow('📋 Event Ordering', _eventOrderingScore, fontScale),
                _buildDimensionRow('🎯 Attention to Detail', _attentionScore, fontScale),
                _buildDimensionRow('⏳ Delayed Recall', _delayedRecallScore, fontScale),
              ],
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8F5C86),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              setState(() {
                _phase = MemoryMelodyPhase.intro;
                _selectedItemAnswer = null;
                _selectedSequenceAnswer = null;
                _selectedAttentionAnswer = null;
                _selectedDelayedAnswer = null;
              });
              _loadSong();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              'Play Another Melody',
              style: GoogleFonts.atkinsonHyperlegible(fontSize: 16 * fontScale, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.charcoalText,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Return to Sanctuary',
              style: GoogleFonts.atkinsonHyperlegible(fontSize: 15 * fontScale, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionRow(String label, int score, double fontScale) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 13 * fontScale,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoalText,
                ),
              ),
              Text(
                '$score%',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 13 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8F5C86),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100.0,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8F5C86)),
            ),
          ),
        ],
      ),
    );
  }
}
