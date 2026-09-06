import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum PronunciationMode {
  continuous,
  padachhedaSyllable,
  kramaPaired,
}

enum VoiceStyle {
  sanskritPandit,  // Deep, calm, measured, rhythmic traditional recitation
  modernNarrator,  // Clear, neutral modern narrator
}

class SanskritPronunciationService {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  SanskritPronunciationService() {
    _initTts();
  }

  void _initTts() async {
    try {
      await _tts.setLanguage('hi-IN');
      await _tts.setSpeechRate(0.38);
      await _tts.setPitch(0.85); // Deep, calm, traditional voice timbre

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS Error: $msg');
      });
    } catch (e) {
      debugPrint('Sanskrit TTS initialization error: $e');
    }
  }

  /// Configures voice style parameters
  Future<void> setVoiceStyle(VoiceStyle style) async {
    if (style == VoiceStyle.sanskritPandit) {
      await _tts.setLanguage('hi-IN');
      await _tts.setSpeechRate(0.38); // Measured, rhythmic chanting pace
      await _tts.setPitch(0.85);      // Resonant, deep traditional tone
    } else {
      await _tts.setLanguage('en-IN');
      await _tts.setSpeechRate(0.50); // Standard modern narrator rate
      await _tts.setPitch(1.00);      // Neutral pitch
    }
  }

  /// Pronounces traditional recitation according to Sanskrit chanting modes
  Future<void> pronounceMantra({
    required String text,
    required PronunciationMode mode,
    VoiceStyle voiceStyle = VoiceStyle.sanskritPandit,
    VoidCallback? onWordSpoken,
  }) async {
    await stop();
    await setVoiceStyle(voiceStyle);

    final cleanText = text.replaceAll(RegExp(r'[।॥\.\,\-\?\!]'), ' ').trim();

    switch (mode) {
      case PronunciationMode.continuous:
        await _tts.speak(cleanText);
        break;

      case PronunciationMode.padachhedaSyllable:
        final words = cleanText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        await _tts.setSpeechRate(0.28);
        for (var word in words) {
          await _tts.speak(word);
          await Future.delayed(const Duration(milliseconds: 900));
        }
        break;

      case PronunciationMode.kramaPaired:
        final words = cleanText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        await _tts.setSpeechRate(0.32);
        for (int i = 0; i < words.length - 1; i++) {
          final pair = '${words[i]} ${words[i + 1]}';
          await _tts.speak(pair);
          await Future.delayed(const Duration(milliseconds: 1100));
        }
        break;
    }
  }

  /// Speaks modern app instructions using narrator voice
  Future<void> speakInstruction(String text, {String lang = 'en-IN'}) async {
    await stop();
    await setVoiceStyle(VoiceStyle.modernNarrator);
    await _tts.setLanguage(lang);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }
}
