import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum PronunciationMode {
  continuous,
  padachhedaSyllable,
  kramaPaired,
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
      await _tts.setSpeechRate(0.35); // Slow, clear rate for elderly ears
      await _tts.setPitch(1.0);

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

  /// Pronounces the mantra according to traditional Sanskrit chanting modes
  Future<void> pronounceMantra({
    required String text,
    required PronunciationMode mode,
    VoidCallback? onWordSpoken,
  }) async {
    await stop();

    final cleanText = text.replaceAll(RegExp(r'[।॥\.\,\-\?\!]'), ' ').trim();

    switch (mode) {
      case PronunciationMode.continuous:
        await _tts.setSpeechRate(0.38);
        await _tts.speak(cleanText);
        break;

      case PronunciationMode.padachhedaSyllable:
        // Word-by-Word slow spell-out
        final words = cleanText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        await _tts.setSpeechRate(0.28); // Extra slow syllable pacing
        for (var word in words) {
          await _tts.speak(word);
          await Future.delayed(const Duration(milliseconds: 900));
        }
        break;

      case PronunciationMode.kramaPaired:
        // Paired Krama Step Pronunciation (AB, BC, CD)
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

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }
}
