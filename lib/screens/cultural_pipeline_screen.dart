import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/cultural_content.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_overlay.dart';

class CulturalPipelineScreen extends StatefulWidget {
  final CulturalContentItem item;

  const CulturalPipelineScreen({super.key, required this.item});

  @override
  State<CulturalPipelineScreen> createState() => _CulturalPipelineScreenState();
}

class _CulturalPipelineScreenState extends State<CulturalPipelineScreen> {
  int _currentStage = 1; // 1 to 7
  final Map<int, bool> _stageCompleted = {};
  String? _selectedMissingChoice;
  bool _reverseCompleted = false;

  // Voice Recitation State Machine: IDLE -> LISTENING -> PROCESSING -> RESULT
  stt.SpeechToText? _speech;
  bool _isSpeechInitialized = false;
  bool _isListening = false;
  bool _isProcessing = false;
  String _recognizedTranscript = '';
  String? _sttError;
  int _matchedWordCount = 0;
  int _totalWordCount = 0;
  bool _showTextInputFallback = false;
  final TextEditingController _typeInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  void _initStt() async {
    _speech = stt.SpeechToText();
    try {
      _isSpeechInitialized = await _speech!.initialize(
        onError: (err) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _isProcessing = false;
              _sttError = 'Voice service notice: ${err.errorMsg}';
              _showTextInputFallback = true;
            });
          }
        },
        onStatus: (status) {
          if ((status == 'done' || status == 'notListening') && _isListening) {
            _stopAndScoreVoice();
          }
        },
      );
    } catch (e) {
      _isSpeechInitialized = false;
    }
  }

  @override
  void dispose() {
    if (_speech?.isListening == true) {
      _speech?.stop();
    }
    _typeInputController.dispose();
    super.dispose();
  }

  Future<void> _startVoiceListening() async {
    setState(() {
      _sttError = null;
      _recognizedTranscript = '';
      _matchedWordCount = 0;
    });

    if (_speech == null || !_isSpeechInitialized) {
      setState(() {
        _sttError = "Voice recognition isn't available on this device.";
        _showTextInputFallback = true;
      });
      return;
    }

    try {
      setState(() => _isListening = true);
      await _speech!.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _recognizedTranscript = result.recognizedWords;
            });
          }
        },
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 4),
      );
    } catch (e) {
      setState(() {
        _isListening = false;
        _sttError = 'Could not access microphone. You can type your answer instead.';
        _showTextInputFallback = true;
      });
    }
  }

  Future<void> _stopAndScoreVoice([String? customInput]) async {
    if (_speech?.isListening == true) {
      await _speech?.stop();
    }
    setState(() {
      _isListening = false;
      _isProcessing = true;
    });

    final text = customInput ?? _recognizedTranscript;
    final targetWords = widget.item.transliteration.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
    _totalWordCount = targetWords.isEmpty ? 5 : targetWords.length;
    final userWords = text.toLowerCase().split(RegExp(r'\s+')).toSet();

    int matched = 0;
    for (final tw in targetWords) {
      if (userWords.any((uw) => uw.contains(tw) || tw.contains(uw))) {
        matched++;
      }
    }
    if (matched == 0 && text.trim().isNotEmpty) {
      matched = (userWords.length).clamp(1, _totalWordCount);
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _matchedWordCount = matched;
        if (customInput != null) {
          _recognizedTranscript = customInput;
        }
      });
    }
  }

  void _nextStage() {
    setState(() {
      _stageCompleted[_currentStage] = true;
      if (_currentStage < 7) {
        _currentStage++;
      }
    });
  }

  void _prevStage() {
    setState(() {
      if (_currentStage > 1) {
        _currentStage--;
      }
    });
  }

  Future<void> _finishPipeline(AppState appState) async {
    await appState.attemptRepo.logAttempt(
      ExerciseAttempt(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: appState.activeUser.id,
        domain: ExerciseDomain.culturalOral,
        type: ExerciseType.structuredRecallPipeline,
        exerciseId: widget.item.id,
        timestamp: DateTime.now(),
        responseMode: '7_stage_pipeline',
        rawScore: 7.0,
        maxScore: 7.0,
        stage: 7,
      ),
    );

    if (mounted) {
      ConfettiOverlay.of(context)?.triggerCelebration(
        title: 'Oral Recitation Mastered! 🎉',
        subtitle: 'You completed all 7 stages of ${widget.item.title}!',
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final item = widget.item;

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
          '7-Stage Oral Recitation',
          style: GoogleFonts.newsreader(
            color: AppColors.charcoalText,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header Stepper
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.newsreader(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.terracottaPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.sageSecondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Stage $_currentStage of 7',
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sageSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _currentStage / 7.0,
                  backgroundColor: AppColors.canvasIvory,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.terracottaPrimary),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Full Information Card (Original + English Transliteration + Translation + Cognitive Purpose)
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.sandalwoodGold.withValues(alpha: 0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.originalScriptText,
                            style: GoogleFonts.newsreader(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.charcoalText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Transliteration: ${item.transliteration}',
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const Divider(height: 24),
                          Text(
                            'English Meaning:',
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.terracottaPrimary,
                            ),
                          ),
                          Text(
                            item.englishMeaning,
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 15,
                              color: AppColors.charcoalText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Why this activity:',
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sageSecondary,
                            ),
                          ),
                          Text(
                            item.cognitivePurpose,
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 14,
                              color: AppColors.charcoalText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              SoundService().speakText(
                                '${item.title}. ${item.originalScriptText}. Meaning: ${item.englishMeaning}',
                                languageCode: item.languageCode,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Playing voice recitation...')),
                              );
                            },
                            icon: const Icon(Icons.volume_up, color: Colors.white),
                            label: const Text('Listen to Voice Recitation'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.terracottaPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stage Specific Interactive Body
                  _buildStageContent(item, appState),
                ],
              ),
            ),
          ),

          // Bottom Stepper Controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                if (_currentStage > 1)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _prevStage,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.charcoalText,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentStage > 1) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentStage == 7
                        ? () => _finishPipeline(appState)
                        : _nextStage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracottaPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentStage == 7 ? 'Complete Pipeline' : 'Next Stage ➔',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageContent(CulturalContentItem item, AppState appState) {
    switch (_currentStage) {
      case 1:
        return _buildStageCard(
          title: 'Stage 1: LISTEN',
          description: 'Listen to the original rhythm and cadence of the recitation.',
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.speak(item.originalScriptText, languageCode: item.languageCode);
                },
                icon: const Icon(Icons.volume_up, size: 28),
                label: Text(
                  'Listen to Audio Recitation',
                  style: GoogleFonts.atkinsonHyperlegible(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sageSecondary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      case 2:
        return _buildStageCard(
          title: 'Stage 2: REPEAT',
          description: 'Repeat the recitation aloud to activate motor and speech memory.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_showTextInputFallback) ...[
                ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () {
                          if (_isListening) {
                            _stopAndScoreVoice();
                          } else {
                            _startVoiceListening();
                          }
                        },
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 28),
                  label: Text(
                    _isListening ? 'Listening... (Tap to Finish)' : 'Tap & Speak Recitation',
                    style: GoogleFonts.atkinsonHyperlegible(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isListening ? Colors.redAccent : AppColors.terracottaPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (_isProcessing) ...[
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 10),
                      Text('Processing voice response...'),
                    ],
                  ),
                ],
                if (_recognizedTranscript.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.canvasIvory,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your response:',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '"$_recognizedTranscript"',
                          style: GoogleFonts.newsreader(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: AppColors.charcoalText,
                          ),
                        ),
                        if (_matchedWordCount > 0) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.sageSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'You remembered $_matchedWordCount of $_totalWordCount words.',
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.sageSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (_sttError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _sttError!,
                    style: GoogleFonts.atkinsonHyperlegible(fontSize: 13, color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _showTextInputFallback = true),
                    child: const Text('Type your answer instead ➔'),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _typeInputController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Type the recitation from memory:',
                    hintText: 'Enter words or phrases you recall...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    if (_typeInputController.text.trim().isNotEmpty) {
                      _stopAndScoreVoice(_typeInputController.text.trim());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracottaPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Evaluate Typed Answer'),
                ),
                if (_recognizedTranscript.isNotEmpty && _matchedWordCount > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.sageSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'You remembered $_matchedWordCount of $_totalWordCount words.',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sageSecondary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _showTextInputFallback = false),
                    child: const Text('Switch back to Voice Recitation'),
                  ),
                ),
              ],
            ],
          ),
        );
      case 3:
        return _buildStageCard(
          title: 'Stage 3: CHUNK (Pāṭha Segmentation)',
          description: 'Recite in smaller 2–3 word chunks to reduce cognitive load.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: item.chunks.asMap().entries.map((e) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.canvasIvory,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.sandalwoodGold.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.terracottaPrimary,
                      child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.value,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoalText,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      case 4:
        return _buildStageCard(
          title: 'Stage 4: OVERLAPPING SEQUENCE',
          description: 'Notice how each phrase links seamlessly into the next phrase.',
          child: Column(
            children: List.generate(item.chunks.length - 1, (idx) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.sageSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.chunks[idx]}  ➔  ${item.chunks[idx + 1]}',
                  style: GoogleFonts.atkinsonHyperlegible(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              );
            }),
          ),
        );
      case 5:
        return _buildStageCard(
          title: 'Stage 5: REVERSE RECALL',
          description: 'Challenge reverse sequential memory pathways.',
          child: Column(
            children: [
              Text(
                'Reverse Order Chunks:',
                style: GoogleFonts.atkinsonHyperlegible(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...item.chunks.reversed.map((c) => Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: Text('• $c', style: GoogleFonts.atkinsonHyperlegible(fontSize: 16)),
                  )),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: CheckboxListTile(
                  title: const Text('I have completed reverse recall'),
                  value: _reverseCompleted,
                  activeColor: AppColors.terracottaPrimary,
                  onChanged: (v) => setState(() => _reverseCompleted = v ?? false),
                ),
              ),
            ],
          ),
        );
      case 6:
        final missingIdx = item.chunks.length > 2 ? 1 : 0;
        final correctChunk = item.chunks[missingIdx];
        final options = [correctChunk, 'Om Shanti', 'Hari Om']..shuffle();

        return _buildStageCard(
          title: 'Stage 6: MISSING ELEMENT',
          description: 'Identify the missing chunk in the sequence.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.chunks
                    .asMap()
                    .entries
                    .map((e) => e.key == missingIdx ? '[ ___ ? ___ ]' : e.value)
                    .join('  ➔  '),
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.terracottaPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((opt) {
                return Material(
                  color: Colors.transparent,
                  child: RadioListTile<String>(
                    activeColor: AppColors.terracottaPrimary,
                    title: Text(opt, style: GoogleFonts.atkinsonHyperlegible(fontSize: 16)),
                    value: opt,
                    // ignore: deprecated_member_use
                    groupValue: _selectedMissingChoice,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      setState(() {
                        _selectedMissingChoice = val;
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        );
      case 7:
        return _buildStageCard(
          title: 'Stage 7: DELAYED RECALL',
          description: 'Final consolidation check: Recite or recall the full verse from memory.',
          child: Column(
            children: [
              const Icon(Icons.stars, size: 48, color: AppColors.sandalwoodGold),
              const SizedBox(height: 12),
              Text(
                'Congratulations! You have completed all 7 pāṭha-structured memory stages for this item.',
                textAlign: TextAlign.center,
                style: GoogleFonts.atkinsonHyperlegible(fontSize: 16),
              ),
            ],
          ),
        );
      default:
        return Container();
    }
  }

  Widget _buildStageCard({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.sandalwoodGold.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.newsreader(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.charcoalText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 14,
                color: AppColors.secondaryText,
              ),
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}
