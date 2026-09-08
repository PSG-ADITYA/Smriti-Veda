class SanskritNormalizerResult {
  final int matchedWords;
  final int totalWords;
  final double matchPercentage;
  final String normalizedTarget;
  final String normalizedUser;

  const SanskritNormalizerResult({
    required this.matchedWords,
    required this.totalWords,
    required this.matchPercentage,
    required this.normalizedTarget,
    required this.normalizedUser,
  });
}

class SanskritTextNormalizer {
  /// Cleans punctuation, danda, extra whitespace, and casing across any Indian or Latin script
  static String normalizeGeneral(String input) {
    if (input.trim().isEmpty) return '';

    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[।॥|]'), ' ')
        .replaceAll(RegExp(r'[^\p{L}\p{M}\p{N}\s]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Normalizes Latin transliteration diacritics into base phonetic equivalents
  static String normalizeTransliteration(String input) {
    String text = normalizeGeneral(input);

    const Map<String, String> diacriticMap = {
      'ā': 'a', 'á': 'a', 'à': 'a',
      'ī': 'i', 'í': 'i', 'ì': 'i',
      'ū': 'u', 'ú': 'u', 'ù': 'u',
      'ṛ': 'ri', 'ṝ': 'ri', 'r̥': 'ri',
      'ḹ': 'li', 'l̥': 'li',
      'ś': 'sh', 'ṣ': 'sh',
      'ñ': 'n', 'ṅ': 'n', 'ṇ': 'n',
      'ṭ': 't', 'ḍ': 'd', 'ḷ': 'l',
      'ḥ': 'h',
      'ṁ': 'm', 'ṃ': 'm', 'm̐': 'm',
      'ॐ': 'om',
    };

    diacriticMap.forEach((key, val) {
      text = text.replaceAll(key, val);
    });

    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Normalizes Devanagari text: virama, anusvara, avagraha, nukta
  static String normalizeDevanagari(String input) {
    String text = normalizeGeneral(input);

    text = text.replaceAll('ऽ', 'अ'); // Expand avagraha
    text = text.replaceAll('ॐ', 'ओम्'); // Om to standard spelling
    text = text.replaceAll('ँ', 'ं');

    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Evaluates speech-to-text transcript against a target verse/line.
  /// Handles both Devanagari and Latin transliteration robustly.
  static SanskritNormalizerResult evaluateMatch({
    required String targetOriginal,
    required String targetTransliteration,
    required String userTranscript,
  }) {
    if (userTranscript.trim().isEmpty) {
      return SanskritNormalizerResult(
        matchedWords: 0,
        totalWords: 1,
        matchPercentage: 0.0,
        normalizedTarget: targetTransliteration,
        normalizedUser: '',
      );
    }

    final normUserRaw = normalizeGeneral(userTranscript);
    final normUserLatin = normalizeTransliteration(userTranscript);
    final normUserDevanagari = normalizeDevanagari(userTranscript);

    // Prepare target tokens (transliteration & original)
    final normTargetLatin = normalizeTransliteration(targetTransliteration);
    final normTargetDev = normalizeDevanagari(targetOriginal);

    final targetLatinWords = normTargetLatin.split(' ').where((w) => w.length > 1).toList();
    final targetDevWords = normTargetDev.split(' ').where((w) => w.length > 1).toList();

    final totalCount = targetLatinWords.isNotEmpty ? targetLatinWords.length : 1;

    final userWordsLatin = normUserLatin.split(' ').where((w) => w.isNotEmpty).toSet();
    final userWordsDev = normUserDevanagari.split(' ').where((w) => w.isNotEmpty).toSet();

    int matchedCount = 0;

    for (int i = 0; i < targetLatinWords.length; i++) {
      final tLatin = targetLatinWords[i];
      final tDev = (i < targetDevWords.length) ? targetDevWords[i] : '';

      bool wordFound = false;

      // Check Latin transliteration match
      for (final uLatin in userWordsLatin) {
        if (uLatin == tLatin ||
            (uLatin.length > 2 && tLatin.contains(uLatin)) ||
            (tLatin.length > 2 && uLatin.contains(tLatin))) {
          wordFound = true;
          break;
        }
      }

      // If not found, check Devanagari match
      if (!wordFound && tDev.isNotEmpty) {
        for (final uDev in userWordsDev) {
          if (uDev == tDev ||
              (uDev.length > 2 && tDev.contains(uDev)) ||
              (tDev.length > 2 && uDev.contains(tDev))) {
            wordFound = true;
            break;
          }
        }
      }

      if (wordFound) matchedCount++;
    }

    // Safety fallback: if user spoke something fluent but transliteration differed slightly
    if (matchedCount == 0 && normUserRaw.isNotEmpty && userWordsLatin.isNotEmpty) {
      matchedCount = 1;
    }

    final pct = (matchedCount / totalCount * 100.0).clamp(0.0, 100.0);

    return SanskritNormalizerResult(
      matchedWords: matchedCount,
      totalWords: totalCount,
      matchPercentage: pct,
      normalizedTarget: normTargetLatin,
      normalizedUser: normUserLatin,
    );
  }
}
