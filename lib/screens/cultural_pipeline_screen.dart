import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/cultural_content.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../utils/sanskrit_text_normalizer.dart';
import '../widgets/confetti_overlay.dart';

enum ShlokaPracticeMode {
  listen,
  echo,
  recall,
  arrange,
}

enum ShlokaScriptMode {
  sanskrit,
  transliteration,
  meaning,
}

class CulturalPipelineScreen extends StatefulWidget {
  final CulturalContentItem item;

  const CulturalPipelineScreen({super.key, required this.item});

  @override
  State<CulturalPipelineScreen> createState() => _CulturalPipelineScreenState();
}

class _CulturalPipelineScreenState extends State<CulturalPipelineScreen> {
  ShlokaPracticeMode _practiceMode = ShlokaPracticeMode.listen;
  ShlokaScriptMode _scriptMode = ShlokaScriptMode.sanskrit;

  // ── Listen Mode State ──
  int? _activeChantingPadaIndex;
  bool _isPlayingFullVerse = false;
  Timer? _chantSequenceTimer;

  // ── Echo Mode State ──
  int _currentEchoPadaIndex = 0;
  bool _isEchoMicActive = false;
  String _lastEchoSpokenText = '';
  String? _echoFeedbackMessage;
  bool _echoFeedbackIsPositive = true;

  // ── Recall Mode State ──
  int _recallCurrentStep = 0; // prompt is padas[step], asking for padas[step + 1]
  List<String> _recallOptions = [];
  String? _selectedRecallChoice;
  bool? _recallChoiceIsCorrect;

  // ── Arrange Mode State ──
  late List<String> _arrangedPadas;
  bool _isArrangedEvaluated = false;
  int _arrangedMatches = 0;

  // ── STT Engine ──
  stt.SpeechToText? _speech;
  bool _isSpeechInitialized = false;

