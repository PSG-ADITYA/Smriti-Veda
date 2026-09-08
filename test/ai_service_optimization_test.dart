import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_veda/services/gemini_service.dart';
import 'package:smriti_veda/services/ai_service.dart';
import 'package:smriti_veda/services/song_generation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Step 8 - AI Service & Gemini Optimization Tests', () {
    test('GeminiService offline fallback returns valid game template without hanging', () async {
      final gemini = GeminiService(apiKey: ''); // No API key -> offline template
      final game = await gemini.generatePersonalizedGame(
        patientName: 'Shri Ramachandra',
        eraPreference: '1970s Classic Music',
        relativeNames: ['Lakshmi', 'Ravi'],
        favoriteMemories: 'Temple visits and classical concerts',
        cognitiveFocus: 'Pictorial & Object Recall',
      );

      expect(game.title, isNotEmpty);
      expect(game.targetItems, isNotEmpty);
      expect(game.distractorItems, isNotEmpty);
      expect(game.quizQuestions, isNotEmpty);
      expect(game.quizAnswers, isNotEmpty);

      // Verify that calling again returns the cached instance
      final cachedGame = await gemini.generatePersonalizedGame(
        patientName: 'Shri Ramachandra',
        eraPreference: '1970s Classic Music',
        relativeNames: ['Lakshmi', 'Ravi'],
        favoriteMemories: 'Temple visits and classical concerts',
        cognitiveFocus: 'Pictorial & Object Recall',
      );

      expect(identical(game, cachedGame), isTrue);
    });

    test('GeminiService conversational returns empathetic elder-friendly response with caching', () async {
      final gemini = GeminiService(apiKey: '');
      final response1 = await gemini.askGeminiConversational(
        userPrompt: 'How can I keep my mind active in the morning?',
        patientName: 'Dada-ji',
        language: 'Hindi',
      );

      expect(response1, isNotEmpty);
      expect(response1.contains('Dada-ji'), isTrue);

      final response2 = await gemini.askGeminiConversational(
        userPrompt: 'How can I keep my mind active in the morning?',
        patientName: 'Dada-ji',
        language: 'Hindi',
      );

      expect(response1, equals(response2));
    });

    test('GeminiOmniRouteAiService personalized plan caching and deterministic fallback', () async {
      final aiService = GeminiOmniRouteAiService();
      final plan1 = await aiService.generatePersonalizedPlan(
        patientName: 'Kavita Devi',
        age: '74',
        cognitiveGoal: 'Improve daily memory and focus',
        language: 'Sanskrit',
        relatives: 'Aarav, Meera',
        memoriesAndHobbies: 'Morning walks and sitar music',
      );

      expect(plan1, contains('Kavita Devi'));
      expect(plan1, contains('Sanskrit'));

      final plan2 = await aiService.generatePersonalizedPlan(
        patientName: 'Kavita Devi',
        age: '74',
        cognitiveGoal: 'Improve daily memory and focus',
        language: 'Sanskrit',
        relatives: 'Aarav, Meera',
        memoriesAndHobbies: 'Morning walks and sitar music',
      );

      expect(plan1, equals(plan2));
    });

    test('SongGenerationService returns curated songs instantly with caching', () async {
      final songService = SongGenerationService();
      final song1 = await songService.generateSong(
        theme: 'Morning Temple Bells',
        language: 'Hindi',
        difficulty: 'Easy',
        patientName: 'Grandma',
      );

      expect(song1.title, isNotEmpty);
      expect(song1.lyrics, isNotEmpty);
      expect(song1.events, isNotEmpty);
      expect(song1.questions, isNotEmpty);

      final song2 = await songService.generateSong(
        theme: 'Morning Temple Bells',
        language: 'Hindi',
        difficulty: 'Easy',
        patientName: 'Grandma',
      );

      expect(identical(song1, song2), isTrue);
    });
  });
}
