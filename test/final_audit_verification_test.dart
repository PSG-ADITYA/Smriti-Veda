import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smriti_veda/models/game_difficulty.dart';
import 'package:smriti_veda/providers/app_state.dart';
import 'package:smriti_veda/screens/everyday_memory_screen.dart';
import 'package:smriti_veda/screens/medical_reports_screen.dart';
import 'package:smriti_veda/services/ai_provider.dart';
import 'package:smriti_veda/services/db_service.dart';
import 'package:smriti_veda/services/session_engine/memory_session_generator.dart';
import 'package:smriti_veda/services/sound_service.dart';
import 'package:smriti_veda/utils/sanskrit_pronunciation_preprocessor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DbService().init();
  });

  group('FINAL PRE-PUSH AUDIT VERIFICATION SUITE', () {
    test('1. OmniRoute Failover & Graceful Offline Fallback', () async {
      final omni = OmniRouteProvider(baseUrl: 'http://localhost:20128/v1');
      // OmniRoute is not running on localhost:20128, so isAvailable should be false or throw handled error
      expect(omni.isAvailable, isFalse);

      final router = AIRouter();
      // AIRouter should seamlessly fall back to deterministic responses without throwing
      final response = await router.getAssistantResponse(
        prompt: 'What is this app?',
        languageCode: 'en',
      );
      expect(response, isNotEmpty);
      expect(response, contains('SmritiVeda'));
      expect(response, contains('10 Replayable'));
    });

    test('2. Chatbot Part 2 Exact Test Queries All Return Unique Grounded Answers', () async {
      final router = AIRouter();

      // Q1
      final a1 = await router.getAssistantResponse(prompt: 'What is in this app?', languageCode: 'en');
      // Q2
      final a2 = await router.getAssistantResponse(prompt: 'What should I do today?', languageCode: 'en');
      // Q3
      final a3 = await router.getAssistantResponse(prompt: 'Recommend a memory game.', languageCode: 'en');
      // Q4
      final a4 = await router.getAssistantResponse(prompt: 'Remind me about my routine.', languageCode: 'en');
      // Q5
      final a5 = await router.getAssistantResponse(prompt: 'How does Smriti Veda help memory?', languageCode: 'en');

      expect(a1, contains('10 Replayable Memory Games'));
      expect(a2, contains('practice plan'));
      expect(a3, contains('recommend starting with "Memory Melody"'));
      expect(a4, contains('healthy senior routine'));
      expect(a5, contains('multi-sensory approach'));

      final allAnswers = {a1, a2, a3, a4, a5};
      expect(allAnswers.length, 5, reason: 'Every question must yield a distinct, non-canned answer!');
    });

    test('3. Patient vs Caregiver Identity Separation', () {
      final appState = AppState();
      appState.login(
        name: 'Aditya Verma',
        credentialId: 'aditya_senior_101',
        role: 'Patient',
      );

      expect(appState.patientName, equals('Aditya Verma'));
      expect(appState.userName, equals('Aditya Verma'));
      expect(appState.userRole, equals('Patient'));
      expect(appState.isCaregiverMode, isFalse);

      // Switch to Caregiver mode
      appState.switchRole();
      expect(appState.userRole, equals('Caregiver'));
      expect(appState.isCaregiverMode, isTrue);
      // Caregiver identity must NOT overwrite the senior's name
      expect(appState.patientName, equals('Aditya Verma'));
      expect(appState.userName, contains('Caregiver'));

      // Switch back to Patient mode
      appState.switchRole();
      expect(appState.userRole, equals('Patient'));
      expect(appState.isCaregiverMode, isFalse);
      expect(appState.userName, equals('Aditya Verma'));
    });

    test('4. Language Persistence Across Restarts', () {
      final appState = AppState();
      expect(appState.selectedLanguage, equals('en'));

      appState.setSelectedLanguage('te');
      expect(appState.selectedLanguage, equals('te'));

      // Verify persistence in DbService
      final persisted = DbService().getPersistentItem('app_selected_language');
      expect(persisted, equals('te'));

      // Re-instantiate AppState to simulate app restart
      final restartedState = AppState();
      expect(restartedState.selectedLanguage, equals('te'));

      // Clean up for other tests
      appState.setSelectedLanguage('en');
    });

    test('5. Memory Melody Procedural Replayability & Audio Synthesis Debounce', () {
      // Generate multiple sessions and verify variations
      final Set<String> melodies = {};
      for (int i = 0; i < 20; i++) {
        final session = MemorySessionGenerator.generateMelodySession(GameDifficulty.medium);
        melodies.add(session.stimulus.noteIds.join('-'));
      }
      expect(melodies.length, greaterThan(1), reason: 'Procedural generation must produce varied melodies');

      // Test tone playing does not throw
      expect(() => SoundService().playMusicalTone(frequency: 261.63, noteLabel: 'Sa'), returnsNormally);
      expect(() => SoundService().playMusicalTone(frequency: 293.66, noteLabel: 'Re'), returnsNormally);
    });

    test('6. Sanskrit TTS Short Token Safe Buffering', () {
      final processedOm = SanskritPronunciationPreprocessor.preprocessForTts('ॐ');
      expect(processedOm, contains('ओम्,'));

      final processedShort = SanskritPronunciationPreprocessor.preprocessForTts('श्री');
      expect(processedShort, endsWith(', '));

      final padas = SanskritPronunciationPreprocessor.splitIntoPadas('ॐ । तत्सवितुर्वरेण्यं ॥');
      expect(padas.length, equals(2));
      expect(padas.first, contains('ओम्'));
    });

    testWidgets('7. Everyday Memory Displays Dynamic Patient Name and Quick Actions', (tester) async {
      final appState = AppState();
      appState.login(name: 'Aditya Verma', credentialId: 'aditya_senior_101', role: 'Patient');

      await tester.pumpWidget(
        MaterialApp(
          home: AppStateScope(
            state: appState,
            child: const EverydayMemoryScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Everyday Memory • Aditya Verma'), findsOneWidget);
      expect(find.text('+ Add Reminder'), findsOneWidget);
      expect(find.text('+ Add Custom Routine'), findsOneWidget);
      expect(find.text('+ Add Familiar Person'), findsOneWidget);
    });

    testWidgets('8. Medical Reports Displays Contextual Empty State for Patient', (tester) async {
      final appState = AppState();
      appState.login(name: 'Aditya Verma', credentialId: 'aditya_senior_101', role: 'Patient');

      await tester.pumpWidget(
        MaterialApp(
          home: AppStateScope(
            state: appState,
            child: const MedicalReportsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No medical reports uploaded yet.'), findsOneWidget);
      expect(find.textContaining('Medical records for Aditya Verma will appear here'), findsOneWidget);
    });
  });
}
