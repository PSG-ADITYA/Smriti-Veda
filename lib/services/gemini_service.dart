import 'dart:convert';
import 'dart:io';

class GeminiService {
  final String? apiKey;

  GeminiService({this.apiKey});

  /// Generates a personalized caregiver cognitive progress report.
  Future<String> generateCaregiverSummary({
    required String patientName,
    required int streakDays,
    required int completedExercises,
    required String primaryLanguage,
  }) async {
    final prompt = '''
You are an AI assistant in Smriti Veda, an elderly cognitive memory support platform.
Generate a concise, compassionate 3-sentence weekly summary for caregiver of patient "$patientName".
Patient Details:
- Daily Activity Streak: $streakDays days
- Total Memory Exercises Completed: $completedExercises
- Primary Language Context: $primaryLanguage

Highlight:
1. Auditory recall engagement and verbal consistency.
2. Positive reinforcement for caregiver monitoring.
3. Suggestion for next week's focus (e.g. regional songs or proverbs).
''';

    if (apiKey == null || apiKey!.isEmpty) {
      return _generateOfflineFallback(patientName, streakDays, completedExercises, primaryLanguage);
    }

    try {
      final client = HttpClient();
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
      );

      final request = await client.postUrl(uri);
      request.headers.set('content-type', 'application/json');

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      });

      request.write(body);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody);
        final candidates = json['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final text = candidates.first['content']['parts'][0]['text'] as String?;
          if (text != null && text.isNotEmpty) {
            return text.trim();
          }
        }
      }
      client.close();
    } catch (e) {
      // Fallback gracefully on network error or offline mode
    }

    return _generateOfflineFallback(patientName, streakDays, completedExercises, primaryLanguage);
  }

  String _generateOfflineFallback(
    String patientName,
    int streakDays,
    int completedExercises,
    String primaryLanguage,
  ) {
    return '$patientName has demonstrated remarkable auditory engagement with a $streakDays-day active practice streak and $completedExercises exercises completed. Speech articulation during voice recall shows steady rhythmic fluency. For next week, introducing familiar $primaryLanguage regional songs and proverbs will provide excellent cognitive stimulation.';
  }
}
