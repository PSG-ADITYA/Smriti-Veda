import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smriti_veda/providers/app_state.dart';
import 'package:smriti_veda/screens/smritiveda_chatbot_screen.dart';
import 'package:smriti_veda/services/ai_provider.dart';
import 'package:smriti_veda/services/db_service.dart';
import 'package:smriti_veda/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppState appState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DbService().init();
    appState = AppState();
  });

  group('SmritiVeda AI Assistant & Chatbot Physical Test Cases', () {
    test('Verify 7 Required Exact Test Queries Return Distinct, Concrete, App-Grounded Answers', () async {
      final router = AIRouter();

      // Query 1: "tell me what's there in the app"
      final res1 = await router.getAssistantResponse(
        prompt: "tell me what's there in the app",
        languageCode: 'en',
      );
      expect(res1, contains('10 Replayable'));
      expect(res1, contains('Medical Reports Hub'));
      expect(res1, contains('Shloka'));

      // Query 2: "what games are available"
      final res2 = await router.getAssistantResponse(
        prompt: 'what games are available',
        languageCode: 'en',
      );
      expect(res2, contains('Fruit Memory Path'));
      expect(res2, contains('Memory Melody'));
      expect(res2, contains('3D Dice Memory'));
      expect(res2, contains('Word Memory Puzzle'));
      expect(res2, contains('Visual Search & Focus'));

      // Query 3: "what should I do now"
      final res3 = await router.getAssistantResponse(
        prompt: 'what should I do now',
        languageCode: 'en',
      );
      expect(res3, contains('Memory Melody'));
      expect(res3, contains('Fruit Memory Path'));
      expect(res3, contains('practice'));
      // Must not claim medical cure
      expect(res3.toLowerCase(), isNot(contains('cure')));

      // Query 4: "how does Memory Melody work"
      final res4 = await router.getAssistantResponse(
        prompt: 'how does Memory Melody work',
        languageCode: 'en',
      );
      expect(res4, contains('Memory Melody'));
      expect(res4, contains('swara'));

      // Query 5: "how do I view my medical reports"
      final res5 = await router.getAssistantResponse(
        prompt: 'how do I view my medical reports',
        languageCode: 'en',
      );
      expect(res5, contains('Medical Reports'));
      expect(res5, contains('Profile'));
      expect(res5, contains('PDF'));

      // Query 6: "what is 3D Dice Memory"
      final res6 = await router.getAssistantResponse(
        prompt: 'what is 3D Dice Memory',
        languageCode: 'en',
      );
      expect(res6, contains('3D Dice Memory'));
      expect(res6, contains('dice'));

      // Query 7: "hello"
      final res7 = await router.getAssistantResponse(
        prompt: 'hello',
        languageCode: 'en',
      );
      expect(res7, contains('Namaste! I am your SmritiVeda AI Assistant'));

      // CRITICAL ASSERTION: The responses for 1 through 6 MUST NOT be identical!
      final responses = [res1, res2, res3, res4, res5, res6, res7];
      final uniqueResponses = responses.toSet();
      expect(uniqueResponses.length, 7, reason: 'All 7 test cases must return distinct responses!');
    });

    test('Verify Part 2 Audit Questions Return Unique, Meaningful, Grounded Answers', () async {
      final router = AIRouter();

      // Q1: "What is in this app?"
      final a1 = await router.getAssistantResponse(prompt: 'What is in this app?', languageCode: 'en');
      expect(a1, contains('SmritiVeda is your complete, culturally grounded cognitive wellness companion'));
      expect(a1, contains('10 Replayable Memory Games'));

      // Q2: "What should I do today?"
      final a2 = await router.getAssistantResponse(prompt: 'What should I do today?', languageCode: 'en');
      expect(a2, contains('practice plan'));
      expect(a2, contains('Memory Melody'));

      // Q3: "Recommend a memory game."
      final a3 = await router.getAssistantResponse(prompt: 'Recommend a memory game.', languageCode: 'en');
      expect(a3, contains('recommend starting with "Memory Melody"'));

      // Q4: "Remind me about my routine."
      final a4 = await router.getAssistantResponse(prompt: 'Remind me about my routine.', languageCode: 'en');
      expect(a4, contains('healthy senior routine'));
      expect(a4, contains('Daily Routine Recall'));

      // Q5: "How does Smriti Veda help memory?"
      final a5 = await router.getAssistantResponse(prompt: 'How does Smriti Veda help memory?', languageCode: 'en');
      expect(a5, contains('multi-sensory approach'));
      expect(a5, contains('neuroplasticity'));

      // Assert all 5 answers are mutually distinct and non-canned!
      final answers = [a1, a2, a3, a4, a5];
      final uniqueAnswers = answers.toSet();
      expect(uniqueAnswers.length, 5, reason: 'All 5 questions must produce unique, specialized responses!');
    });

    test('Clinical boundary interception defends against diagnostic/medication queries', () async {
      final router = AIRouter();

      final clinicalRes1 = await router.getAssistantResponse(
        prompt: 'Can you prescribe medication or tell me what dementia stage I am in?',
        languageCode: 'en',
      );
      expect(clinicalRes1, equals(AIRouter.caregiverBoundaryNotice));

      final clinicalRes2 = await router.getAssistantResponse(
        prompt: 'How to cure dementia with these games?',
        languageCode: 'en',
      );
      expect(clinicalRes2, equals(AIRouter.caregiverBoundaryNotice));
    });

    testWidgets('SmritiVedaChatbotScreen renders "SmritiVeda AI Assistant" branding and answers queries', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AppStateScope(
            state: appState,
            child: const SmritiVedaChatbotScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title is "SmritiVeda AI Assistant" (NO Gemini branding)
      expect(find.text('SmritiVeda AI Assistant'), findsOneWidget);
      expect(find.textContaining('Gemini'), findsNothing);

      // Verify initial welcome bubble
      expect(find.textContaining('Namaste! I am your SmritiVeda AI Assistant'), findsOneWidget);

      // Enter Question: "what games are available"
      await tester.enterText(find.byKey(const Key('chatbot_input_field')), 'what games are available');
      await tester.pump();
      await tester.tap(find.byKey(const Key('chatbot_send_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      // Check assistant response contains actual games list
      expect(find.textContaining('Fruit Memory Path'), findsOneWidget);
      expect(find.textContaining('3D Dice Memory'), findsOneWidget);
      expect(find.textContaining('Word Memory Puzzle'), findsOneWidget);

      // Enter Question: "how do I view my medical reports"
      await tester.enterText(find.byKey(const Key('chatbot_input_field')), 'how do I view my medical reports');
      await tester.pump();
      await tester.tap(find.byKey(const Key('chatbot_send_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      // Check assistant response contains medical reports navigation instructions
      expect(find.textContaining('Medical Reports'), findsWidgets);
      expect(find.textContaining('Profile'), findsWidgets);
    });
  });
}
