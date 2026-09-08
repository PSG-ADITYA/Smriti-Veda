import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'db_service.dart';

abstract class AIProvider {
  String get name;
  bool get isAvailable;
  Future<String> chat({
    required String prompt,
    required String languageCode,
    String? systemPrompt,
  });
}

/// Google Gemini 1.5 Flash Provider
class GeminiProvider implements AIProvider {
  @override
  String get name => 'Google Gemini (1.5 Flash)';

  @override
  bool get isAvailable => DbService().isAiEnabled && DbService().geminiApiKey.isNotEmpty;

  @override
  Future<String> chat({
    required String prompt,
    required String languageCode,
    String? systemPrompt,
  }) async {
    final apiKey = DbService().geminiApiKey;
    if (apiKey.isEmpty) {
      throw StateError('Gemini API key is not configured');
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final fullPrompt = systemPrompt != null
        ? '$systemPrompt\n\nUser query ($languageCode): $prompt'
        : 'Respond in language ($languageCode): $prompt';

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [{'text': fullPrompt}]
          }
        ]
      }),
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final candidates = json['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final text = candidates.first['content']['parts'][0]['text'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          return text.trim();
        }
      }
    }
    throw StateError('Gemini response error (${response.statusCode})');
  }
}

/// OpenAI-compatible Gateway Provider (OmniRoute on localhost:20128/v1 or custom URL)
class OmniRouteProvider implements AIProvider {
  final String baseUrl;

  OmniRouteProvider({this.baseUrl = 'http://localhost:20128/v1'});

  @override
  String get name => 'OmniRoute Gateway';

  @override
  bool get isAvailable => DbService().isAiEnabled;

  @override
  Future<String> chat({
    required String prompt,
    required String languageCode,
    String? systemPrompt,
  }) async {
    final endpoint = Uri.parse('$baseUrl/chat/completions');

    final messages = <Map<String, String>>[];
    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.add({
      'role': 'user',
      'content': 'Language: $languageCode\n$prompt',
    });

    final response = await http.post(
      endpoint,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': 'omniroute-default',
        'messages': messages,
        'temperature': 0.7,
      }),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final choices = json['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final content = choices.first['message']?['content'] as String?;
        if (content != null && content.trim().isNotEmpty) {
          return content.trim();
        }
      }
    }
    throw StateError('OmniRoute gateway error (${response.statusCode})');
  }
}

/// Government of India Bhashini / ULCA Platform Adapter
class BhashiniProvider implements AIProvider {
  final String? apiKey;
  final String? userId;

  BhashiniProvider({this.apiKey, this.userId});

  @override
  String get name => 'BHASHINI (MeitY National Indic Platform)';

  @override
  bool get isAvailable => apiKey != null && apiKey!.isNotEmpty;

  @override
  Future<String> chat({
    required String prompt,
    required String languageCode,
    String? systemPrompt,
  }) async {
    // Adapter connects to ULCA pipeline if configured
    if (!isAvailable) {
      throw StateError('Bhashini credentials not set');
    }
    // Pluggable pipeline call structure
    throw UnimplementedError('Bhashini cloud adapter requires active pipeline registration');
  }
}

/// Offline Deterministic Knowledge Provider for Elderly Guidance
class OfflineDeterministicProvider implements AIProvider {
  @override
  String get name => 'Offline Heritage Assistant';

  @override
  bool get isAvailable => true;

