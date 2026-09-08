import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smriti_veda/locales/app_localizations.dart';
import 'package:smriti_veda/models/cultural_content.dart';
import 'package:smriti_veda/models/game_difficulty.dart';
import 'package:smriti_veda/providers/app_state.dart';
import 'package:smriti_veda/screens/cultural_pipeline_screen.dart';
import 'package:smriti_veda/screens/smritiveda_chatbot_screen.dart';
import 'package:smriti_veda/services/ai_provider.dart';
import 'package:smriti_veda/widgets/difficulty_selector.dart';
import 'package:smriti_veda/widgets/languages_section.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Game Difficulty Architecture Tests', () {
    test('GameDifficulty labels and descriptions are accessible and non-diagnostic', () {
      expect(GameDifficulty.easy.label, 'Easy');
      expect(GameDifficulty.medium.label, 'Medium');
      expect(GameDifficulty.hard.label, 'Hard');

      for (final diff in GameDifficulty.values) {
        expect(diff.description, isNotEmpty);
        expect(diff.description.toLowerCase(), isNot(contains('dementia')));
        expect(diff.description.toLowerCase(), isNot(contains('decline')));
      }
    });

    testWidgets('DifficultySelector toggles active difficulty with tap sound feedback', (tester) async {
      GameDifficulty current = GameDifficulty.easy;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DifficultySelector(
                  selected: current,
                  onChanged: (d) => setState(() => current = d),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Easy'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Hard'), findsOneWidget);

      await tester.tap(find.text('Hard'));
      await tester.pumpAndSettle();

      expect(current, GameDifficulty.hard);
    });
  });

  group('2. Multi-Language System Tests', () {
    test('AppLocalizations retrieves localized strings across English, Telugu, Hindi, and Sanskrit', () {
      expect(AppLocalizations.getDirect('en', 'app_title'), 'SmritiVeda');
      expect(AppLocalizations.getDirect('te', 'app_title'), 'స్మృతివేద');
      expect(AppLocalizations.getDirect('hi', 'app_title'), 'स्मृतिवेद');
      expect(AppLocalizations.getDirect('sa', 'app_title'), 'स्मृतिवेदः');

      // Test fallback to English
      expect(AppLocalizations.getDirect('te', 'unknown_key_xyz', fallback: 'FallbackText'), 'FallbackText');
    });

    testWidgets('LanguagesSection renders native script cards and updates AppState', (tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        MaterialApp(
          home: AppStateScope(
            state: appState,
            child: const Scaffold(
              body: LanguagesSection(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Native cards
      expect(find.text('English'), findsOneWidget);
      expect(find.text('తెలుగు'), findsOneWidget);
      expect(find.text('हिन्दी'), findsOneWidget);
      expect(find.text('संस्कृतम्'), findsOneWidget);

      // Tap Telugu
      await tester.tap(find.text('తెలుగు'));
      await tester.pumpAndSettle();

      expect(appState.selectedLanguage, 'te');
    });
  });

  group('3. Progressive Shloka Recitation Accessibility Tests', () {
    final sampleItem = CulturalContentItem(
      id: 'gayatri_test',
      category: 'Verse',
      title: 'Gayatri Mantra',
      originalScriptText: 'ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि धियो यो नः प्रचोदयात्',
      transliteration: 'om bhur bhuvah svah\ntat savitur varenyam\nbhargo devasya dhimahi\ndhiyo yo nah pracodayat',
      englishMeaning: 'We meditate on the spiritual radiance of the divine source of light.',
      englishExplanation: 'Traditional Vedic chant for wisdom and cognitive vitality.',
      cognitivePurpose: 'Sequential auditory recall and breath pacing',
      chunks: [
        'ॐ भूर्भुवः स्वः',
        'तत्सवितुर्वरेण्यं',
        'भर्गो देवस्य धीमहि',
        'धियो यो नः प्रचोदयात्',
      ],
      languageCode: 'sa',
    );

    testWidgets('CulturalPipelineScreen supports Listen, Echo, Recall, and Arrange modes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      final appState = AppState();

      await tester.pumpWidget(
        MaterialApp(
          home: AppStateScope(
            state: appState,
            child: CulturalPipelineScreen(item: sampleItem),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Script tabs visible
      expect(find.text('संस्कृत'), findsWidgets);
      expect(find.text('Transliteration'), findsOneWidget);
      expect(find.text('Meaning'), findsOneWidget);

      // 2. Practice mode tabs
      expect(find.text('🎧 Listen'), findsOneWidget);
      expect(find.text('🗣️ Echo'), findsOneWidget);
      expect(find.text('🧩 Recall'), findsOneWidget);
      expect(find.text('🔀 Arrange'), findsOneWidget);

      // 3. Switch to Echo Mode
      await tester.tap(find.text('🗣️ Echo'));
      await tester.pumpAndSettle();

      expect(find.textContaining('PHRASE 1 OF 4'), findsOneWidget);
      expect(find.text('I recited this phrase (Tap to Confirm)'), findsOneWidget);

      // Tap manual recitation confirmation (voice alternative)
      await tester.tap(find.text('I recited this phrase (Tap to Confirm)'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Well recited!'), findsOneWidget);
      expect(find.text('Next Phrase ➔'), findsOneWidget);

      // 4. Switch to Recall Mode
      await tester.ensureVisible(find.text('🧩 Recall'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🧩 Recall'));
      await tester.pumpAndSettle();

      expect(find.text('Which sacred phrase follows next?'), findsOneWidget);

      // 5. Switch to Arrange Mode
      await tester.ensureVisible(find.text('🔀 Arrange'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🔀 Arrange'));
      await tester.pumpAndSettle();

      expect(find.text('Check Verse Sequence'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsWidgets);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsWidgets);
    });
  });

  group('4. AI Router & Help Chatbot Tests', () {
    test('AIRouter protects caregiver boundary and deflects clinical queries', () async {
      final router = AIRouter();

      final res1 = await router.getAssistantResponse(
        prompt: 'What dementia stage am I currently in according to doctor report?',
        languageCode: 'en',
      );
      expect(res1, contains('clinical evaluations'));

      final res2 = await router.getAssistantResponse(
        prompt: 'How do I practice Shlokas today?',
        languageCode: 'en',
      );
      expect(res2, contains('Listen'));
    });

    test('AIRouter caches duplicate requests', () async {
      final router = AIRouter();
      final r1 = await router.getAssistantResponse(prompt: 'Tell me about memory games', languageCode: 'en');
      final r2 = await router.getAssistantResponse(prompt: 'Tell me about memory games', languageCode: 'en');
      expect(r1, r2);
    });

    testWidgets('SmritiVedaChatbotScreen renders preset chips, allows input, and replies', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      final appState = AppState();

      await tester.pumpWidget(
        MaterialApp(
          home: AppStateScope(
            state: appState,
            child: const SmritiVedaChatbotScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ask SmritiVeda Assistant'), findsOneWidget);
      expect(find.text('How do I practice Shlokas today?'), findsOneWidget);

      // Tap preset chip
      await tester.tap(find.text('How do I practice Shlokas today?'));
      await tester.pumpAndSettle();

      // Check reply is displayed
      expect(find.textContaining('shloka practice has 4 progressive steps'), findsOneWidget);
    });
  });
}
