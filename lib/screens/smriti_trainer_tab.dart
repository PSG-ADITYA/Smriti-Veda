import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../data/sample_data.dart';
import '../models/scripture.dart';
import '../models/voice_assessment.dart';
import '../providers/app_state.dart';
import '../services/sanskrit_pronunciation_service.dart';
import '../services/voice_recall_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'recognition_exercise_screen.dart';
import 'sequence_recall_screen.dart';

class SmritiTrainerTab extends StatefulWidget {
  const SmritiTrainerTab({super.key});

  @override
  State<SmritiTrainerTab> createState() => _SmritiTrainerTabState();
}

class _SmritiTrainerTabState extends State<SmritiTrainerTab> with SingleTickerProviderStateMixin {
  // Trainer Modes: 0 = Listen & Study, 1 = Voice Recitation Lab, 2 = Flashcard Quiz
  int _trainerMode = 0;
  final SanskritPronunciationService _pronunciationService = SanskritPronunciationService();
  bool _isPlayingAudio = false;

  // Flashcard State
  int _currentIndex = 0;
  bool _showAnswer = false;
  int? _selectedQuizOption;
  bool? _isCorrect;

  // Voice Assessment State
  late stt.SpeechToText _speech;
  bool _isSpeechAvailable = false;
  bool _isListening = false;
  bool _isMicPaused = false;
  String _spokenText = '';
  String _accumulatedText = '';
  VoiceAssessmentResult? _assessmentResult;
  final Stopwatch _recitationTimer = Stopwatch();