  @override
  Future<String> chat({
    required String prompt,
    required String languageCode,
    String? systemPrompt,
  }) async {
    final lower = prompt.toLowerCase();

    // 1. Shloka / Cultural Practice questions
    if (lower.contains('shloka') || lower.contains('mantra') || lower.contains('verse') || lower.contains('శ్లోక') || lower.contains('श्लोक')) {
      if (languageCode == 'te') {
        return 'శ్లోక సాధనలో 4 దశలు ఉన్నాయి: వినడం (Listen), అనువాదించడం (Echo), గుర్తుతెచ్చుకోవడం (Recall), మరియు క్రమబద్ధీకరించడం (Arrange). ప్రతిరోజూ 5 నిమిషాల గాయత్రీ లేదా మృత్యుంజయ మంత్ర సాధన మనస్సును ప్రశాంతంగా ఉంచుతుంది.';
      } else if (languageCode == 'hi') {
        return 'श्लोक अभ्यास में 4 चरण हैं: सुनना (Listen), दोहराना (Echo), स्मरण (Recall), और क्रमबद्ध करना (Arrange)। प्रतिदिन 5 मिनट महामृत्युंजय या गायत्री मंत्र का पाठ मानसिक एकाग्रता को सुदृढ़ करता है।';
      } else if (languageCode == 'sa') {
        return 'श्लोकाभ्यासस्य चत्वारः सोपानाः सन्ति: श्रवणम्, अनुवाचनम्, स्मरणम्, क्रमबद्धता च। नित्यं पञ्च निमेषाणां मन्त्राभ्यासः शान्तिं ददाति।';
      }
      return 'Our sacred shloka practice has 4 progressive steps: Listen (synchronous chanting), Echo (repeat each phrase), Recall (choose the next phrase), and Arrange (sequence the verse). Practicing 5 minutes daily brings deep mental focus and tranquility.';
    }

    // 2. Cognitive Games guidance
    if (lower.contains('game') || lower.contains('memory') || lower.contains('play') || lower.contains('ఆట') || lower.contains('खेल') || lower.contains('క్రీడ')) {
      if (languageCode == 'te') {
        return 'మీరు "మెమరీ మెలోడీ" (Memory Melody) ద్వారా శ్రవణ జ్ఞాపకశక్తిని, "ఫ్రూట్ మెమరీ పాత్" (Fruit Path) ద్వారా దృశ్య మార్గాన్ని సాధన చేయవచ్చు. మీ సౌకర్యార్థం Easy లేదా Medium మోడ్ ఎంచుకోండి.';
      } else if (languageCode == 'hi') {
        return 'आप "मेमोरी मेलोडी" (Memory Melody) से श्रवण स्मृति और "फ्रूट पाथ" (Fruit Path) से स्थानिक स्मृति का अभ्यास कर सकते हैं। अपनी गति के अनुसार Easy या Medium स्तर चुनें।';
      }
      return 'I recommend starting today with "Memory Melody" for auditory recall or "Fruit Memory Path" for spatial navigation. You can select Easy difficulty for a relaxed, enjoyable session!';
    }

    // 3. Progress / Daily tracking
    if (lower.contains('progress') || lower.contains('score') || lower.contains('today') || lower.contains('పురోగతి') || lower.contains('प्रगति')) {
      if (languageCode == 'te') {
        return 'మీరు క్రమం తప్పకుండా సాధన చేస్తున్నారు! మీ ప్రశాంత సాధన జ్ఞాపకశక్తిని మరియు ఏకాగ్రతను చురుకుగా ఉంచుతుంది. Progress ట్యాబ్‌లో మీ పూర్తి వివరాలు చూడవచ్చు.';
      } else if (languageCode == 'hi') {
        return 'आपका अभ्यास बहुत सराहनीय है! नियमित अभ्यास से एकाग्रता और स्मृति सदैव सक्रिय रहती है। अपनी पूरी प्रगति आप Progress टैब में देख सकते हैं।';
      }
      return 'You are doing wonderfully! Consistent, peaceful daily practice keeps your focus and neural connections active. Check the Progress tab anytime to see your daily exercise summary.';
    }

    // 4. Routine / Medicine reminder
    if (lower.contains('routine') || lower.contains('medicine') || lower.contains('evening') || lower.contains('water') || lower.contains('దినచర్య') || lower.contains('दिनचर्या')) {
      if (languageCode == 'te') {
        return 'మంచి ఆరోగ్య దినచర్య: సూర్యోదయ వేళ శ్వాస వ్యాయామం, సమయానికి మందులు తీసుకోవడం, మరియు తగినంత గోరువెచ్చని నీరు త్రాగడం. ప్రశాంతంగా విశ్రాంతి తీసుకోండి.';
      } else if (languageCode == 'hi') {
        return 'स्वस्थ दिनचर्या: प्रातःकाल प्राणायाम, समय पर औषधि ग्रहण, और पर्याप्त गुनगुने जल का सेवन। संध्याकाल में हल्का विश्राम करें।';
      }
      return 'A healthy senior routine includes gentle morning breathing, timely medicine intake, staying well-hydrated, and evening relaxation. Take your time and enjoy every moment.';
    }

    // Default supportive response
    if (languageCode == 'te') {
      return 'నమస్కారం! నేను స్మృతివేద మీ జ్ఞాపకశక్తి సహచరుడిని. శ్లోక సాధన, జ్ఞాపకశక్తి ఆటలు లేదా మీ రోజువారీ దినచర్య గురించి నన్ను అడగవచ్చు.';
    } else if (languageCode == 'hi') {
      return 'नमस्ते! मैं स्मृतिवेद संज्ञानात्मक सहायक हूँ। श्लोक पाठ, स्मृति खेलों या दैनिक अभ्यास से संबंधित किसी भी प्रश्न के लिए मुझसे पूछें।';
    } else if (languageCode == 'sa') {
      return 'नमस्ते! अहं स्मृतिवेद-सहायकः अस्मि। श्लोकाभ्यासार्थं स्मृति-क्रीडार्थं च मां पृच्छतु।';
    }
    return 'Namaste! I am your SmritiVeda cognitive wellness companion. I can help guide your Shloka practice, recommend memory games, or help you review your daily routines!';
  }
}

