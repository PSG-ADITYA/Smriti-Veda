class SanskritPronunciationPreprocessor {
  /// Preprocesses Sanskrit/Devanagari text for natural TTS recitation.
  /// Replaces raw typographical ligatures with pronunciation-friendly cadence markers.
  static String preprocessForTts(String rawText, {String languageCode = 'sa'}) {
    if (rawText.trim().isEmpty) return '';

    String text = rawText.trim();

    // 1. Avagraha (ऽ) handling:
    // In TTS, ऽ is often mispronounced as "apostrophe".
    // Replace with a natural breath pause or elided vowel sound.
    text = text.replaceAll('माऽमृतात्', 'मा अमृतात्');
    text = text.replaceAll('ऽ', ' ');

    // 2. Danda and Double Danda pausing:
    // Single danda । = 400ms half-verse breath pause (ardha-shloka)
    // Double danda ॥ = 800ms full verse completion pause (purna-shloka)
    text = text.replaceAll(RegExp(r'\s*॥\s*'), '... ');
    text = text.replaceAll(RegExp(r'\s*।\s*'), ', ');

    // 3. Om (ॐ) pronunciation normalization:
    // Ensure clean sacred syllable articulation without glitching
    text = text.replaceAll('ॐ', 'ओम् ');

    // 4. Clean superfluous characters
    text = text.replaceAll(RegExp(r'[-_~]'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  /// Splits a traditional Sanskrit verse into natural recitation padas (quarter-verses).
  /// Each pada corresponds to a natural breath cycle in Vedic recitation.
  static List<String> splitIntoPadas(String verseText) {
    if (verseText.trim().isEmpty) return [];

    // Split on danda, double danda, newlines, or semicolons
    final rawChunks = verseText.split(RegExp(r'[।॥;\n]'));
    final padas = <String>[];

    for (final c in rawChunks) {
      final processed = preprocessForTts(c);
      if (processed.isNotEmpty && processed.length > 2) {
        padas.add(processed);
      }
    }

    if (padas.isEmpty && verseText.trim().isNotEmpty) {
      padas.add(preprocessForTts(verseText));
    }

    return padas;
  }

  /// Returns recommended speech rate for the given content type.
  /// Traditional mantras require a slow, calm, dignified pacing (0.35).
  static double getRecommendedSpeechRate({String languageCode = 'sa', String category = 'Mantra'}) {
    if (category.toLowerCase() == 'mantra' || languageCode.toLowerCase() == 'sa') {
      return 0.35; // Calm, meditative Vedic pacing
    }
    return 0.38; // Dignified senior pacing
  }
}
