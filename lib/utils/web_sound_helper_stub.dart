// Stub implementation of Web Audio and Speech Synthesis for Android / Native platforms
void initWebAudio() {}
dynamic getAudioContext(dynamic currentCtx) => null;
void playWebTone({
  required dynamic audioCtx,
  required double frequency,
  required double durationSeconds,
  String type = 'sine',
  double targetFrequency = 0.0,
  double volume = 0.15,
}) {}
void speakWeb(String text, String targetLang) {}
void stopWebSpeech() {}