/// Central Intelligent AI Routing Hub
class AIRouter {
  static final AIRouter _instance = AIRouter._internal();
  factory AIRouter() => _instance;
  AIRouter._internal();

  final GeminiProvider _gemini = GeminiProvider();
  final OmniRouteProvider _omniRoute = OmniRouteProvider();
  final BhashiniProvider _bhashini = BhashiniProvider();
  final OfflineDeterministicProvider _offline = OfflineDeterministicProvider();

  // In-memory cache to save costs & eliminate latency
  final Map<String, String> _responseCache = {};

  static const String caregiverBoundaryNotice =
      'I am your daily cognitive wellness companion. Medical reports, clinical evaluations, and prescription adjustments are strictly reserved for your authorized caregiver and doctor for your safety.';

  /// Dispatches assistant queries through available providers with seamless fallback
  Future<String> getAssistantResponse({
    required String prompt,
    required String languageCode,
    String? systemPrompt,
  }) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) {
      return 'Please feel free to ask any question about your daily exercises or memory games.';
    }

    // ── Clinical & Caregiver Authorization Boundary Guardrail ──
    final lower = cleanPrompt.toLowerCase();
    if (lower.contains('dementia stage') ||
        lower.contains('cognitive decline') ||
        lower.contains('worsening') ||
        lower.contains('doctor report') ||
        lower.contains('caregiver password') ||
        lower.contains('clinical diagnosis')) {
      return caregiverBoundaryNotice;
    }

    // Check Cache
    final cacheKey = '$languageCode::$cleanPrompt';
    if (_responseCache.containsKey(cacheKey)) {
      return _responseCache[cacheKey]!;
    }

    // 1. Try OmniRoute (OpenAI Gateway) if enabled
    if (_omniRoute.isAvailable) {
      try {
        final res = await _omniRoute.chat(
          prompt: cleanPrompt,
          languageCode: languageCode,
          systemPrompt: systemPrompt,
        );
        _responseCache[cacheKey] = res;
        return res;
      } catch (e) {
        debugPrint('OmniRoute fallback triggered: $e');
      }
    }

    // 2. Try Gemini 1.5 Flash
    if (_gemini.isAvailable) {
      try {
        final res = await _gemini.chat(
          prompt: cleanPrompt,
          languageCode: languageCode,
          systemPrompt: systemPrompt,
        );
        _responseCache[cacheKey] = res;
        return res;
      } catch (e) {
        debugPrint('Gemini fallback triggered: $e');
      }
    }

    // 3. Try Bhashini if registered
    if (_bhashini.isAvailable) {
      try {
        final res = await _bhashini.chat(
          prompt: cleanPrompt,
          languageCode: languageCode,
          systemPrompt: systemPrompt,
        );
        _responseCache[cacheKey] = res;
        return res;
      } catch (e) {
        debugPrint('Bhashini fallback triggered: $e');
      }
    }

    // 4. Reliable Offline Deterministic Guidance
    final offlineRes = await _offline.chat(
      prompt: cleanPrompt,
      languageCode: languageCode,
      systemPrompt: systemPrompt,
    );
    _responseCache[cacheKey] = offlineRes;
    return offlineRes;
  }
}
