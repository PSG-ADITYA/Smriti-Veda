import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_veda/utils/sanskrit_pronunciation_preprocessor.dart';

void main() {
  group('SanskritPronunciationPreprocessor Tests', () {
    test('Preprocesses Avagraha and Dandas into natural pauses', () {
      const rawVerse = 'ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम् । उर्वारुकमिव बन्धनान्मृत्योर्मुक्षीय माऽमृतात् ॥';
      final processed = SanskritPronunciationPreprocessor.preprocessForTts(rawVerse);

      // Om normalized
      expect(processed.contains('ओम्'), isTrue);
      // Danda replaced with pause
      expect(processed.contains('।'), isFalse);
      expect(processed.contains(', '), isTrue);
      // Double danda replaced with cadence pause
      expect(processed.contains('॥'), isFalse);
      expect(processed.contains('...'), isTrue);
      // Avagraha normalized
      expect(processed.contains('ऽ'), isFalse);
      expect(processed.contains('मा अमृतात्'), isTrue);
    });

    test('Splits traditional verse into natural breath padas (quarter-verses)', () {
      const rawGayatri = 'ॐ भूर्भुवः स्वः । तत्सवितुर्वरेण्यं । भर्गो देवस्य धीमहि । धियो यो नः प्रचोदयात् ॥';
      final padas = SanskritPronunciationPreprocessor.splitIntoPadas(rawGayatri);

      expect(padas.length, equals(4));
      expect(padas[0].contains('ओम् भूर्भुवः स्वः'), isTrue);
      expect(padas[1].contains('तत्सवितुर्वरेण्यं'), isTrue);
      expect(padas[2].contains('भर्गो देवस्य धीमहि'), isTrue);
      expect(padas[3].contains('धियो यो नः प्रचोदयात्'), isTrue);
    });

    test('Returns appropriate calm pacing rate for Vedic mantras vs general prose', () {
      final mantraRate = SanskritPronunciationPreprocessor.getRecommendedSpeechRate(languageCode: 'sa', category: 'Mantra');
      final generalRate = SanskritPronunciationPreprocessor.getRecommendedSpeechRate(languageCode: 'en', category: 'Prose');

      expect(mantraRate, equals(0.35));
      expect(generalRate, equals(0.38));
    });
  });
}
