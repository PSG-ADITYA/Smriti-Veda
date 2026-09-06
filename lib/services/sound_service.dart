import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../utils/web_sound_helper.dart';

class SoundService extends ChangeNotifier {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;

  SoundService._internal() {
    _initTts();
    _initWebAudio();
  }

  final FlutterTts _tts = FlutterTts();
  dynamic _audioCtx;
  bool _isBgmActive = false;
  dynamic _bgmGainNode;
  dynamic _bgmOsc1;
  dynamic _bgmOsc2;

  bool get isBgmActive => _isBgmActive;

  void _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.40); // Gentle pacing for seniors
      await _tts.setPitch(1.0);
    } catch (e) {
      debugPrint('TTS init warning: $e');
    }
  }

  void _initWebAudio() {
    if (!kIsWeb) return;
    initWebAudio();
  }

  dynamic _getAudioContext() {
    if (!kIsWeb) return null;
    _audioCtx = getAudioContext(_audioCtx);
    return _audioCtx;
  }

  /// Plays synthesized audio frequency tone with envelope (non-blocking)
  void _playTone({
    required double frequency,
    required double durationSeconds,
    String type = 'sine',
    double targetFrequency = 0.0,
    double volume = 0.15,
  }) {
    if (!kIsWeb) return;
    Future.microtask(() {
      try {
        final ctx = _getAudioContext();
        if (ctx == null) return;

        final osc = ctx.callMethod('createOscillator');
        final gain = ctx.callMethod('createGain');

        osc['type'] = type;
        final now = ctx['currentTime'] ?? 0;
        final oscFreq = osc['frequency'];
        oscFreq.callMethod('setValueAtTime', [frequency, now]);

        if (targetFrequency > 0) {
          oscFreq.callMethod('exponentialRampToValueAtTime', [targetFrequency, now + durationSeconds]);
        }

        final gainValue = gain['gain'];
        gainValue.callMethod('setValueAtTime', [volume, now]);
        gainValue.callMethod('exponentialRampToValueAtTime', [0.0001, now + durationSeconds]);

        osc.callMethod('connect', [gain]);
        gain.callMethod('connect', [ctx['destination']]);

        osc.callMethod('start', [now]);
        osc.callMethod('stop', [now + durationSeconds]);
      } catch (e) {
        debugPrint('Audio tone warning: $e');
      }
    });
  }

  // ── Real Sound Effects (Click, Success, Error, Fanfare, Flip) ─────────────

  /// Touch / Tap Sound Feedback (1000Hz -> 500Hz)
  void playTapSound() {
    if (!kIsWeb) {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.selectionClick();
      return;
    }
    _playTone(
      frequency: 1000,
      targetFrequency: 500,
      durationSeconds: 0.04,
      volume: 0.12,
    );
  }

  void playClickSound() => playTapSound();

  /// Card Flip / Swoosh Sound
  void playFlipSound() {
    if (!kIsWeb) {
      HapticFeedback.lightImpact();
      return;
    }
    _playTone(
      frequency: 380,
      targetFrequency: 820,
      durationSeconds: 0.08,
      volume: 0.10,
    );
  }

  /// Soft Error Buzzer (240Hz -> 140Hz)
  void playErrorSound() {
    if (!kIsWeb) {
      HapticFeedback.heavyImpact();
      return;
    }
    _playTone(
      frequency: 240,
      targetFrequency: 140,
      type: 'sawtooth',
      durationSeconds: 0.20,
      volume: 0.08,
    );
  }

  /// Success Chime (C5 - E5 - G5 - C6 Chord Sequence)
  void playSuccessSound() {
    if (!kIsWeb) {
      HapticFeedback.mediumImpact();
      return;
    }
    final notes = [523.25, 659.25, 783.99, 1046.50];
    for (int i = 0; i < notes.length; i++) {
      Future.delayed(Duration(milliseconds: i * 70), () {
        _playTone(
          frequency: notes[i],
          durationSeconds: 0.25,
          volume: 0.14,
        );
      });
    }
  }

  /// Achievement Victory Fanfare Music
  void playFanfareSound() {
    if (!kIsWeb) {
      HapticFeedback.heavyImpact();
      return;
    }
    final melody = [
      {'freq': 523.25, 'delay': 0, 'dur': 0.12},
      {'freq': 659.25, 'delay': 110, 'dur': 0.12},
      {'freq': 783.99, 'delay': 220, 'dur': 0.12},
      {'freq': 1046.50, 'delay': 350, 'dur': 0.22},
      {'freq': 783.99, 'delay': 580, 'dur': 0.14},
      {'freq': 1046.50, 'delay': 740, 'dur': 0.55},
    ];

    for (final note in melody) {
      Future.delayed(Duration(milliseconds: (note['delay'] as num).toInt()), () {
        _playTone(
          frequency: (note['freq'] as num).toDouble(),
          durationSeconds: (note['dur'] as num).toDouble(),
          volume: 0.16,
        );
      });
    }
  }

  // ── Ambient Background Music (BGM) Drone Synth ─────────────────────────────

  void toggleBgm() {
    if (_isBgmActive) {
      stopBgm();
    } else {
      startBgm();
    }
  }

  void startBgm() {
    if (!kIsWeb) return;
    try {
      final ctx = _getAudioContext();
      if (ctx == null) return;

      stopBgm();

      _bgmGainNode = ctx.callMethod('createGain');
      final now = ctx['currentTime'] ?? 0;
      final g = _bgmGainNode['gain'];
      g.callMethod('setValueAtTime', [0.001, now]);
      g.callMethod('linearRampToValueAtTime', [0.035, now + 1.5]); // Smooth ambient swell

      // Dual harmonic drone tuned to 432Hz serene scale
      _bgmOsc1 = ctx.callMethod('createOscillator');
      _bgmOsc2 = ctx.callMethod('createOscillator');

      _bgmOsc1['type'] = 'sine';
      _bgmOsc1['frequency'].callMethod('setValueAtTime', [216.0, now]); // A3 drone

      _bgmOsc2['type'] = 'sine';
      _bgmOsc2['frequency'].callMethod('setValueAtTime', [432.0, now]); // A4 harmonic

      _bgmOsc1.callMethod('connect', [_bgmGainNode]);
      _bgmOsc2.callMethod('connect', [_bgmGainNode]);
      _bgmGainNode.callMethod('connect', [ctx['destination']]);

      _bgmOsc1.callMethod('start', [now]);
      _bgmOsc2.callMethod('start', [now]);

      _isBgmActive = true;
      notifyListeners();
    } catch (e) {
      debugPrint('BGM Start Error: $e');
    }
  }

  void stopBgm() {
    if (!kIsWeb) return;
    try {
      if (_bgmGainNode != null && _audioCtx != null) {
        final now = _audioCtx['currentTime'] ?? 0;
        _bgmGainNode['gain'].callMethod('linearRampToValueAtTime', [0.0001, now + 0.5]);
      }
      Timer(const Duration(milliseconds: 550), () {
        try {
          _bgmOsc1?.callMethod('stop');
          _bgmOsc2?.callMethod('stop');
          _bgmOsc1?.callMethod('disconnect');
          _bgmOsc2?.callMethod('disconnect');
        } catch (_) {}
        _bgmOsc1 = null;
        _bgmOsc2 = null;
        _bgmGainNode = null;
      });
      _isBgmActive = false;
      notifyListeners();
    } catch (e) {
      debugPrint('BGM Stop Error: $e');
    }
  }

  void speakText(String text, {String languageCode = 'hi'}) async {
    if (text.trim().isEmpty) return;
    stopSpeaking();

    String targetLang = 'hi-IN';
    final code = languageCode.toLowerCase().trim();
    if (code == 'hi' || code == 'hindi' || code == 'sa' || code == 'sanskrit') {
      targetLang = 'hi-IN';
    } else if (code == 'te' || code == 'telugu') {
      targetLang = 'te-IN';
    } else if (code == 'ta' || code == 'tamil') {
      targetLang = 'ta-IN';
    } else if (code == 'bn' || code == 'bengali' || code == 'as' || code == 'assamese') {
      targetLang = 'bn-IN';
    } else if (code == 'en' || code == 'english') {
      targetLang = 'en-IN';
    } else {
      targetLang = code.contains('-') ? code : '$code-IN';
    }

    if (kIsWeb) {
      speakWeb(text, targetLang);
      return;
    }

    try {
      await _tts.setLanguage(targetLang);
      await _tts.setSpeechRate(0.40);
      try {
        final voices = await _tts.getVoices;
        if (voices is List) {
          for (final v in voices) {
            if (v is Map) {
              final name = (v['name'] ?? '').toString().toLowerCase();
              if (name.contains('female') ||
                  name.contains('zira') ||
                  name.contains('samantha') ||
                  name.contains('heera') ||
                  name.contains('priya') ||
                  name.contains('swara') ||
                  name.contains('veena')) {
                await _tts.setVoice({'name': v['name'], 'locale': v['locale']});
                break;
              }
            }
          }
        }
      } catch (_) {}
      await _tts.speak(text);
    } catch (e) {
      debugPrint('FlutterTts speak error: $e');
    }
  }

  void stopSpeaking() async {
    if (kIsWeb) {
      stopWebSpeech();
    }
    try {
      await _tts.stop();
    } catch (_) {}
  }

  // Static helper wrappers for easy access anywhere in app
  static void playTap() => _instance.playTapSound();
  static void playSuccess() => _instance.playSuccessSound();
  static void playError() => _instance.playErrorSound();
  static void playFanfare() => _instance.playFanfareSound();
  static void playFlip() => _instance.playFlipSound();
  static void speak(String text, {String languageCode = 'en-US'}) => _instance.speakText(text, languageCode: languageCode);
  static void stop() => _instance.stopSpeaking();
}
