import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_veda/utils/sanskrit_text_normalizer.dart';

void main() {
  group('SanskritTextNormalizer Tests', () {
    test('Cleans punctuation, danda, and extra whitespace cleanly', () {
      const raw = 'ॐ भूर्भुवः स्वः । तत्सवितुर्वरेण्यं ॥';
      final cleaned = SanskritTextNormalizer.normalizeGeneral(raw);
      expect(cleaned.contains('।'), isFalse);
      expect(cleaned.contains('॥'), isFalse);
      expect(cleaned.contains('भूर्भुवः'), isTrue);
    });

    test('Normalizes Sanskrit transliteration diacritics to phonetic ASCII', () {
      const transliteration = 'Oṁ Bhūr Bhuvaḥ Svaḥ Tat Savitur Vareṇyaṁ';
      final norm = SanskritTextNormalizer.normalizeTransliteration(transliteration);
      expect(norm, equals('om bhur bhuvah svah tat savitur varenyam'));
    });

    test('Evaluates matching speech transcript against Sanskrit verse accurately', () {
      const original = 'ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं';
      const transliteration = 'Om Bhur Bhuvah Svah Tat Savitur Varenyam';
      const userSpoken = 'om bhur bhuvah svah tat savitur varenyam';

      final result = SanskritTextNormalizer.evaluateMatch(
        targetOriginal: original,
        targetTransliteration: transliteration,
        userTranscript: userSpoken,
      );

      expect(result.matchedWords, greaterThanOrEqualTo(5));
      expect(result.matchPercentage, greaterThanOrEqualTo(80.0));
    });

    test('Tolerates STT punctuation differences and diacritics without failing user', () {
      const original = 'ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम्';
      const transliteration = 'Oṁ Tryambakaṁ Yajāmahe Sugandhiṁ Puṣṭi-Vardhanam';
      // User spoken with commas, period, and plain ASCII
      const userSpoken = 'Om, tryambakam yajamahe... sugandhim pushti vardhanam!';

      final result = SanskritTextNormalizer.evaluateMatch(
        targetOriginal: original,
        targetTransliteration: transliteration,
        userTranscript: userSpoken,
      );

      expect(result.matchedWords, greaterThanOrEqualTo(4));
      expect(result.matchPercentage, greaterThanOrEqualTo(75.0));
    });
  });
}
