import '../services/session_engine/memory_session_generator.dart';
import '../models/game_difficulty.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_overlay.dart';

class MusicalNote {
  final String id;
  final String westernName;
  final String swaraName;
  final double frequency;
  final Color color;

  const MusicalNote({
    required this.id,
    required this.westernName,
    required this.swaraName,
    required this.frequency,
    required this.color,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MusicalNote && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const List<MusicalNote> kOctaveNotes = [
  MusicalNote(id: 'c4', westernName: 'C', swaraName: 'Sa', frequency: 261.63, color: Color(0xFFD32F2F)),
  MusicalNote(id: 'd4', westernName: 'D', swaraName: 'Re', frequency: 293.66, color: Color(0xFFE65100)),
  MusicalNote(id: 'e4', westernName: 'E', swaraName: 'Ga', frequency: 329.63, color: Color(0xFFF9A825)),
  MusicalNote(id: 'f4', westernName: 'F', swaraName: 'Ma', frequency: 349.23, color: Color(0xFF2E7D32)),
  MusicalNote(id: 'g4', westernName: 'G', swaraName: 'Pa', frequency: 392.00, color: Color(0xFF1565C0)),
  MusicalNote(id: 'a4', westernName: 'A', swaraName: 'Dha', frequency: 440.00, color: Color(0xFF6A1B9A)),
  MusicalNote(id: 'b4', westernName: 'B', swaraName: 'Ni', frequency: 493.88, color: Color(0xFFAD1457)),
  MusicalNote(id: 'c5', westernName: 'C5', swaraName: 'Taar Sa', frequency: 523.25, color: Color(0xFF00695C)),
];

class MelodyRoundConfig {
  final int roundNumber;
  final String title;
  final String difficulty;
  final List<String> noteIds;

  const MelodyRoundConfig({
    required this.roundNumber,
    required this.title,
    required this.difficulty,
    required this.noteIds,
  });
}

class MelodyDifficultyConfig {
  final GameDifficulty difficulty;
  final String title;
  final List<String> noteIds;
  final Duration noteDuration;
  final Duration gapDuration;
  final Duration stepDuration;

  const MelodyDifficultyConfig({
    required this.difficulty,
    required this.title,
    required this.noteIds,
    required this.noteDuration,
    required this.gapDuration,
    required this.stepDuration,
  });
}

const Map<GameDifficulty, MelodyDifficultyConfig> kMelodyDifficultyConfigs = {
  GameDifficulty.easy: MelodyDifficultyConfig(
    difficulty: GameDifficulty.easy,
    title: 'Three-Tone Harmonic Chord (Sa - Ga - Pa)',
    noteIds: ['c4', 'e4', 'g4'],
    noteDuration: Duration(milliseconds: 650),
    gapDuration: Duration(milliseconds: 250),
    stepDuration: Duration(milliseconds: 900),
  ),
  GameDifficulty.medium: MelodyDifficultyConfig(
    difficulty: GameDifficulty.medium,
    title: 'Five-Tone Melodic Scale (Sa - Re - Ga - Pa - Taar Sa)',
    noteIds: ['c4', 'd4', 'e4', 'g4', 'c5'],
    noteDuration: Duration(milliseconds: 450),
    gapDuration: Duration(milliseconds: 150),
    stepDuration: Duration(milliseconds: 600),
  ),
  GameDifficulty.hard: MelodyDifficultyConfig(
    difficulty: GameDifficulty.hard,
    title: 'Seven-Tone Rhythmic Heritage Wave',
    noteIds: ['c4', 'e4', 'g4', 'a4', 'g4', 'd4', 'c4'],
    noteDuration: Duration(milliseconds: 320),
    gapDuration: Duration(milliseconds: 100),
    stepDuration: Duration(milliseconds: 420),
  ),
};

enum MemoryMelodyPhase {
  ready,
  playback,
  reproduction,
  evaluated,
}

class MemoryMelodyScreen extends StatefulWidget {
  final String? initialTheme;
  const MemoryMelodyScreen({super.key, this.initialTheme});

  @override
  State<MemoryMelodyScreen> createState() => _MemoryMelodyScreenState();
}

class _MemoryMelodyScreenState extends State<MemoryMelodyScreen> {
  GameDifficulty _difficulty = GameDifficulty.easy;
  MemoryMelodyPhase _phase = MemoryMelodyPhase.ready;

  // Stored immutable target sequence for this round
  late List<MusicalNote> _targetSequence;

  // User input sequence
  final List<MusicalNote> _userSequence = [];

  // Playback & Animation State
  String? _currentlySoundingNoteId;
  Timer? _playbackTimer;
  bool _isPlayingMelody = false;

  // Evaluation & Metrics
  int _matchedNotesCount = 0;
  final Stopwatch _stopwatch = Stopwatch();
  int _cumulativeScore = 0;

  MelodyDifficultyConfig get _currentRound => kMelodyDifficultyConfigs[_difficulty]!;

  @override
  void initState() {
    super.initState();
    _initRound();
  }

  @override
  void dispose() {
    _cancelAudioAndTimers();
    super.dispose();
  }

  void _cancelAudioAndTimers() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _isPlayingMelody = false;
    _currentlySoundingNoteId = null;
  }

  void _initRound() {
    _cancelAudioAndTimers();
    _phase = MemoryMelodyPhase.ready;
    _userSequence.clear();
    _matchedNotesCount = 0;

    final noteMap = {for (final n in kOctaveNotes) n.id: n};
    final session = MemorySessionGenerator.generateMelodySession(_difficulty);
    _targetSequence = session.stimulus.noteIds.map((id) => noteMap[id] ?? kOctaveNotes.first).toList();

    _stopwatch.reset();
    setState(() {});
  }

  // ── Synchronized Audio Melody Playback ─────────────────────────────────────
  void _startMelodyPlayback() {
    if (_isPlayingMelody) return;
    _cancelAudioAndTimers();

    setState(() {
      _phase = MemoryMelodyPhase.playback;
      _isPlayingMelody = true;
      _userSequence.clear();
    });

    SoundService.speak('Listen carefully to the melody.');

    // Give 1.2s before tones start so user gets ready
    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted || !_isPlayingMelody) return;

      int noteIdx = 0;
      final stepDuration = _currentRound.stepDuration;
      final noteDuration = _currentRound.noteDuration;
      final gapDuration = _currentRound.gapDuration;

      _playSingleStep(noteIdx, stepDuration, noteDuration, gapDuration);
    });
  }

  void _playSingleStep(int noteIdx, Duration stepDuration, Duration noteDuration, Duration gapDuration) {
    if (!mounted || !_isPlayingMelody) return;

    if (noteIdx >= _targetSequence.length) {
      // Melody finished completely!
      _onMelodyPlaybackComplete();
      return;
    }

    final note = _targetSequence[noteIdx];
    setState(() {
      _currentlySoundingNoteId = note.id;
    });

    SoundService.playNote(note.frequency, label: note.westernName);

    // Turn off illumination after note duration
    Timer(noteDuration, () {
      if (mounted && _isPlayingMelody) {
        setState(() {
          _currentlySoundingNoteId = null;
        });
      }
    });

    // Schedule next note with consistent timing
    _playbackTimer = Timer(stepDuration, () {
      _playSingleStep(noteIdx + 1, stepDuration, noteDuration, gapDuration);
    });
  }

  void _onMelodyPlaybackComplete() {
    _cancelAudioAndTimers();
    if (!mounted) return;

    setState(() {
      _phase = MemoryMelodyPhase.reproduction;
    });

    SoundService.playSuccess();
    SoundService.speak('Now reproduce the melody in the same order.');
    _stopwatch.reset();
    _stopwatch.start();
  }

  // ── User Input & Note Selection ───────────────────────────────────────────
  void _onUserTapNote(MusicalNote note) {
    // Only accept input during reproduction phase
    if (_phase != MemoryMelodyPhase.reproduction) return;
    if (_isPlayingMelody) return;
    if (_userSequence.length >= _targetSequence.length) return;

    // Play note immediately on touch
    SoundService.playNote(note.frequency, label: note.westernName);

    setState(() {
      _currentlySoundingNoteId = note.id;
      _userSequence.add(note);
    });

    Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _currentlySoundingNoteId = null;
        });
      }
    });

    // If user filled all expected notes, evaluate immediately
    if (_userSequence.length == _targetSequence.length) {
      Timer(const Duration(milliseconds: 400), () {
        if (mounted) {
          final appState = AppStateScope.of(context);
          _evaluateSequence(appState);
        }
      });
    }
  }

  void _removeLastUserNote() {
    if (_phase != MemoryMelodyPhase.reproduction || _userSequence.isEmpty) return;
    SoundService.playTap();
    setState(() {
      _userSequence.removeLast();
    });
  }

  // ── Deterministic Ordered Comparison ──────────────────────────────────────
  void _evaluateSequence(AppState appState) async {
    _stopwatch.stop();

    int matches = 0;
    for (int i = 0; i < _targetSequence.length; i++) {
      if (i < _userSequence.length && _userSequence[i].id == _targetSequence[i].id) {
        matches++;
      }
    }

    final total = _targetSequence.length;
    final accuracyPct = (matches / total * 100.0).round();
    _matchedNotesCount = matches;
    _cumulativeScore += accuracyPct;

    setState(() {
      _phase = MemoryMelodyPhase.evaluated;
    });

    if (matches == total) {
      SoundService.playFanfare();
      if (mounted) {
        ConfettiOverlay.show(
          context,
          title: 'Harmonic Melody Master! 🎵',
          subtitle: 'You reproduced all $total notes in the exact sequence!',
        );
      }
    } else if (matches >= (total / 2)) {
      SoundService.playSuccess();
    } else {
      SoundService.playError();
    }

    // Persist attempt into repository
    await appState.attemptRepository.logAttempt(
      ExerciseAttempt(
        id: 'att_melody_${DateTime.now().millisecondsSinceEpoch}',
        userId: appState.credentialId,
        domain: ExerciseDomain.universalCognitive,
        cognitiveDomain: CognitiveDomain.auditoryRecall,
        type: ExerciseType.memoryMelody,
        exerciseId: 'memory_melody_${_difficulty.name}',
        responseMode: 'note_pads',
        rawScore: matches.toDouble(),
        maxScore: total.toDouble(),
        timeTakenMs: _stopwatch.elapsedMilliseconds,
      ),
    );
  }

  void _tryAgain() {
    SoundService.playTap();
    _initRound();
  }

  void _nextRound() {
    SoundService.playTap();
    if (_difficulty == GameDifficulty.easy) {
      setState(() => _difficulty = GameDifficulty.medium);
    } else if (_difficulty == GameDifficulty.medium) {
      setState(() => _difficulty = GameDifficulty.hard);
    }
    _initRound();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final fontScale = appState.fontScale;
    final total = _targetSequence.length;
    final accuracy = total > 0 ? (_matchedNotesCount / total * 100).round() : 0;

    return Scaffold(
      backgroundColor: AppColors.canvasIvory,
      appBar: AppBar(
        backgroundColor: AppColors.canvasIvory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.charcoalText),
          onPressed: () {
            _cancelAudioAndTimers();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Memory Melody',
          style: GoogleFonts.newsreader(
            fontSize: 22 * fontScale,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoalText,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF8E24AA).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.music_note_rounded, size: 16, color: Color(0xFF8E24AA)),
                const SizedBox(width: 4),
                Text(
                  'Auditory Memory',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8E24AA),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Information Card ──
              _buildHeaderCard(fontScale),
              const SizedBox(height: 14),

              // ── Melody Demonstration / Input Display Tray ──
              _buildMelodyTray(fontScale),
              const SizedBox(height: 16),

              // ── Interactive Musical Pads ──
              _buildMusicalNotePads(fontScale),
              const SizedBox(height: 18),

              // ── Bottom Action & Results ──
              _buildActionArea(appState, fontScale, total, accuracy),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header Status Card ──
  Widget _buildHeaderCard(double fontScale) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.4)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6)],
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
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_difficulty.label.toUpperCase()} DIFFICULTY • ${_targetSequence.length} NOTES',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 11 * fontScale,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: const Color(0xFF8E24AA),
                  ),
                ),
              ),
              Text(
                'Total Score: $_cumulativeScore',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 13 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sageSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currentRound.title,
            style: GoogleFonts.newsreader(
              fontSize: 18 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoalText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _phase == MemoryMelodyPhase.playback
                ? 'Listen carefully as each note plays and illuminates...'
                : _phase == MemoryMelodyPhase.reproduction
                    ? 'Reproduce the melody notes by tapping the pads in exact order.'
                    : _phase == MemoryMelodyPhase.evaluated
                        ? 'Evaluation complete! Compare your notes with the target melody.'
                        : 'Tap Play Melody to hear the musical notes sequence.',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 13 * fontScale,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Melody Display Tray ──
  Widget _buildMelodyTray(double fontScale) {
    final isPlayback = _phase == MemoryMelodyPhase.playback;
    final isRepro = _phase == MemoryMelodyPhase.reproduction;
    final isEval = _phase == MemoryMelodyPhase.evaluated;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPlayback
              ? const Color(0xFF8E24AA)
              : AppColors.sandalwoodGold.withValues(alpha: 0.4),
          width: isPlayback ? 1.8 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isPlayback
                      ? 'PLAYING MELODY (LISTEN CAREFULLY):'
                      : isRepro
                          ? 'YOUR REPRODUCED SEQUENCE (${_userSequence.length} OF ${_targetSequence.length}):'
                          : isEval
                              ? 'MELODY ACCURACY COMPARISON:'
                              : 'TARGET MELODY SEQUENCE (${_targetSequence.length} NOTES):',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 11 * fontScale,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: isPlayback ? const Color(0xFF8E24AA) : AppColors.secondaryText,
                  ),
                ),
              ),
              if (isRepro && _userSequence.isNotEmpty)
                TextButton.icon(
                  onPressed: _removeLastUserNote,
                  icon: const Icon(Icons.backspace_outlined, size: 16, color: AppColors.terracottaPrimary),
                  label: Text(
                    'Undo',
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 12 * fontScale,
                      color: AppColors.terracottaPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Display notes in sequence
          if (isRepro) ...[
            // User notes entered so far
            if (_userSequence.isEmpty)
              Container(
                height: 54,
                alignment: Alignment.center,
                child: Text(
                  'Tap the note pads below to reproduce the melody.',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 13 * fontScale,
                    fontStyle: FontStyle.italic,
                    color: AppColors.secondaryText,
                  ),
                ),
              )
            else
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_userSequence.length, (idx) {
                  final note = _userSequence[idx];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: note.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: note.color, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          note.westernName,
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 16 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: note.color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${note.swaraName})',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 12 * fontScale,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
          ] else if (isEval) ...[
            // Side-by-side comparison of Target vs User
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target: ',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _targetSequence.map((n) => _buildBadge(n, fontScale)).toList(),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your Input: ',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(_userSequence.length, (i) {
                    final note = _userSequence[i];
                    final isCorrect = i < _targetSequence.length && note.id == _targetSequence[i].id;
                    return _buildBadge(note, fontScale, isCorrect: isCorrect);
                  }),
                ),
              ],
            ),
          ] else ...[
            // Ready or Playback mode: Show note sequence tiles
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_targetSequence.length, (idx) {
                final note = _targetSequence[idx];
                final isSoundingNow = _currentlySoundingNoteId == note.id && _isPlayingMelody;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSoundingNow
                        ? note.color
                        : note.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: note.color,
                      width: isSoundingNow ? 2.5 : 1.2,
                    ),
                    boxShadow: isSoundingNow
                        ? [BoxShadow(color: note.color.withValues(alpha: 0.4), blurRadius: 10)]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        note.westernName,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 18 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: isSoundingNow ? Colors.white : note.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        note.swaraName,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 13 * fontScale,
                          fontWeight: FontWeight.w600,
                          color: isSoundingNow ? Colors.white70 : AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(MusicalNote note, double fontScale, {bool? isCorrect}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCorrect == true
            ? AppColors.sageSecondary.withValues(alpha: 0.2)
            : isCorrect == false
                ? Colors.redAccent.withValues(alpha: 0.2)
                : note.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCorrect == true
              ? AppColors.sageSecondary
              : isCorrect == false
                  ? Colors.redAccent
                  : note.color,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${note.westernName} (${note.swaraName})',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 12 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoalText,
            ),
          ),
          if (isCorrect != null) ...[
            const SizedBox(width: 4),
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              size: 14,
              color: isCorrect ? AppColors.sageSecondary : Colors.redAccent,
            ),
          ],
        ],
      ),
    );
  }

  // ── Musical Note Touch Pads (Piano / Indian Swara keyboard) ───────────────
  Widget _buildMusicalNotePads(double fontScale) {
    final isRepro = _phase == MemoryMelodyPhase.reproduction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MUSICAL NOTE PADS (TAP TO PLAY & REPRODUCE):',
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 11 * fontScale,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: AppColors.charcoalText,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kOctaveNotes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final note = kOctaveNotes[index];
            final isPlayingThis = _currentlySoundingNoteId == note.id;

            return Material(
              color: isPlayingThis
                  ? note.color
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: isPlayingThis ? 4 : 1,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: isRepro ? () => _onUserTapNote(note) : null,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: note.color,
                      width: isPlayingThis ? 2.5 : 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            note.westernName,
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 19 * fontScale,
                              fontWeight: FontWeight.bold,
                              color: isPlayingThis ? Colors.white : note.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            note.swaraName,
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 12 * fontScale,
                              fontWeight: FontWeight.bold,
                              color: isPlayingThis ? Colors.white70 : AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Action Button & Results Card ──────────────────────────────────────────
  Widget _buildActionArea(AppState appState, double fontScale, int total, int accuracy) {
    if (_phase == MemoryMelodyPhase.ready) {
      return ElevatedButton.icon(
        onPressed: _startMelodyPlayback,
        icon: const Icon(Icons.play_circle_filled_rounded, size: 24),
        label: Text(
          'Play Melody (Listen)',
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 16 * fontScale,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8E24AA),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }

    if (_phase == MemoryMelodyPhase.playback) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8E24AA)),
            ),
            Text(
              'Playing Melody Tones...',
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 14 * fontScale,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8E24AA),
              ),
            ),
          ],
        ),
      );
    }

    if (_phase == MemoryMelodyPhase.reproduction) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _startMelodyPlayback,
              icon: const Icon(Icons.volume_up_rounded, size: 18),
              label: Text(
                'Replay Melody',
                style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold),
              ),
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
              onPressed: _userSequence.length == _targetSequence.length
                  ? () => _evaluateSequence(appState)
                  : null,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: Text(
                'Check Melody',
                style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E24AA),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    // Evaluated Phase
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _matchedNotesCount == total ? AppColors.sageSecondary : const Color(0xFF8E24AA),
          width: 1.5,
        ),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6)],
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Icon(
                _matchedNotesCount == total ? Icons.music_note_rounded : Icons.graphic_eq_rounded,
                color: _matchedNotesCount == total ? AppColors.sageSecondary : const Color(0xFF8E24AA),
                size: 28,
              ),
              Text(
                _matchedNotesCount == total
                    ? 'Perfect Melody Recall!'
                    : '$_matchedNotesCount of $total notes correct.',
                style: GoogleFonts.newsreader(
                  fontSize: 18 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoalText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Accuracy: $accuracy%',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 14 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _tryAgain,
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: Text(
                    'Try Again',
                    style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold),
                  ),
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
                  onPressed: _nextRound,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    _difficulty != GameDifficulty.hard ? 'Next Difficulty' : 'Play Again',
                    style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E24AA),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