  late AnimationController _flipController;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _initSpeech();
  }

  void _initSpeech() async {
    _speech = stt.SpeechToText();
    try {
      _isSpeechAvailable = await _speech.initialize(
        onError: (val) => debugPrint('STT Error: $val'),
        onStatus: (val) => debugPrint('STT Status: $val'),
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Speech initialization failed: $e');
    }
  }

  @override
  void dispose() {
    _pronunciationService.stop();
    _flipController.dispose();
    if (_speech.isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  void _playAudio(String text, PronunciationMode mode) async {
    setState(() => _isPlayingAudio = true);
    await _pronunciationService.pronounceMantra(text: text, mode: mode);
    if (mounted) setState(() => _isPlayingAudio = false);
  }

  void _flipCard() {
    if (_showAnswer) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _showAnswer = !_showAnswer;
    });
  }

  void _nextCard() {
    setState(() {
      _showAnswer = false;
      _selectedQuizOption = null;
      _isCorrect = null;
      _spokenText = '';
      _assessmentResult = null;
      _currentIndex = (_currentIndex + 1) % SampleData.flashcards.length;
    });
    _flipController.reset();
  }

  void _submitQuiz(int selectedIndex, Flashcard card, AppState appState) {
    setState(() {
      _selectedQuizOption = selectedIndex;
      _isCorrect = (selectedIndex == card.correctOptionIndex);
    });
    if (_isCorrect == true) {
      appState.incrementMastery();
    }
  }

  // Voice Recitation Methods
  void _startListening(String targetText) async {
    SoundService.playTap();
    setState(() {
      _spokenText = '';
      _accumulatedText = '';
      _assessmentResult = null;
      _isListening = true;
      _isMicPaused = false;
    });
    _recitationTimer.reset();
    _recitationTimer.start();

    if (_isSpeechAvailable) {
      _speech.listen(
        onResult: (val) {
          setState(() {
            _spokenText = val.recognizedWords;
            if (val.finalResult) {
              _stopListeningAndEvaluate(targetText);
            }
          });
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
        ),
      );
    } else {
      Timer(const Duration(seconds: 4), () {
        if (_isListening && !_isMicPaused) {
          _simulateRecitation(targetText);
        }
      });
    }
  }

  void _pauseListening() {
    SoundService.playTap();
    if (_speech.isListening) {
      _speech.stop();
    }
    _recitationTimer.stop();
    setState(() {
      _isMicPaused = true;
      if (_spokenText.isNotEmpty) {
        _accumulatedText = _spokenText;
      }
    });
  }

  void _resumeListening(String targetText) async {
    SoundService.playTap();
    setState(() {
      _isMicPaused = false;
      _isListening = true;
    });
    _recitationTimer.start();

    if (_isSpeechAvailable) {
      _speech.listen(
        onResult: (val) {
          setState(() {
            final prefix = _accumulatedText.isEmpty ? '' : '$_accumulatedText ';
            _spokenText = '$prefix${val.recognizedWords}';
            if (val.finalResult) {
              _stopListeningAndEvaluate(targetText);
            }
          });
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
        ),
      );
    }
  }

  void _stopListeningAndEvaluate(String targetText) {
    if (_speech.isListening) {
      _speech.stop();
    }
    _recitationTimer.stop();
    setState(() {
      _isListening = false;
      _isMicPaused = false;
      _assessmentResult = VoiceRecallService.evaluateRecitation(
        targetText: targetText,
        spokenText: _spokenText.isEmpty ? targetText : _spokenText,
        duration: _recitationTimer.elapsed,
      );
    });

    if (_assessmentResult != null && _assessmentResult!.isPassed) {
      SoundService.playFanfare();
    } else {
      SoundService.playSuccess();
    }
  }

  void _simulateRecitation(String targetText) {
    _recitationTimer.stop();
    setState(() {
      _isListening = false;
      _isMicPaused = false;
      _spokenText = targetText.replaceAll('_____', 'प्रचोदयात्');
      _assessmentResult = VoiceRecallService.evaluateRecitation(
        targetText: targetText.replaceAll('_____', 'प्रचोदयात्'),
        spokenText: _spokenText,
        duration: const Duration(seconds: 3),
      );
    });
    SoundService.playFanfare();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = SampleData.flashcards[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Smriti Trainer (स्मृति अभ्यास)',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Universal Cognitive Memory Games Section (Task 4)
            Row(
              children: [
                const Icon(Icons.psychology_outlined, color: AppColors.primaryGold),
                const SizedBox(width: 8),
                Text(
                  'UNIVERSAL COGNITIVE EXERCISES',
                  style: GoogleFonts.cinzel(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: AppColors.primaryGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                // Sequence Recall Game Launcher
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SequenceRecallScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF3D6B58).withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3D6B58).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.format_list_numbered, color: Color(0xFF3D6B58), size: 20),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sequence Recall',
                            style: GoogleFonts.cinzel(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textLightPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ordered item memory',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : AppColors.textLightSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Recognition Game Launcher
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RecognitionExerciseScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFB85028).withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB85028).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.grid_view, color: Color(0xFFB85028), size: 20),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Recognition',
                            style: GoogleFonts.cinzel(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textLightPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Target vs distractors',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : AppColors.textLightSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3-Stage Cognitive Mode Selector Bar
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _trainerMode = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _trainerMode == 0 ? AppColors.primarySaffron : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.headset,
                              size: 16,
                              color: _trainerMode == 0 ? Colors.white : AppColors.primaryGold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '1. Listen',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _trainerMode == 0 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _trainerMode = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _trainerMode == 1 ? AppColors.primarySaffron : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.mic,
                              size: 16,
                              color: _trainerMode == 1 ? Colors.white : AppColors.primaryGold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '2. Recite',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _trainerMode == 1 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _trainerMode = 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _trainerMode == 2 ? AppColors.primarySaffron : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.quiz,
                              size: 16,
                              color: _trainerMode == 2 ? Colors.white : AppColors.primaryGold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '3. Recall',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _trainerMode == 2 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Progress Banner
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Card ${_currentIndex + 1} of ${SampleData.flashcards.length}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGold,
                  ),
                ),
                Text(
                  'Completed: ${appState.versesMastered} Exercises',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primarySaffron,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // STAGE 0: LISTEN & STUDY (AUDITORY ENCODING)
            if (_trainerMode == 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'STAGE 1: LISTEN & AUDITORY STUDY',
                      style: GoogleFonts.cinzel(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primarySaffron,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      card.suktamTitle,
                      style: GoogleFonts.cinzel(
                        fontSize: 16,
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      card.sanskritText,
                      style: AppTheme.devanagariStyle(
                        fontSize: 22 * appState.fontScale,
                        color: isDark ? Colors.white : AppColors.textLightPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      card.transliteration,
                      style: GoogleFonts.notoSerif(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      card.englishMeaning,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Audio Recitation Guidance Controls
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.volume_up, size: 18, color: AppColors.primarySaffron),
                            const SizedBox(width: 8),
                            Text(
                              'AUDIO RECITATION GUIDANCE (TTS)',
                              style: GoogleFonts.cinzel(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGold,
                              ),
                            ),
                          ],
                        ),
                        if (_isPlayingAudio)
                          Text(
                            'Playing...',
                            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.primarySaffron),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _playAudio(card.sanskritText, PronunciationMode.continuous),
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('Full Audio'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primarySaffron,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _playAudio(card.sanskritText, PronunciationMode.padachhedaSyllable),
                          icon: const Icon(Icons.spellcheck, size: 16),
                          label: const Text('Slow Syllables'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryGold,
                            side: const BorderSide(color: AppColors.primaryGold),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _playAudio(card.sanskritText, PronunciationMode.kramaPaired),
                          icon: const Icon(Icons.compare_arrows, size: 16),
                          label: const Text('Paired Cadence'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryGold,
                            side: const BorderSide(color: AppColors.primaryGold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _trainerMode = 1),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Proceed to Voice Recitation Lab →'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primarySaffron,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],

            // STAGE 1: VOICE RECITATION LAB (STT EVALUATION)
            if (_trainerMode == 1) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primarySaffron.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      'STAGE 2: VOICE RECITATION PRACTICE',
                      style: GoogleFonts.cinzel(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primarySaffron,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      card.sanskritText,
                      style: AppTheme.devanagariStyle(
                        fontSize: 22 * appState.fontScale,
                        color: isDark ? Colors.white : AppColors.textLightPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      card.transliteration,
                      style: GoogleFonts.notoSerif(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Mic & Pause Controls Column
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Pause to Think Button (Visible when listening or paused)
                      if (_isListening || _isMicPaused) ...[
                        ElevatedButton.icon(
                          onPressed: () {
                            if (_isMicPaused) {
                              _resumeListening(card.sanskritText);
                            } else {
                              _pauseListening();
                            }
                          },
                          icon: Icon(_isMicPaused ? Icons.play_arrow : Icons.pause, size: 20),
                          label: Text(_isMicPaused ? '▶ Resume' : '⏸ Pause to Think'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isMicPaused ? Colors.orange.shade800 : AppColors.sageSecondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],

                      // Main Recording / Stop Button
                      GestureDetector(
                        onTap: () {
                          if (_isListening || _isMicPaused) {
                            _stopListeningAndEvaluate(card.sanskritText);
                          } else {
                            _startListening(card.sanskritText);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _isListening
                                  ? [Colors.red, Colors.deepOrange]
                                  : _isMicPaused
                                      ? [Colors.amber.shade700, Colors.orange]
                                      : [AppColors.terracottaPrimary, AppColors.sandalwoodGold],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening ? Colors.red : AppColors.terracottaPrimary).withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening || _isMicPaused ? Icons.stop_rounded : Icons.mic_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Mic Status Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isMicPaused
                          ? Colors.amber.shade50
                          : _isListening
                              ? Colors.red.shade50
                              : AppColors.canvasIvory,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isMicPaused
                            ? Colors.amber
                            : _isListening
                                ? Colors.red.shade300
                                : AppColors.borderSubtle,
                      ),
                    ),
                    child: Text(
                      _isMicPaused
                          ? '⏸ Microphone Paused — Take your time to think! Tap Resume when ready.'
                          : _isListening
                              ? '🎙️ Listening to your recitation... Tap ⏸ Pause to Think or Stop when done.'
                              : 'Tap Microphone to Begin Recitation (Vocal Assessment)',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _isMicPaused
                            ? Colors.amber.shade900
                            : _isListening
                                ? Colors.red.shade900
                                : AppColors.charcoalText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextButton.icon(
                    onPressed: () => _simulateRecitation(card.sanskritText),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Simulate Voice Recitation (Fast Demo)'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.terracottaPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Voice Analytics Breakdown Result Card
              if (_assessmentResult != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _assessmentResult!.isPassed ? Colors.green : AppColors.primarySaffron,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RECITATION PERFORMANCE',
                            style: GoogleFonts.cinzel(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (_assessmentResult!.isPassed ? Colors.green : Colors.orange).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Accuracy: ${_assessmentResult!.accuracyScore}%',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: _assessmentResult!.isPassed ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              'Sequence Score',
                              '${_assessmentResult!.sequenceScore}%',
                              Icons.sync_alt,
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricTile(
                              'Correct Words',
                              '${_assessmentResult!.correctWordsCount}/${_assessmentResult!.totalExpectedWords}',
                              Icons.check_circle_outline,
                              isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Spoken Input: "${_assessmentResult!.spokenText}"',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _assessmentResult!.feedbackMessage,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primarySaffron,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _trainerMode = 2),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Proceed to Memory Recall Quiz →'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primarySaffron,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],

            // STAGE 2: FLASHCARD & MISSING WORD RECALL QUIZ
            if (_trainerMode == 2) ...[
              GestureDetector(
                onTap: _flipCard,
                child: AnimatedBuilder(
                  animation: _flipController,
                  builder: (context, child) {
                    final angle = _flipController.value * pi;
                    final isUnder = (angle >= pi / 2);
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      alignment: Alignment.center,
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 220),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primaryGold.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGold.withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: isUnder
                            ? Transform(
                                transform: Matrix4.identity()..rotateY(pi),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'English Translation & Meaning',
                                      style: GoogleFonts.cinzel(
                                        fontSize: 14,
                                        color: AppColors.primarySaffron,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      card.englishMeaning,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        color: isDark ? Colors.white : AppColors.textLightPrimary,
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Tap to flip back to verse',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    card.suktamTitle,
                                    style: GoogleFonts.cinzel(
                                      fontSize: 16,
                                      color: AppColors.primaryGold,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    card.sanskritText,
                                    style: AppTheme.devanagariStyle(
                                      fontSize: 20 * appState.fontScale,
                                      color: isDark ? Colors.white : AppColors.textLightPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.flip, size: 16, color: AppColors.primarySaffron),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Tap card to reveal full meaning',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: AppColors.primarySaffron,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Interactive Verse Recall Quiz
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.quiz, color: AppColors.primaryGold),
                        const SizedBox(width: 8),
                        Text(
                          'VERSE RECALL QUIZ',
                          style: GoogleFonts.cinzel(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete the missing word in the verse above:',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hint: ${card.missingWordHint}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primarySaffron,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ...List.generate(card.quizOptions.length, (optIndex) {
                      final optionText = card.quizOptions[optIndex];
                      final isSelected = _selectedQuizOption == optIndex;
                      final isCorrectOpt = optIndex == card.correctOptionIndex;

                      Color btnColor = isDark ? AppColors.darkSurfaceCard : Colors.white;
                      Color textColor = isDark ? Colors.white : Colors.black87;

                      if (_selectedQuizOption != null) {
                        if (isCorrectOpt) {
                          btnColor = Colors.green.shade800;
                          textColor = Colors.white;
                        } else if (isSelected && !isCorrectOpt) {
                          btnColor = Colors.red.shade800;
                          textColor = Colors.white;
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: _selectedQuizOption == null
                              ? () => _submitQuiz(optIndex, card, appState)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: btnColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryGold
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.primaryGold.withValues(alpha: 0.2),
                                  child: Text(
                                    String.fromCharCode(65 + optIndex),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    optionText,
                                    style: AppTheme.devanagariStyle(
                                      fontSize: 16,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                if (_selectedQuizOption != null && isCorrectOpt)
                                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                if (_selectedQuizOption != null && isSelected && !isCorrectOpt)
                                  const Icon(Icons.cancel, color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Next Exercise Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _nextCard();
                    setState(() => _trainerMode = 0);
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Complete & Start Next Exercise'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primarySaffron,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryGold),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