  final Stopwatch _sessionStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _arrangedPadas = List<String>.from(widget.item.chunks);
    _shufflePadas();
    _setupRecallOptions();
    _initSpeechEngine();
    _sessionStopwatch.start();
  }

  void _shufflePadas() {
    final original = widget.item.chunks;
    if (original.length <= 1) return;
    List<String> shuffled = List<String>.from(original);
    int attempts = 0;
    while (attempts < 5 && _listsEqual(shuffled, original)) {
      shuffled.shuffle();
      attempts++;
    }
    _arrangedPadas = shuffled;
    _isArrangedEvaluated = false;
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _setupRecallOptions() {
    final padas = widget.item.chunks;
    if (padas.length < 2) return;

    final targetCorrect = padas[(_recallCurrentStep + 1) % padas.length];
    final Set<String> options = {targetCorrect};

    // Add distractors from other padas or standard classical variants
    for (int i = 0; i < padas.length; i++) {
      if (padas[i] != targetCorrect && padas[i] != padas[_recallCurrentStep]) {
        options.add(padas[i]);
      }
      if (options.length >= 3) break;
    }

    if (options.length < 3) {
      options.add('ॐ शान्तिः शान्तिः शान्तिः');
    }
    if (options.length < 3) {
      options.add('सर्वं मङ्गलम् भवतु');
    }

    _recallOptions = options.toList()..shuffle();
    _selectedRecallChoice = null;
    _recallChoiceIsCorrect = null;
  }

  void _initSpeechEngine() async {
    _speech = stt.SpeechToText();
    try {
      _isSpeechInitialized = await _speech!.initialize(
        onError: (e) {
          if (mounted) setState(() => _isEchoMicActive = false);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted && _isEchoMicActive) {
              _finishEchoVoiceEvaluation();
            }
          }
        },
      );
    } catch (_) {
      _isSpeechInitialized = false;
    }
  }

  @override
  void dispose() {
    _chantSequenceTimer?.cancel();
    _speech?.stop();
    SoundService.stop();
    _sessionStopwatch.stop();
    super.dispose();
  }

  // ── Listen Mode Logic ──
  void _playWholeVerse() async {
    SoundService.playTap();
    _chantSequenceTimer?.cancel();
    setState(() {
      _isPlayingFullVerse = true;
      _activeChantingPadaIndex = 0;
    });

    final padas = widget.item.chunks;
    for (int i = 0; i < padas.length; i++) {
      if (!mounted || !_isPlayingFullVerse) break;
      setState(() => _activeChantingPadaIndex = i);
      SoundService.speak(padas[i], languageCode: widget.item.languageCode);
      // Wait for recitation of this pada before advancing
      final words = padas[i].split(' ').length;
      final delay = Duration(milliseconds: 1200 + (words * 450));
      await Future.delayed(delay);
    }

    if (mounted) {
      setState(() {
        _isPlayingFullVerse = false;
        _activeChantingPadaIndex = null;
      });
    }
  }

  void _stopVersePlayback() {
    _chantSequenceTimer?.cancel();
    SoundService.stop();
    setState(() {
      _isPlayingFullVerse = false;
      _activeChantingPadaIndex = null;
    });
  }

  void _chantSinglePada(int index) {
    SoundService.playTap();
    setState(() => _activeChantingPadaIndex = index);
    final pada = widget.item.chunks[index];
    SoundService.speak(pada, languageCode: widget.item.languageCode);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _activeChantingPadaIndex == index) {
        setState(() => _activeChantingPadaIndex = null);
      }
    });
  }

  // ── Echo Mode Logic ──
  void _playTeacherPada() {
    SoundService.playTap();
    final pada = widget.item.chunks[_currentEchoPadaIndex];
    SoundService.speak(pada, languageCode: widget.item.languageCode);
  }

  void _startEchoRecording() async {
    SoundService.playTap();
    setState(() {
      _isEchoMicActive = true;
      _lastEchoSpokenText = '';
      _echoFeedbackMessage = null;
    });

    if (_speech == null || !_isSpeechInitialized) {
      // Fallback if mic unavailable
      _confirmManualEchoRecitation();
      return;
    }

    try {
      await _speech!.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _lastEchoSpokenText = result.recognizedWords;
            });
          }
        },
      );
    } catch (_) {
      _confirmManualEchoRecitation();
    }
  }

  void _finishEchoVoiceEvaluation() {
    setState(() => _isEchoMicActive = false);
    final targetPada = widget.item.chunks[_currentEchoPadaIndex];
    final match = SanskritTextNormalizer.evaluateMatch(
      targetOriginal: targetPada,
      targetTransliteration: targetPada,
      userTranscript: _lastEchoSpokenText,
    );

    SoundService.playSuccess();
    setState(() {
      _echoFeedbackIsPositive = true;
      if (match.matchPercentage >= 40.0) {
        _echoFeedbackMessage = 'Wonderful recitation! Clear and resonant rhythm.';
      } else {
        _echoFeedbackMessage = 'Good effort! Every recitation cultivates peace and recall.';
      }
    });
  }

  void _confirmManualEchoRecitation() {
    SoundService.playSuccess();
    setState(() {
      _isEchoMicActive = false;
      _echoFeedbackIsPositive = true;
      _echoFeedbackMessage = 'Well recited! Your devotion and focus nourish memory.';
    });
  }

  void _advanceEchoPada() {
    SoundService.playTap();
    final padas = widget.item.chunks;
    if (_currentEchoPadaIndex < padas.length - 1) {
      setState(() {
        _currentEchoPadaIndex++;
        _echoFeedbackMessage = null;
        _lastEchoSpokenText = '';
      });
      _playTeacherPada();
    } else {
      ConfettiOverlay.show(
        context,
        title: 'Shloka Echo Complete! 🌸',
        subtitle: 'You completed every phrase of this sacred verse.',
      );
      setState(() {
        _echoFeedbackMessage = 'All phrases recited with care! Tap below to try Recall mode.';
      });
    }
  }

  // ── Recall Mode Logic ──
  void _selectRecallOption(String choice, AppState appState) {
    if (_selectedRecallChoice != null) return; // already answered
    SoundService.playTap();

    final padas = widget.item.chunks;
    final targetCorrect = padas[(_recallCurrentStep + 1) % padas.length];
    final isCorrect = choice == targetCorrect;

    setState(() {
      _selectedRecallChoice = choice;
      _recallChoiceIsCorrect = isCorrect;
    });

    if (isCorrect) {
      SoundService.playSuccess();
      SoundService.speak(choice, languageCode: widget.item.languageCode);
    } else {
      SoundService.playError();
    }
  }

  void _advanceRecallStep() {
    SoundService.playTap();
    final padas = widget.item.chunks;
    if (_recallCurrentStep < padas.length - 2) {
      setState(() {
        _recallCurrentStep++;
      });
      _setupRecallOptions();
    } else {
      ConfettiOverlay.show(
        context,
        title: 'Verse Recall Mastered! 🌟',
        subtitle: 'You remembered the full chain of sacred phrases!',
      );
      setState(() {
        _recallCurrentStep = 0;
      });
      _setupRecallOptions();
    }
  }

  // ── Arrange Mode Logic ──
  void _movePada(int index, int delta) {
    SoundService.playTap();
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= _arrangedPadas.length) return;
    setState(() {
      final item = _arrangedPadas.removeAt(index);
      _arrangedPadas.insert(newIndex, item);
      _isArrangedEvaluated = false;
    });
  }

  Future<void> _checkArrangedSequence(AppState appState) async {
    SoundService.playTap();
    final original = widget.item.chunks;
    int matches = 0;
    for (int i = 0; i < original.length; i++) {
      if (i < _arrangedPadas.length && _arrangedPadas[i] == original[i]) {
        matches++;
      }
    }

    final isAllCorrect = matches == original.length;
    setState(() {
      _isArrangedEvaluated = true;
      _arrangedMatches = matches;
    });

    if (isAllCorrect) {
      SoundService.playFanfare();
      if (mounted) {
        ConfettiOverlay.show(
          context,
          title: 'Harmonious Sequence! 🪔',
          subtitle: 'You correctly assembled all ${original.length} padas of the verse!',
        );
      }
      // Chant full assembled shloka
      SoundService.speak(widget.item.originalScriptText, languageCode: widget.item.languageCode);
    } else {
      SoundService.playSuccess();
    }

    // Log attempt with supportive attribution
    await appState.attemptRepository.logAttempt(
      ExerciseAttempt(
        id: 'att_cult_${DateTime.now().millisecondsSinceEpoch}',
        userId: appState.credentialId,
        domain: ExerciseDomain.culturalOral,
        cognitiveDomain: CognitiveDomain.sequentialMemory,
        type: ExerciseType.structuredRecallPipeline,
        exerciseId: 'cultural_${widget.item.id}',
        responseMode: 'progressive_padas',
        rawScore: matches.toDouble(),
        maxScore: original.length.toDouble(),
        timeTakenMs: _sessionStopwatch.elapsedMilliseconds,
        metadata: {
          'practiceMode': _practiceMode.name,
          'itemTitle': widget.item.title,
          'matches': matches,
        },
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
        title: Text(
          widget.item.title,
          style: GoogleFonts.newsreader(
            fontWeight: FontWeight.bold,
            fontSize: 20 * fontScale,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.charcoalText,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Return to Practice',
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isPlayingFullVerse ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
              color: AppColors.terracottaPrimary,
            ),
            tooltip: _isPlayingFullVerse ? 'Stop Chanting' : 'Chant Whole Verse',
            onPressed: _isPlayingFullVerse ? _stopVersePlayback : _playWholeVerse,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderBanner(fontScale),
              const SizedBox(height: 14),
              _buildScriptModeSelector(fontScale),
              const SizedBox(height: 14),
              _buildPracticeModeSelector(fontScale),
              const SizedBox(height: 18),
              _buildActiveModeContent(appState, fontScale),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Header Banner ──
  Widget _buildHeaderBanner(double fontScale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.3)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.terracottaSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_stories_rounded, color: AppColors.terracottaPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.source,
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.terracottaPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.item.cognitivePurpose,
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 13 * fontScale,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Script / Display Switcher ──
  Widget _buildScriptModeSelector(double fontScale) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _buildScriptTab('संस्कृत', ShlokaScriptMode.sanskrit, fontScale),
          _buildScriptTab('Transliteration', ShlokaScriptMode.transliteration, fontScale),
          _buildScriptTab('Meaning', ShlokaScriptMode.meaning, fontScale),
        ],
      ),
    );
  }

  Widget _buildScriptTab(String label, ShlokaScriptMode mode, double fontScale) {
    final isSelected = _scriptMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          SoundService.playTap();
          setState(() => _scriptMode = mode);
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.sageSecondary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 12 * fontScale,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.charcoalText,
            ),
          ),
        ),
      ),
    );
  }

  // ── Progressive Practice Mode Selector Tabs ──
  Widget _buildPracticeModeSelector(double fontScale) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPracticeChip('🎧 Listen', ShlokaPracticeMode.listen, fontScale),
          const SizedBox(width: 8),
          _buildPracticeChip('🗣️ Echo', ShlokaPracticeMode.echo, fontScale),
          const SizedBox(width: 8),
          _buildPracticeChip('🧩 Recall', ShlokaPracticeMode.recall, fontScale),
          const SizedBox(width: 8),
          _buildPracticeChip('🔀 Arrange', ShlokaPracticeMode.arrange, fontScale),
        ],
      ),
    );
  }

  Widget _buildPracticeChip(String label, ShlokaPracticeMode mode, double fontScale) {
    final isSelected = _practiceMode == mode;
    return InkWell(
      onTap: () {
        SoundService.playTap();
        setState(() => _practiceMode = mode);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.terracottaPrimary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.terracottaPrimary : AppColors.sandalwoodGold.withValues(alpha: 0.35),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? const [BoxShadow(color: Color(0x18B85028), blurRadius: 6, offset: Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 14 * fontScale,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.charcoalText,
          ),
        ),
      ),
    );
  }

  // ── Active Mode Content Router ──
  Widget _buildActiveModeContent(AppState appState, double fontScale) {
    switch (_practiceMode) {
      case ShlokaPracticeMode.listen:
        return _buildListenMode(fontScale);
      case ShlokaPracticeMode.echo:
        return _buildEchoMode(fontScale);
      case ShlokaPracticeMode.recall:
        return _buildRecallMode(appState, fontScale);
      case ShlokaPracticeMode.arrange:
        return _buildArrangeMode(appState, fontScale);
    }
  }

  // ── 1. LISTEN MODE ──
  Widget _buildListenMode(double fontScale) {
    final padas = widget.item.chunks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF5EE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.headphones_rounded, color: AppColors.terracottaPrimary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Listen calmly to each phrase. Tap any card to hear it spoken individually.',
                  style: GoogleFonts.atkinsonHyperlegible(fontSize: 13 * fontScale, color: AppColors.charcoalText),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(padas.length, (idx) {
          final isHighlighted = _activeChantingPadaIndex == idx;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _chantSinglePada(idx),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isHighlighted ? AppColors.terracottaSoft : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isHighlighted ? AppColors.terracottaPrimary : AppColors.sandalwoodGold.withValues(alpha: 0.3),
                      width: isHighlighted ? 2.2 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isHighlighted ? const Color(0x1CB85028) : const Color(0x06000000),
                        blurRadius: isHighlighted ? 8 : 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isHighlighted ? AppColors.terracottaPrimary : AppColors.canvasIvory,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${idx + 1}',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 13 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: isHighlighted ? Colors.white : AppColors.charcoalText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _getDisplayPadaText(padas[idx], idx),
                          style: GoogleFonts.newsreader(
                            fontSize: 20 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: isHighlighted ? AppColors.terracottaPrimary : AppColors.charcoalText,
                            height: 1.35,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isHighlighted ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                          color: AppColors.terracottaPrimary,
                          size: 24,
                        ),
                        onPressed: () => _chantSinglePada(idx),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _isPlayingFullVerse ? _stopVersePlayback : _playWholeVerse,
          icon: Icon(_isPlayingFullVerse ? Icons.stop_rounded : Icons.play_circle_filled_rounded, size: 22),
          label: Text(
            _isPlayingFullVerse ? 'Stop Chanting' : 'Listen to Full Verse',
            style: GoogleFonts.atkinsonHyperlegible(fontSize: 16 * fontScale, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.terracottaPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  // ── 2. ECHO MODE ──
  Widget _buildEchoMode(double fontScale) {
    final padas = widget.item.chunks;
    final currentPada = padas[_currentEchoPadaIndex];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sageSecondary, width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PHRASE ${_currentEchoPadaIndex + 1} OF ${padas.length}',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 12 * fontScale,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppColors.sageSecondary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: AppColors.sageSecondary),
                tooltip: 'Listen to phrase again',
                onPressed: _playTeacherPada,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F7F4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.sageSecondary.withValues(alpha: 0.3)),
            ),
            child: Text(
              _getDisplayPadaText(currentPada, _currentEchoPadaIndex),
              textAlign: TextAlign.center,
              style: GoogleFonts.newsreader(
                fontSize: 22 * fontScale,
                fontWeight: FontWeight.bold,
                color: AppColors.charcoalText,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (_echoFeedbackMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _echoFeedbackIsPositive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _echoFeedbackIsPositive ? Colors.green.shade600 : Colors.orange.shade700,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _echoFeedbackIsPositive ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    color: _echoFeedbackIsPositive ? Colors.green.shade700 : Colors.orange.shade800,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _echoFeedbackMessage!,
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 13 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoalText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _advanceEchoPada,
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              label: Text(
                _currentEchoPadaIndex < padas.length - 1 ? 'Next Phrase ➔' : 'Restart Echo Session',
                style: GoogleFonts.atkinsonHyperlegible(fontSize: 15 * fontScale, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sageSecondary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ] else ...[
            Text(
              'Listen first, then speak or confirm recitation:',
              textAlign: TextAlign.center,
              style: GoogleFonts.atkinsonHyperlegible(fontSize: 13 * fontScale, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _playTeacherPada,
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: Text('Listen First', style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.charcoalText,
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: AppColors.sandalwoodGold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isEchoMicActive ? null : _startEchoRecording,
                    icon: Icon(_isEchoMicActive ? Icons.mic_rounded : Icons.mic_none_rounded, size: 18),
                    label: Text(
                      _isEchoMicActive ? 'Listening...' : 'Repeat with Voice',
                      style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracottaPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _confirmManualEchoRecitation,
              icon: const Icon(Icons.check_rounded, size: 18, color: AppColors.sageSecondary),
              label: Text(
                'I recited this phrase (Tap to Confirm)',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 13 * fontScale,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sageSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 3. RECALL MODE ──
  Widget _buildRecallMode(AppState appState, double fontScale) {
    final padas = widget.item.chunks;
    final currentAnchorPada = padas[_recallCurrentStep];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'PHRASE ${_recallCurrentStep + 1} OF ${padas.length}:',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 11 * fontScale,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppColors.terracottaPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _getDisplayPadaText(currentAnchorPada, _recallCurrentStep),
                style: GoogleFonts.newsreader(
                  fontSize: 22 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoalText,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 6),
              Text(
                'Which sacred phrase follows next?',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 14 * fontScale,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sageSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._recallOptions.map((opt) {
          final isSelected = _selectedRecallChoice == opt;
          final targetCorrect = padas[(_recallCurrentStep + 1) % padas.length];
          final isTarget = opt == targetCorrect;

          Color cardBg = Colors.white;
          Color cardBorder = AppColors.sandalwoodGold.withValues(alpha: 0.3);

          if (_selectedRecallChoice != null) {
            if (isTarget) {
              cardBg = const Color(0xFFE8F5E9);
              cardBorder = Colors.green.shade600;
            } else if (isSelected) {
              cardBg = const Color(0xFFFFEBEE);
              cardBorder = Colors.red.shade400;
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _selectedRecallChoice != null ? null : () => _selectRecallOption(opt, appState),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cardBorder, width: isSelected || isTarget ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          opt,
                          style: GoogleFonts.newsreader(
                            fontSize: 18 * fontScale,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoalText,
                          ),
                        ),
                      ),
                      if (_selectedRecallChoice != null)
                        Icon(
                          isTarget ? Icons.check_circle_rounded : (isSelected ? Icons.cancel_rounded : Icons.circle_outlined),
                          color: isTarget ? Colors.green.shade700 : (isSelected ? Colors.red : Colors.grey.shade400),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        if (_selectedRecallChoice != null) ...[
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _advanceRecallStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracottaPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _recallChoiceIsCorrect == true ? 'Next Phrase ➔' : 'Continue Practice',
              style: GoogleFonts.atkinsonHyperlegible(fontSize: 15 * fontScale, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }

  // ── 4. ARRANGE MODE ──
  Widget _buildArrangeMode(AppState appState, double fontScale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF8F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.swap_vert_rounded, color: AppColors.terracottaPrimary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Use the arrow buttons to sequence the phrases into the authentic chronological verse.',
                  style: GoogleFonts.atkinsonHyperlegible(fontSize: 13 * fontScale, color: AppColors.charcoalText),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(_arrangedPadas.length, (idx) {
          final pada = _arrangedPadas[idx];
          final original = widget.item.chunks;
          final isCorrectSpot = _isArrangedEvaluated && idx < original.length && pada == original[idx];

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isCorrectSpot ? const Color(0xFFE8F5E9) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCorrectSpot
                      ? Colors.green.shade600
                      : AppColors.sandalwoodGold.withValues(alpha: 0.35),
                  width: isCorrectSpot ? 2.0 : 1.0,
                ),
                boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isCorrectSpot ? Colors.green.shade700 : AppColors.canvasIvory,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${idx + 1}',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 13 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: isCorrectSpot ? Colors.white : AppColors.charcoalText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pada,
                      style: GoogleFonts.newsreader(
                        fontSize: 18 * fontScale,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoalText,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                        tooltip: 'Move Up',
                        onPressed: idx > 0 ? () => _movePada(idx, -1) : null,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.arrow_downward_rounded, size: 20),
                        tooltip: 'Move Down',
                        onPressed: idx < _arrangedPadas.length - 1 ? () => _movePada(idx, 1) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => _checkArrangedSequence(appState),
          icon: const Icon(Icons.verified_rounded, size: 20),
          label: Text(
            'Check Verse Sequence',
            style: GoogleFonts.atkinsonHyperlegible(fontSize: 16 * fontScale, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.terracottaPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        if (_isArrangedEvaluated) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _arrangedMatches == widget.item.chunks.length
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _arrangedMatches == widget.item.chunks.length
                    ? Colors.green.shade600
                    : Colors.amber.shade700,
              ),
            ),
            child: Text(
              _arrangedMatches == widget.item.chunks.length
                  ? 'All $_arrangedMatches phrases in perfect order! Well done.'
                  : '$_arrangedMatches of ${widget.item.chunks.length} phrases in place. Adjust with arrows and re-check!',
              textAlign: TextAlign.center,
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 13 * fontScale,
                fontWeight: FontWeight.bold,
                color: AppColors.charcoalText,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Helper to format display text by script mode ──
  String _getDisplayPadaText(String originalPada, int index) {
    switch (_scriptMode) {
      case ShlokaScriptMode.sanskrit:
        return originalPada;
      case ShlokaScriptMode.transliteration:
        // If the item provides transliteration, use proportional slice or fallback
        final transList = widget.item.transliteration.split('\n');
        if (index < transList.length && transList[index].trim().isNotEmpty) {
          return transList[index].trim();
        }
        return widget.item.transliteration;
      case ShlokaScriptMode.meaning:
        final meaningList = widget.item.englishMeaning.split(';');
        if (index < meaningList.length && meaningList[index].trim().isNotEmpty) {
          return meaningList[index].trim();
        }
        return widget.item.englishMeaning;
    }
  }
}
