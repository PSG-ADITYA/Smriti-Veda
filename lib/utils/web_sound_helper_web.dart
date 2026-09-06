// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

void initWebAudio() {
  try {
    final ctor = js.context['AudioContext'] ?? js.context['webkitAudioContext'];
    if (ctor != null) {
      js.JsObject(ctor, []);
    }
  } catch (e) {
    debugPrint('WebAudio init error: ');
  }
}

dynamic getAudioContext(dynamic currentCtx) {
  if (currentCtx == null) {
    try {
      final ctor = js.context['AudioContext'] ?? js.context['webkitAudioContext'];
      if (ctor != null) {
        currentCtx = js.JsObject(ctor, []);
      }
    } catch (_) {}
  }
  if (currentCtx != null) {
    try {
      if (currentCtx['state'] == 'suspended') {
        currentCtx.callMethod('resume');
      }
    } catch (_) {}
  }
  return currentCtx;
}

void playWebTone({
  required dynamic audioCtx,
  required double frequency,
  required double durationSeconds,
  String type = 'sine',
  double targetFrequency = 0.0,
  double volume = 0.15,
}) {
  try {
    final ctx = getAudioContext(audioCtx);
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
    osc.callMethod('stop', [now + durationSeconds + 0.05]);
  } catch (e) {
    debugPrint('Audio tone warning: ');
  }
}

void speakWeb(String text, String targetLang) {
  try {
    final synth = js.context['speechSynthesis'];
    if (synth != null) {
      synth.callMethod('cancel');
      final utterance = js.JsObject(js.context['SpeechSynthesisUtterance'], [text]);
      utterance['lang'] = targetLang;
      utterance['rate'] = 0.88;
      utterance['pitch'] = 1.05;

      try {
        final voices = synth.callMethod('getVoices');
        if (voices != null && voices['length'] != null) {
          final int len = voices['length'] as int;
          dynamic chosenVoice;
          for (int i = 0; i < len; i++) {
            final v = voices[i];
            final String name = (v['name'] ?? '').toString().toLowerCase();
            final String lang = (v['lang'] ?? '').toString().toLowerCase();
            final bool isFemale = name.contains('female') ||
                name.contains('zira') ||
                name.contains('heera') ||
                name.contains('samantha') ||
                name.contains('karen') ||
                name.contains('victoria') ||
                name.contains('priya') ||
                name.contains('swara') ||
                name.contains('veena');
            if (isFemale && lang.startsWith(targetLang.toLowerCase().substring(0, 2))) {
              chosenVoice = v;
              break;
            }
          }
          if (chosenVoice == null) {
            for (int i = 0; i < len; i++) {
              final v = voices[i];
              final String name = (v['name'] ?? '').toString().toLowerCase();
              if (name.contains('female') ||
                  name.contains('zira') ||
                  name.contains('samantha') ||
                  name.contains('karen') ||
                  name.contains('victoria')) {
                chosenVoice = v;
                break;
              }
            }
          }
          if (chosenVoice != null) {
            utterance['voice'] = chosenVoice;
          }
        }
      } catch (_) {}

      utterance['onerror'] = (dynamic e) {
        debugPrint('Web Speech Synthesis notice: ');
      };
      synth.callMethod('speak', [utterance]);
    }
  } catch (e) {
    debugPrint('Web Speech Synthesis Error: ');
  }
}

void stopWebSpeech() {
  try {
    final synth = js.context['speechSynthesis'];
    if (synth != null) {
      synth.callMethod('cancel');
    }
  } catch (_) {}
}
