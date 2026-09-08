import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'db_service.dart';

/// SmritiVeda System Context for Online Conversational AI Models
const String smritiVedaSystemPrompt = """
You are the compassionate, elderly-friendly AI Assistant for "SmritiVeda" (स्मृति वेद), an Indian cognitive wellness and memory preservation application for senior citizens.
Key SmritiVeda Features:
• 10 Replayable Cognitive Games:
  1. Fruit Memory Path (Spatial navigation & fruit sequences along a garden path)
  2. Memory Melody (Auditory swara notes Sa-Re-Ga-Ma & melodic recall)
  3. 3D Dice Memory (Tabletop spatial arrangement & number recall)
  4. Word Memory Puzzle (Culturally familiar vocabulary sequence recall)
  5. Pattern Memory (Visual grid patterns & working memory)
  6. Object Memory & Recall (Nostalgic household item placement & presence)
  7. Visual Search & Focus (Target discrimination amidst distractors)
  8. Sequence Recall (Number/word order & reverse sequence recall)
  9. Oral Heritage Stories (Story comprehension & narrative recall)
  10. Daily Routine Recall (Everyday living activity schedules & ordering)
• Sacred Shloka Recitation: 4-stage multi-sensory pipeline (Listen, Echo, Recall, Arrange) with traditional verses (Gita, Mahamrityunjaya, Gayatri).
• Everyday Memory Anchors: Personal diary, family reminders, and cognitive milestone tracking.
• Medical Reports Hub: Secure in-app viewer for PDF prescriptions and image laboratory scans with zoom and full-text notes.
• Caregiver Dashboard: Longitudinal consistency monitoring and milestone tracking.

Tone & Safety Guidelines:
- Warm, patient, elderly-friendly, respectful Indian tone ("Namaste").
- Keep responses concise (2 to 4 sentences), highly legible, and reassuring.
- Emphasize peaceful cognitive exercise, mental calmness, and daily rhythm.
- CLINICAL SAFETY GUARD: Never diagnose dementia or any disease. Never prescribe medicines or alter dosages. If clinical queries arise, kindly advise consulting a doctor.
""";

abstract class AIProvider {
  String get name;
  bool get isAvailable;
  Future<String> chat({
    required String prompt,
    required String languageCode,
    String? systemPrompt,
  });
}

/// Google Gemini 1.5 Flash Provider (Primary AI Engine)
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

    final sys = systemPrompt ?? smritiVedaSystemPrompt;
    final fullPrompt = '$sys\n\nUser query ($languageCode): $prompt';

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

/// OpenAI-compatible Gateway Provider (OmniRoute - Secondary Failover)
class OmniRouteProvider implements AIProvider {
  final String baseUrl;

  OmniRouteProvider({this.baseUrl = 'http://localhost:20128/v1'});

  @override
  String get name => 'OmniRoute Gateway';

  @override
  bool get isAvailable {
    final customUrl = DbService().getPersistentItem('omniroute_base_url');
    // Only available if explicitly configured with an accessible custom gateway (not unconfigured localhost)
    return DbService().isAiEnabled && customUrl != null && customUrl.isNotEmpty && !customUrl.contains('localhost');
  }

  @override
  Future<String> chat({
    required String prompt,
    required String languageCode,
    String? systemPrompt,
  }) async {
    if (!isAvailable) {
      throw StateError('OmniRoute gateway is not configured or unavailable');
    }

    final customUrl = DbService().getPersistentItem('omniroute_base_url');
    final activeBase = customUrl ?? baseUrl;
    final endpoint = Uri.parse('$activeBase/chat/completions');

    final messages = <Map<String, String>>[];
    final sys = systemPrompt ?? smritiVedaSystemPrompt;
    messages.add({'role': 'system', 'content': sys});
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
    if (!isAvailable) {
      throw StateError('Bhashini credentials not set');
    }
    throw UnimplementedError('Bhashini cloud adapter requires active pipeline registration');
  }
}

/// Offline Contextual Deterministic Knowledge Provider for Elderly Guidance
/// Delivers rich, accurate, grounded answers for every feature in SmritiVeda.
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
    final lower = prompt.toLowerCase().trim();

    // Dynamically detect script from user prompt so replies match user language
    String activeLang = languageCode;
    final hasTelugu = RegExp(r'[\u0C00-\u0C7F]').hasMatch(prompt);
    final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(prompt);
    final hasEnglish = RegExp(r'[a-zA-Z]').hasMatch(prompt);

    if (hasTelugu) {
      activeLang = 'te';
    } else if (hasDevanagari) {
      activeLang = 'hi';
    } else if (hasEnglish && !hasTelugu && !hasDevanagari) {
      activeLang = 'en';
    }


    // ── Out-of-Topic Guardrail (Policy Enforcement) ──
    if (lower.contains('cricket') ||
        lower.contains('weather') ||
        lower.contains('movie') ||
        lower.contains('cinema') ||
        lower.contains('politics') ||
        lower.contains('election') ||
        lower.contains('python') ||
        lower.contains('coding') ||
        lower.contains('recipe') ||
        lower.contains('stock market') ||
        lower.contains('football') ||
        lower.contains('bitcoin') ||
        lower.contains('సినిమా') ||
        lower.contains('వాతావరణం') ||
        lower.contains('రాజకీయాలు') ||
        lower.contains('క్రికెట్') ||
        lower.contains('मौसम') ||
        lower.contains('सिनेमा') ||
        lower.contains('फिल्म') ||
        lower.contains('राजनीति') ||
        lower.contains('क्रिकेट')) {
      if (activeLang == 'te') {
        return 'క్షమించండి, నేను కేవలం స్మృతివేద యాప్, మీ దినచర్యలు, జ్ఞాపకశక్తి ఆటలు, శ్లోక సాధన మరియు మానసిక ఆరోగ్యం గురించిన ప్రశ్నలకు మాత్రమే సమాధానం ఇవ్వగలను.';
      } else if (activeLang == 'hi') {
        return 'क्षमा करें, मैं केवल स्मृतिवेद ऐप, आपकी दिनचर्या, स्मृति खेलों, श्लोक पाठ और संज्ञानात्मक स्वास्थ्य से संबंधित प्रश्नों के उत्तर दे सकता हूँ।';
      }
      return 'Sorry, I can only answer questions about Smriti Veda, your daily routines, memory games, shloka practice, and cognitive health.';
    }

    // ── App Comprehensive Guide: "How to use this app" ──
    if (lower.contains('how to use') ||
        lower.contains('how do i use') ||
        lower.contains('how does this app work') ||
        lower.contains('guide me') ||
        lower.contains('app guide') ||
        lower.contains('explain app') ||
        lower.contains('how to use this') ||
        lower.contains('యాప్‌ను ఎలా ఉపయోగించాలి') ||
        lower.contains('యాప్ ఎలా పనిచేస్తుంది') ||
        lower.contains('ऐप का उपयोग कैसे करें') ||
        lower.contains('ऐप कैसे काम करता है')) {
      if (activeLang == 'te') {
        return 'స్మృతివేద యాప్‌ను ఎలా ఉపయోగించాలో ఇక్కడ వివరణ ఉంది:\n'
            '1. హోమ్ ట్యాబ్ (Home): నేటి సాధన ప్రణాళికను వినండి, స్ట్రీక్ మరియు స్ఫూర్తిదాయక సూక్తిని చూడండి.\n'
            '2. సాధన ట్యాబ్ (Practice): 10 జ్ఞాపకశక్తి ఆటలు (Memory Melody, Fruit Path, 3D Dice) మరియు 4 దశల వేద శ్లోక సాధన చేయండి.\n'
            '3. దినచర్య ట్యాబ్ (Everyday): మీ దినచర్య, రిమైండర్లు మరియు కుటుంబ సభ్యులను నమోదు చేసుకోండి.\n'
            '4. మెడికల్ రిపోర్ట్స్ (Medical Reports): ప్రిస్క్రిప్షన్‌లు, రక్త పరీక్షలు మరియు స్కాన్‌లను భద్రంగా చదవండి.\n'
            '5. కేర్‌గివర్ (Caregiver): కుటుంబ సభ్యులతో సురక్షితంగా అనుసంధానమై మీ పురోగతిని పంచుకోండి.';
      } else if (activeLang == 'hi') {
        return 'स्मृतिवेद ऐप का उपयोग करने की सरल विधि:\n'
            '1. होम टैब (Home): दैनिक योजना सुनें, दैनिक स्ट्रीक और प्रेरक विचार देखें।\n'
            '2. अभ्यास टैब (Practice): 10 संज्ञानात्मक खेल (Memory Melody, 3D Dice, Fruit Path) और 4-चरणीय वैदिक श्लोक पाठ करें।\n'
            '3. दिनचर्या टैब (Everyday): अपनी दैनिक दिनचर्या, रिमाइंडर और परिचित परिजनों को जोड़ें।\n'
            '4. मेडिकल रिपोर्ट (Medical Reports): डॉक्टर के पर्चे और टेस्ट रिपोर्ट की PDF सुरक्षित रखें।\n'
            '5. देखभालकर्ता (Caregiver): अपने परिवार के सदस्य से जुड़कर प्रगति साझा करें।';
      }
      return 'Here is a simple guide on how to use Smriti Veda:\n'
          '1. Home Tab: Listen to your daily plan with the audio prompter, view your streak, and read the daily motivational quote.\n'
          '2. Practice Tab: Explore 10 evidence-based cognitive games (Memory Melody, Fruit Path, 3D Dice, Word Puzzle) and 4-step progressive Vedic Shloka recitation.\n'
          '3. Everyday Memory Tab: Organize your daily routines, reminders, and familiar family connections.\n'
          '4. Medical Reports: Securely upload and view prescriptions, laboratory tests, and MRI scans offline.\n'
          '5. Caregiver Hub: Link with a trusted family member to monitor wellness milestones peacefully.';
    }

    // ── Difficulty Escalation: "Make levels hard" / "How to increase difficulty" ──
    if (lower.contains('make levels hard') ||
        lower.contains('make it hard') ||
        lower.contains('harder') ||
        lower.contains('increase difficulty') ||
        lower.contains('difficulty level') ||
        lower.contains('change difficulty') ||
        lower.contains('level hard') ||
        lower.contains('make level hard') ||
        lower.contains('కష్టమైన స్థాయి') ||
        lower.contains('స్థాయిని పెంచడం') ||
        lower.contains('कठिन स्तर') ||
        lower.contains('कठिनाई बढ़ाएं')) {
      if (activeLang == 'te') {
        return 'ఆట స్థాయిలను కఠినతరం (Hard) చేయడానికి:\n'
            '1. మీరు ఆడాలనుకునే ఏ ఆట కార్డునైనా ఎంచుకోండి.\n'
            '2. ఆట స్క్రీన్ ఎగువన "Easy", "Medium", "Hard" సెలెక్టర్ కనిపిస్తుంది. అందులో "Hard" నొక్కండి.\n'
            '3. Hard మోడ్‌లో ఎక్కువ వస్తువులు లేదా స్వరాలు ఉంటాయి, సమయం తక్కువగా ఉంటుంది మరియు రివర్స్ రీకాల్ వంటి సవాళ్లు ఉంటాయి!\n'
            'ఉదాహరణకు, Memory Melody లో 7 స్వరాల రాగం వేగంగా ప్లే అవుతుంది.';
      } else if (activeLang == 'hi') {
        return 'खेल का स्तर कठिन (Hard) करने के लिए:\n'
            '1. कोई भी खेल चुनें (जैसे Memory Melody, 3D Dice या Fruit Path)।\n'
            '2. खेल शुरू होने से पहले ऊपर दिए गए "Easy", "Medium", "Hard" विकल्पों में से "Hard" चुनें।\n'
            '3. Hard स्तर में वस्तुओं या संगीत के स्वरों की संख्या बढ़ जाती है, गति तेज हो जाती है और स्मरण चुनौती कठिन हो जाती है!';
      }
      return 'To make exercise levels harder:\n'
          '1. Open any game from the Practice tab (such as Memory Melody, 3D Dice Memory, or Fruit Memory Path).\n'
          '2. At the top of the game screen, tap the "Hard" button on the Difficulty Selector.\n'
          '3. In Hard Mode:\n'
          '   • Memory Melody plays a complex 7-note classical raga sequence at a brisker tempo.\n'
          '   • 3D Dice Memory displays 5 dice with shorter preview time and reverse location challenges.\n'
          '   • Word Puzzle presents longer cultural lists with subtle distractors and order rearrangement.\n'
          'This provides an invigorating workout for mental processing speed and working memory!';
    }

    // ── 1. Medical Reports & Prescriptions Hub ──
    if (lower.contains('medical report') ||
        lower.contains('view my medical') ||
        lower.contains('view report') ||
        lower.contains('prescription') ||
        lower.contains('lab report') ||
        lower.contains('blood report') ||
        RegExp(r'\bmri\b').hasMatch(lower) ||
        lower.contains('doctor report') ||
        lower.contains('open report') ||
        lower.contains('reports') ||
        lower.contains('వైద్య నివేదిక') ||
        lower.contains('మందుల చీటీ') ||
        lower.contains('चिकित्सा रिपोर्ट') ||
        lower.contains('दवा का पर्चा')) {
      if (activeLang == 'te') {
        return 'మీ వైద్య నివేదికలను చూడటానికి:\n'
            '1. హోమ్ స్క్రీన్‌పై "Medical Reports" బటన్ నొక్కండి, లేదా Profile ట్యాబ్‌ను తెరవండి.\n'
            '2. మీరు భద్రపరిచిన ప్రిస్క్రిప్షన్‌లు, రక్త పరీక్షలు, MRI స్కాన్‌ల జాబితా కనిపిస్తుంది.\n'
            '3. ఏ రిపోర్ట్ కార్డునైనా తాకితే, PDF లేదా ఇమేజ్ స్కాన్‌ను నేరుగా యాప్‌లోనే స్పష్టంగా చదవవచ్చు.';
      } else if (activeLang == 'hi') {
        return 'अपनी चिकित्सा रिपोर्ट देखने के लिए:\n'
            '1. होम स्क्रीन पर "Medical Reports" बटन दबाएँ, या Profile टैब खोलें।\n'
            '2. यहाँ आपके सुरक्षित नुस्खे (Prescriptions), लैब टेस्ट और MRI स्कैन सूचीबद्ध मिलेंगे।\n'
            '3. किसी भी रिपोर्ट कार्ड पर टैप करके आप PDF या इमेज स्कैन को ऐप के भीतर ही ज़ूम करके देख सकते हैं।';
      }
      return 'To view your medical reports:\n'
          '1. Tap the "Medical Reports" button on the Home screen, or open the Medical Reports section from your Profile tab.\n'
          '2. You will see all your saved records (prescriptions, laboratory tests, MRI scans, and clinical notes).\n'
          '3. Tap directly on any report card to open our built-in high-resolution viewer for PDF documents and image scans.\n'
          'All your documents remain private and securely saved on your device.';
    }

    // ── 2. 3D Dice Memory Game ──
    if (lower.contains('3d dice') ||
        lower.contains('dice memory') ||
        lower.contains('dice game') ||
        lower.contains('dice') ||
        lower.contains('పాచిక') ||
        lower.contains('పాచికలు') ||
        lower.contains('पासा') ||
        lower.contains('पासे')) {
      if (activeLang == 'te') {
        return '3D డైస్ మెమరీ (3D Dice Memory) ఆటలో:\n'
            'వర్చువల్ బల్లపై 3 నుండి 5 చెక్క పాచికలు కనిపిస్తాయి. కొన్ని సెకన్లలో వాటి సంఖ్యలు మరియు స్థానాలను గమనించండి. తర్వాత పాచికలు మూసివేయబడతాయి. "మధ్య పాచిక సంఖ్య ఎంత?" లేదా "5 సంఖ్య ఏ పాచికపై ఉంది?" వంటి ప్రశ్నలకు సమాధానం ఇవ్వాలి. ఇది స్థానిక మరియు దృశ్య జ్ఞాపకశక్తిని పెంచుతుంది.';
      } else if (activeLang == 'hi') {
        return '3D पासा स्मृति (3D Dice Memory) खेल में:\n'
            'मेज पर 3 से 5 लकड़ी के पासे दिखाई देते हैं। कुछ सेकंड में उनकी संख्याओं और स्थानों को ध्यान से देखें। फिर पासे ढक दिए जाते हैं। आपसे पूछा जाएगा: "बीच के पासे पर कौन सा नंबर था?" या "5 नंबर किस पासे पर था?". यह खेल स्थानिक एकाग्रता को मजबूत करता है।';
      }
      return 'In 3D Dice Memory, 3 to 5 tactile wooden dice appear on a virtual tabletop showing numbers 1 to 6. You have a few seconds to observe their values and spatial arrangement. Mystery cups then cover the dice! You will be asked questions like "Which die showed number 5?" or "What number was on the middle die?". It is a wonderful exercise for spatial orientation and short-term visual recall.';
    }

    // ── 3. Word Memory Puzzle Game ──
    if (lower.contains('word memory') ||
        lower.contains('word puzzle') ||
        lower.contains('word game') ||
        lower.contains('words') ||
        lower.contains('పదాల పజిల్') ||
        lower.contains('పదాలు') ||
        lower.contains('शब्द पहेली') ||
        lower.contains('शब्द स्मरण')) {
      if (activeLang == 'te') {
        return 'వర్డ్ మెమరీ పజిల్ (Word Memory Puzzle) ఆటలో:\n'
            'దీపం, తులసి, చందనం, వీణ వంటి సాంస్కృతిక పదాల జాబితా చూపబడుతుంది. వాటిని గుర్తుంచుకున్న తర్వాత కార్డులు దాచబడతాయి. ఏ పదం ఉంది, లేదా క్రమంలో ఏ పదం తర్వాత ఏది వచ్చిందో గుర్తించాలి. ఇది భాషా మరియు శబ్ద జ్ఞాపకశక్తిని మెరుగుపరుస్తుంది.';
      } else if (activeLang == 'hi') {
        return 'शब्द स्मृति पहेली (Word Memory Puzzle) में:\n'
            'दीपक, तुलसी, चन्दन, वीणा जैसे परिचित सांस्कृतिक शब्दों की एक सूची दिखाई जाती है। याद रखने के बाद शब्द ढक दिए जाते हैं। फिर आपसे पूछा जाता है कि कौन सा शब्द आया था या क्रम क्या था। यह शाब्दिक स्मृति को सुदृढ़ करता है।';
      }
      return 'In Word Memory Puzzle, you observe a sequence of culturally familiar words (such as Deepam, Tulasi, Chandanam, Veena, and Mandir). Memorize them before mystery parchment cards conceal them. Then answer challenges such as identifying which word appeared, which word followed a specific item, or arranging them in order. It strengthens verbal memory and semantic recall.';
    }

    // ── 4. Memory Melody Game ──
    if (lower.contains('memory melody') ||
        lower.contains('melody') ||
        lower.contains('swara') ||
        lower.contains('tune') ||
        lower.contains('song') ||
        lower.contains('music') ||
        lower.contains('మెలోడీ') ||
        lower.contains('సంగీతం') ||
        lower.contains('मेलोडी') ||
        lower.contains('संगीत') ||
        lower.contains('स्वर')) {
      if (activeLang == 'te') {
        return 'మెమరీ మెలోడీ (Memory Melody) ఆటలో:\n'
            'సా, రే, గ, మ వంటి సాంప్రదాయ స్వరాలు మరియు శాంతియుత ధ్వని క్రమాన్ని వింటారు. ప్రతి స్వరంతో రంగు వెలుగుతుంది. సంగీతం ఆగినప్పుడు, అదే క్రమంలో స్వరాలను గుర్తుచేసుకుని తాకాలి. ఇది శ్రవణ జ్ఞాపకశక్తిని మరియు శ్రద్ధను చురుకుగా ఉంచుతుంది.';
      } else if (activeLang == 'hi') {
        return 'मेमोरी मेलोडी (Memory Melody) खेल में:\n'
            'आप सा, रे, ग, म जैसे पारंपरिक भारतीय स्वरों और मधुर धुनों का एक क्रम सुनते हैं। प्रत्येक स्वर के साथ स्क्रीन पर प्रकाश चमकता है। धुन रुकने पर आपको उसी क्रम में स्वरों को दोहराना होता है। यह श्रवण स्मृति और ध्यान को जाग्रत करता है।';
      }
      return 'In Memory Melody, you listen to a peaceful sequence of traditional Indian musical notes (swaras like Sa, Re, Ga, Ma, Pa, Dha, Ni). Watch as each note illuminates on screen. When the melody pauses, your goal is to echo the notes back in the exact order you heard. It provides soothing auditory working memory and sequential recall practice.';
    }

    // ── 5. Fruit Memory Path Game ──
    if (lower.contains('fruit memory') ||
        lower.contains('fruit path') ||
        lower.contains('fruit') ||
        lower.contains('garden path') ||
        lower.contains('పండ్ల మార్గం') ||
        lower.contains('పండ్లు') ||
        lower.contains('फल')) {
      if (activeLang == 'te') {
        return 'ఫ్రూట్ మెమరీ పాత్ (Fruit Memory Path) ఆటలో:\n'
            'తోట దారి పొడవునా మామిడి, ఆపిల్, అరటి వంటి పండ్లు వరుసగా కనిపిస్తాయి. వాటి క్రమాన్ని గమనించి, మార్గాన్ని పూర్తి చేయాలి. ఇది దృశ్య మరియు ప్రాదేశిక జ్ఞాపకశక్తికి చాలా ఉపయోగకరం.';
      } else if (activeLang == 'hi') {
        return 'फ्रूट मेमोरी पाथ (Fruit Memory Path) खेल में:\n'
            'बगीचे के सुंदर रास्ते पर आम, सेब और केले जैसे फल क्रम में दिखाई देते हैं। उनके स्थान और क्रम को याद रखें। फिर सही फल चुनकर रास्ते को पूरा करें। यह स्थानिक स्मृति के लिए उत्तम अभ्यास है।';
      }
      return 'In Fruit Memory Path, you follow a colorful garden path where familiar fruits like mangoes, apples, and bananas appear in sequence along the trail. Observe their positions and order. Once hidden, retrace the path and place the correct fruits at each step. It is an engaging exercise for spatial navigation and visual memory.';
    }

    // ── 6. Other Games (Pattern, Object, Search, Sequence, Stories, Routine) ──
    if (lower.contains('pattern') || lower.contains('grid') || lower.contains('నమూనా') || lower.contains('पैटर्न')) {
      return 'In Pattern Memory, a grid highlights specific tiles in an elegant geometric pattern. Once the pattern vanishes, tap the remembered tiles. It exercises visuospatial working memory and grid orientation.';
    }
    if (lower.contains('object') || lower.contains('shelf') || lower.contains('items') || lower.contains('వస్తువు') || lower.contains('वस्तु')) {
      return 'In Object Memory & Recall, nostalgic household items (brass diya, vintage radio, clay kulhad) are arranged on shelves. Memorize their spots to recall what was present and where each item belonged.';
    }
    if (lower.contains('visual search') || lower.contains('focus') || lower.contains('find') || lower.contains('ఏకాగ్రత') || lower.contains('खोज')) {
      return 'Visual Search & Focus challenges you to spot a target item amongst gentle background distractors. It strengthens selective visual attention and processing speed.';
    }
    if (lower.contains('sequence recall') || lower.contains('reverse sequence') || lower.contains('order') || lower.contains('క్రమం') || lower.contains('अनुक्रम')) {
      return 'In Sequence Recall, you observe numbers, letters, or shapes and reproduce them in forward or reverse order. It exercises mental manipulation and working memory.';
    }
    if (lower.contains('story') || lower.contains('oral heritage') || lower.contains('stories') || lower.contains('కథ') || lower.contains('कहानी')) {
      return 'Oral Heritage Stories shares uplifting traditional parables and folklore. Read or listen to the tale, and answer pleasant recall questions about the characters and events.';
    }

    // ── Cognitive Benefits & Mechanism: "How does Smriti Veda help memory?" ──
    if (lower.contains('help memory') ||
        lower.contains('how does smriti veda help') ||
        lower.contains('helps memory') ||
        lower.contains('how does this app help') ||
        lower.contains('why memory games') ||
        lower.contains('cognitive benefits') ||
        lower.contains('జ్ఞాపకశక్తికి ఎలా సహాయపడుతుంది') ||
        lower.contains('स्मृति में कैसे सहायक')) {
      if (activeLang == 'te') {
        return 'స్మృతివేద జ్ఞాపకశక్తికి ఎలా సహాయపడుతుందంటే:\n'
            '1. శ్రవణ ఏకాగ్రత: సంగీత స్వరాలు మరియు వేద శ్లోకాల ద్వారా శ్రద్ధను చురుకుగా ఉంచుతుంది.\n'
            '2. దృశ్య మరియు ప్రాదేశిక జ్ఞాపకం: 3D Dice మరియు Fruit Path ఆటలు మెదడులోని న్యూరల్ మార్గాలను ఉత్తేజపరుస్తాయి.\n'
            '3. దినచర్య రీకాల్: రోజువారీ పనులను సరైన క్రమంలో సాధన చేయడం ద్వారా స్వతంత్ర జీవన నైపుణ్యాలను కాపాడుతుంది.\n'
            'నిత్యం 10-15 నిమిషాల ప్రశాంత సాధన మానసిక చురుకుదనాన్ని పెంచుతుంది.';
      } else if (activeLang == 'hi') {
        return 'स्मृतिवेद आपकी स्मृति को कैसे सुदृढ़ करता है:\n'
            '1. श्रवण ध्यान: संगीत के स्वरों और पारंपरिक श्लोक पाठ से एकाग्रता बढ़ती है।\n'
            '2. दृश्य और स्थानिक स्मृति: 3D Dice और Fruit Path जैसे खेल मस्तिष्क के न्यूरल पाथवे को सक्रिय रखते हैं।\n'
            '3. दैनिक क्रमबद्धता: दिनचर्या और कार्यों के अनुक्रम को याद रखकर वरिष्ठ नागरिक आत्मनिर्भर रहते हैं।\n'
            'प्रतिदिन 10-15 मिनट का शांत और सुखद अभ्यास मानसिक स्वास्थ्य को सशक्त बनाता है।';
      }
      return 'Smriti Veda helps preserve and strengthen memory through a multi-sensory approach:\n'
          '1. Auditory & Rhythmic Focus: Memory Melody and traditional Shloka chanting activate working memory and auditory processing.\n'
          '2. Visuospatial Stimulation: 3D Dice Memory and Fruit Memory Path exercise spatial orientation and object recall.\n'
          '3. Everyday Functional Recall: Daily Routine and Word Puzzle exercises reinforce sequencing and daily living independence.\n'
          'Just 10 to 15 minutes of gentle daily practice stimulates neuroplasticity in a calm, stress-free environment.';
    }

    // ── Dedicated Memory Game Recommendation: "Recommend a memory game" ──
    if (lower.contains('recommend a memory game') ||
        lower.contains('recommend a game') ||
        lower.contains('recommend memory game') ||
        lower.contains('suggest a game') ||
        lower.contains('suggest a memory game') ||
        lower.contains('ఆటను సిఫార్సు') ||
        lower.contains('खेल की सिफारिश')) {
      if (activeLang == 'te') {
        return 'ఈ రోజు మీ కోసం సిఫార్సు చేయబడిన ఆట:\n'
            'శ్రవణ ఏకాగ్రత మరియు సంగీత స్వరాల సాధన కోసం "Memory Melody" ఆటతో ప్రారంభించండి! లేదా దృశ్య జ్ఞాపకశక్తి కోసం "Fruit Memory Path" లేదా "3D Dice Memory" ప్రయత్నించండి. Practice ట్యాబ్‌లో ఇవి సులభంగా లభిస్తాయి.';
      } else if (activeLang == 'hi') {
        return 'आज के लिए विशेष खेल की सिफारिश:\n'
            'श्रवण एकाग्रता और संगीत स्वरों के लिए "Memory Melody" से शुरुआत करें! या दृश्य स्मृति के लिए "Fruit Memory Path" या "3D Dice Memory" खेलें। ये सभी खेल Practice टैब में उपलब्ध हैं।';
      }
      return 'For an enjoyable memory exercise today, I recommend starting with "Memory Melody" to awaken your auditory focus with soothing Indian swaras, followed by "Fruit Memory Path" for spatial navigation or "3D Dice Memory" for visual retention. Each game adapts gently to your pace!';
    }

    // ── 7. Action Guidance: "What should I do now?" / "What can I practice today?" ──
    if (lower.contains('what should i do') ||
        lower.contains('what to do now') ||
        lower.contains('what do i do') ||
        lower.contains('what can i practice') ||
        lower.contains('what to practice') ||
        lower.contains('where should i start') ||
        lower.contains('where to start') ||
        lower.contains('what now') ||
        lower.contains('suggest') ||
        lower.contains('recommend') ||
        lower.contains('start today') ||
        lower.contains('ఏం చేయాలి') ||
        lower.contains('ఇప్పుడు ఏమి చేయాలి') ||
        lower.contains('अब क्या करें') ||
        lower.contains('क्या करना चाहिए')) {
      if (activeLang == 'te') {
        return 'ఇప్పుడు మీరు చేయగల ఉత్తమ సాధన ప్రణాళిక:\n'
            '1. శ్రవణ ఏకాగ్రత కోసం ముందుగా "Memory Melody" ఆటను ఎంచుకోండి.\n'
            '2. తర్వాత దృశ్య ప్రాదేశిక సాధన కోసం "3D Dice Memory" లేదా "Fruit Memory Path" ఆడండి.\n'
            '3. చివరగా Cultural విభాగంలో 5 నిమిషాల ప్రశాంత శ్లోక సాధన చేయండి.\n'
            'ఎలాంటి తొందరపాటు లేకుండా, ప్రశాంతంగా ఆనందించండి!';
      } else if (activeLang == 'hi') {
        return 'आज के लिए एक उत्तम अभ्यास योजना:\n'
            '1. सबसे पहले अपने कानों और ध्यान को केंद्रित करने के लिए "Memory Melody" खेलें।\n'
            '2. इसके बाद दृश्य और स्थानिक स्मृति के लिए "3D Dice Memory" या "Fruit Memory Path" का अभ्यास करें।\n'
            '3. अंत में Cultural सेक्शन में 5 मिनट का शांत श्लोक पाठ करें।\n'
            'आराम से और बिना किसी जल्दबाजी के अपनी गति से अभ्यास करें!';
      }
      return 'Here is a wonderful, balanced practice plan for you right now:\n'
          '1. Start with "Memory Melody" to warm up your auditory focus with gentle musical swaras.\n'
          '2. Next, play a quick session of "3D Dice Memory" or "Fruit Memory Path" to exercise your visual and spatial memory.\n'
          '3. Finish with 5 minutes of calming Shloka recitation in the Cultural section.\n'
          'Take your time, enjoy each step peacefully, and remember there is never any hurry!';
    }

    // ── 8. Available Games Listing: "What games are available?" ──
    if (lower.contains('what games') ||
        lower.contains('which games') ||
        lower.contains('available games') ||
        lower.contains('list games') ||
        lower.contains('all games') ||
        lower.contains('games in app') ||
        lower.contains('games can i play') ||
        lower.contains('show games') ||
        lower.contains('game list') ||
        lower.contains('ఏ ఆటలు') ||
        lower.contains('ఆటల జాబితా') ||
        lower.contains('कौन से खेल') ||
        lower.contains('खेलों की सूची')) {
      if (activeLang == 'te') {
        return 'స్మృతివేదలో 10 ప్రత్యేక జ్ఞాపకశక్తి ఆటలు ఉన్నాయి:\n'
            '1. Fruit Memory Path (పండ్ల మార్గం - ప్రాదేశిక నావిగేషన్)\n'
            '2. Memory Melody (సంగీత స్వరాల శ్రవణ సాధన)\n'
            '3. 3D Dice Memory (3D పాచికల సంఖ్య మరియు స్థానాలు)\n'
            '4. Word Memory Puzzle (సాంస్కృతిక పదాల పజిల్)\n'
            '5. Pattern Memory (గ్రిడ్ నమూనాలు)\n'
            '6. Object Memory & Recall (గృహ వస్తువుల జ్ఞాపకం)\n'
            '7. Visual Search & Focus (దృష్టి ఏకాగ్రత)\n'
            '8. Sequence Recall (క్రమ సంఖ్యల సాధన)\n'
            '9. Oral Heritage Stories (కథా జ్ఞానం)\n'
            '10. Daily Routine Recall (దినచర్య క్రమం)\n'
            'Practice ట్యాబ్‌లో మీకు నచ్చిన ఆటను ప్రారంభించవచ్చు!';
      } else if (activeLang == 'hi') {
        return 'स्मृतिवेद में 10 विशेष संज्ञानात्मक खेल उपलब्ध हैं:\n'
            '1. Fruit Memory Path (फलों का मार्ग - स्थानिक स्मृति)\n'
            '2. Memory Melody (मधुर स्वरों का श्रवण अभ्यास)\n'
            '3. 3D Dice Memory (पासे की संख्या और स्थान)\n'
            '4. Word Memory Puzzle (सांस्कृतिक शब्द पहेली)\n'
            '5. Pattern Memory (ग्रिड पैटर्न स्मरण)\n'
            '6. Object Memory & Recall (घरेलू वस्तुओं का स्थान)\n'
            '7. Visual Search & Focus (दृश्य एकाग्रता)\n'
            '8. Sequence Recall (क्रमबद्ध स्मरण)\n'
            '9. Oral Heritage Stories (पारंपरिक कहानियाँ)\n'
            '10. Daily Routine Recall (दैनिक कार्यों का क्रम)\n'
            'आप Practice टैब में जाकर कोई भी खेल शुरू कर सकते हैं!';
      }
      return 'SmritiVeda offers 10 specialized, replayable cognitive memory games:\n'
          '1. Fruit Memory Path (Spatial navigation & path memory)\n'
          '2. Memory Melody (Auditory swara notes & melodic recall)\n'
          '3. 3D Dice Memory (Tabletop spatial arrangement & numbers)\n'
          '4. Word Memory Puzzle (Culturally familiar word sequences)\n'
          '5. Pattern Memory (Visual grid patterns & working memory)\n'
          '6. Object Memory & Recall (Household items & spatial placement)\n'
          '7. Visual Search & Focus (Visual attention & target discrimination)\n'
          '8. Sequence Recall (Number & word order, forward & reverse)\n'
          '9. Oral Heritage Stories (Cultural narrative comprehension)\n'
          '10. Daily Routine Recall (Daily living activities & task order)\n'
          'You can select any of these anytime from the Practice tab!';
    }

    // ── 9. App Overview: "Tell me what's there in the app" ──
    if (lower.contains("what's there in the app") ||
        lower.contains("what is there in the app") ||
        lower.contains("what is in the app") ||
        lower.contains("what is in this app") ||
        lower.contains("what is this app") ||
        lower.contains("what is smritiveda") ||
        lower.contains("about the app") ||
        lower.contains("app overview") ||
        lower.contains("features") ||
        lower.contains("tell me about the app") ||
        (lower.contains("what") && lower.contains("in the app")) ||
        lower.contains('యాప్‌లో ఏముంది') ||
        lower.contains('ఈ యాప్ ఏమిటి') ||
        lower.contains('ऐप में क्या है') ||
        lower.contains('इस ऐप के बारे में')) {
      if (activeLang == 'te') {
        return 'స్మృతివేద (SmritiVeda) సీనియర్ పౌరుల మానసిక ఉల్లాసం మరియు జ్ఞాపకశక్తి కోసం రూపొందించబడింది. ఇందులో ఉన్న ముఖ్య విభాగాలు:\n'
            '• 10 పునరావృత జ్ఞాపకశక్తి ఆటలు (Fruit Path, Memory Melody, 3D Dice, మొదలైనవి)\n'
            '• పవిత్ర శ్లోక సాధన (Listen, Echo, Recall, Arrange పద్ధతుల్లో)\n'
            '• రోజువారీ జ్ఞాపకశక్తి దినచర్య (కుటుంబ విశేషాలు, దినచర్యలు)\n'
            '• మెడికల్ రిపోర్ట్స్ హబ్ (ప్రిస్క్రిప్షన్‌లు, ల్యాబ్ రిపోర్టుల సురక్షిత వ్యూయర్)\n'
            '• ప్రోగ్రెస్ ట్రాకింగ్ & కేర్ గివర్ డ్యాష్‌బోర్డ్';
      } else if (activeLang == 'hi') {
        return 'स्मृतिवेद (SmritiVeda) वरिष्ठ नागरिकों के संज्ञानात्मक स्वास्थ्य और स्मृति संवर्धन के लिए बनाया गया है। इस ऐप में शामिल हैं:\n'
            '• 10 पुनः खेलने योग्य स्मृति खेल (Fruit Path, Memory Melody, 3D Dice, आदि)\n'
            '• पारंपरिक श्लोक अभ्यास (सुनना, दोहराना, स्मरण और क्रमबद्ध करना)\n'
            '• दैनिक स्मृति एंकर (पारिवारिक यादें और दिनचर्या)\n'
            '• मेडिकल रिपोर्ट हब (दवा के पर्चे और जाँच रिपोर्ट का सुरक्षित व्यूअर)\n'
            '• प्रगति ट्रैकिंग और देखभालकर्ता (Caregiver) डैशबोर्ड';
      }
      return 'SmritiVeda is your complete, culturally grounded cognitive wellness companion for healthy aging. In this app, you have:\n'
          '• 10 Replayable Memory Games (Fruit Path, Memory Melody, 3D Dice, Word Memory, Pattern Memory, etc.)\n'
          '• Cultural Shloka Recitation (Listen, Echo, Recall & Arrange traditional sacred verses)\n'
          '• Everyday Memory Anchors (Keep track of personal memories, family moments & daily routines)\n'
          '• Medical Reports Hub (Safely store and view prescriptions, laboratory tests, and doctor scans)\n'
          '• Progress Tracking & Caregiver Insights (Follow your engagement streaks and cognitive wellness)\n'
          'Everything is designed with large text, soothing colors, and elderly-friendly touch controls.';
    }

    // ── 10. Shloka / Cultural Practice ──
    if (lower.contains('shloka') ||
        lower.contains('mantra') ||
        lower.contains('verse') ||
        lower.contains('chant') ||
        lower.contains('cultural') ||
        lower.contains('శ్లోక') ||
        lower.contains('మంత్ర') ||
        lower.contains('श्लोक') ||
        lower.contains('मंत्र')) {
      if (activeLang == 'te') {
        return 'శ్లోక సాధనలో 4 ప్రశాంత దశలు ఉన్నాయి: వినడం (Listen), అనువాదించడం (Echo), గుర్తుతెచ్చుకోవడం (Recall), మరియు క్రమబద్ధీకరించడం (Arrange). ప్రతిరోజూ 5 నిమిషాల గాయత్రీ లేదా మృత్యుంజయ మంత్ర సాధన మనస్సును ప్రశాంతంగా ఉంచుతుంది.';
      } else if (activeLang == 'hi') {
        return 'श्लोक अभ्यास में 4 चरण हैं: सुनना (Listen), दोहराना (Echo), स्मरण (Recall), और क्रमबद्ध करना (Arrange)। प्रतिदिन 5 मिनट महामृत्युंजय या गायत्री मंत्र का पाठ मानसिक एकाग्रता को सुदृढ़ करता है।';
      }
      return 'Our sacred shloka practice has 4 progressive steps: Listen (synchronized chanting), Echo (recite along with audio pauses), Recall (select or speak the missing phrase), and Arrange (sequence the verse in proper meter). Practicing 5 minutes daily brings deep mental tranquility and sharpens auditory focus.';
    }

    // ── 11. Progress & Streak ──
    if (lower.contains('progress') ||
        lower.contains('streak') ||
        lower.contains('score') ||
        lower.contains('performance') ||
        lower.contains('how am i doing') ||
        lower.contains('పురోగతి') ||
        lower.contains('స్కోరు') ||
        lower.contains('प्रगति') ||
        lower.contains('स्कोर')) {
      if (activeLang == 'te') {
        return 'మీరు చాలా చక్కగా సాధన చేస్తున్నారు! మీ రోజువారీ స్ట్రీక్ మరియు పూర్తి చేసిన సెషన్లను చూడటానికి Progress ట్యాబ్‌ను తెరవండి. ప్రశాంతమైన నిత్య సాధన మనస్సును ఎల్లప్పుడూ చురుకుగా ఉంచుతుంది.';
      } else if (activeLang == 'hi') {
        return 'आपका अभ्यास बहुत सराहनीय है! अपने दैनिक स्ट्रीक और पूर्ण किए गए सत्रों को देखने के लिए Progress टैब खोलें। नियमित और शांत अभ्यास से मन सदैव प्रसन्न और सक्रिय रहता है।';
      }
      return 'You are doing wonderfully! You can view your detailed daily streak and completed exercise breakdown anytime on the "Progress" tab. Consistent, peaceful practice stimulates neural pathways and keeps your focus active. Keep up your wonderful routine!';
    }

    // ── 12. Daily Routine & Everyday Memory ──
    if (lower.contains('routine') ||
        lower.contains('medicine') ||
        lower.contains('evening') ||
        lower.contains('water') ||
        lower.contains('everyday memory') ||
        lower.contains('దినచర్య') ||
        lower.contains('दिनचर्या')) {
      if (activeLang == 'te') {
        return 'ఆరోగ్యకరమైన దినచర్య: ఉదయం ప్రాణాయామం, సమయానికి మందులు తీసుకోవడం, సరిపడా నీరు త్రాగడం, మరియు సాయంత్రం ప్రశాంతంగా నడవడం. రోజువారీ పనులను సరైన క్రమంలో సాధన చేయడానికి Daily Routine ఆటను ప్రయత్నించండి.';
      } else if (activeLang == 'hi') {
        return 'स्वस्थ दिनचर्या: प्रातःकाल प्राणायाम, समय पर दवा लेना, पर्याप्त जल पीना, और शाम को हल्की सैर। दैनिक कार्यों को सही क्रम में व्यवस्थित करने के लिए Daily Routine खेल का अभ्यास करें।';
      }
      return 'A healthy senior routine includes gentle morning breathing, timely medication, staying well-hydrated, and evening relaxation. You can also practice our "Daily Routine Recall" exercise to order real-world activities and reinforce everyday living memory.';
    }

    // ── 13. Caregiver Support ──
    if (lower.contains('caregiver') ||
        lower.contains('family') ||
        lower.contains('connect') ||
        lower.contains('సంరక్షకుడు') ||
        lower.contains('देखभालकर्ता')) {
      return 'SmritiVeda allows a trusted caregiver or family member to link with your profile via a private pairing code. From their Caregiver Dashboard, they can view your practice consistency and celebrate your milestones while respecting your personal independence.';
    }

    // ── 14. Normal Polite Greeting (Only pure greetings, not questions!) ──
    if (lower == 'hello' ||
        lower == 'hi' ||
        lower == 'namaste' ||
        lower == 'hey' ||
        lower == 'good morning' ||
        lower == 'good afternoon' ||
        lower == 'good evening' ||
        lower == 'hi there' ||
        lower == 'hello there' ||
        lower == 'నమస్కారం' ||
        lower == 'హలో' ||
        lower == 'नमस्ते' ||
        lower == 'प्रणाम') {
      if (activeLang == 'te') {
        return 'నమస్కారం! నేను మీ స్మృతివేద AI సహాయకుడిని. నేటి శ్లోక సాధన, జ్ఞాపకశక్తి ఆటలు లేదా మీ మెడికల్ రిపోర్టుల గురించి ఏదైనా అడగవచ్చు. మీకు ఎలా సహాయపడగలను?';
      } else if (activeLang == 'hi') {
        return 'नमस्ते! मैं आपका स्मृतिवेद AI सहायक हूँ। आज के श्लोक पाठ, स्मृति खेलों या मेडिकल रिपोर्ट के विषय में मुझसे कुछ भी पूछ सकते हैं। मैं आपकी क्या सहायता करूँ?';
      }
      return 'Namaste! I am your SmritiVeda AI Assistant. I am here to guide your daily memory exercises, Shloka recitation, and health records. How may I support your practice today?';
    }

    // ── 15. Contextual Helpful Fallback (Never a repetitive canned greeting!) ──
    if (activeLang == 'te') {
      return 'నమస్కారం! స్మృతివేద సహాయకుడిగా నేను మీకు సహాయం చేయడానికి సిద్ధంగా ఉన్నాను. మీరు నన్ను అడగవచ్చు:\n'
          '• "యాప్‌లో ఏముంది?" - అన్ని సౌకర్యాల వివరణ కోసం\n'
          '• "ఏ ఆటలు ఉన్నాయి?" - 10 జ్ఞాపకశక్తి ఆటల జాబితా కోసం\n'
          '• "ఇప్పుడు ఏమి చేయాలి?" - సిఫార్సు చేయబడిన సాధన కోసం\n'
          '• "Memory Melody ఎలా పనిచేస్తుంది?" లేదా "3D Dice ఆట ఎలా ఆడాలి?"\n'
          '• "నా మెడికల్ రిపోర్టులను ఎలా చూడాలి?"';
    } else if (activeLang == 'hi') {
      return 'नमस्ते! स्मृतिवेद AI सहायक के रूप में मैं आपकी सहायता के लिए उपस्थित हूँ। आप मुझसे पूछ सकते हैं:\n'
          '• "ऐप में क्या है?" - सभी सुविधाओं की जानकारी के लिए\n'
          '• "कौन से खेल उपलब्ध हैं?" - 10 स्मृति खेलों की सूची\n'
          '• "अब क्या करना चाहिए?" - आज के अभ्यास की सलाह\n'
          '• "Memory Melody कैसे काम करता है?" या "3D Dice खेल क्या है?"\n'
          '• "अपनी मेडिकल रिपोर्ट कैसे देखें?"';
    }
    return 'Namaste! I am happy to assist you with SmritiVeda. You can ask me:\n'
        '• "What\'s there in the app?" for a complete overview\n'
        '• "What games are available?" to explore all 10 memory games\n'
        '• "What should I do now?" for an actionable practice recommendation\n'
        '• "How does Memory Melody work?" or "What is 3D Dice Memory?" for game guides\n'
        '• "How do I view my medical reports?" for help opening prescriptions\n'
        'What would you like to explore right now?';
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
      return 'Namaste! Please feel free to ask any question about your daily exercises, memory games, or medical reports.';
    }

    // ── Clinical & Caregiver Authorization Boundary Guardrail ──
    final lower = cleanPrompt.toLowerCase();
    if (lower.contains('dementia stage') ||
        lower.contains('cognitive decline') ||
        lower.contains('worsening') ||
        lower.contains('caregiver password') ||
        lower.contains('clinical diagnosis') ||
        lower.contains('prescribe') ||
        lower.contains('dosage') ||
        lower.contains('cure dementia') ||
        lower.contains('cure alzheimer') ||
        lower.contains('treat dementia')) {
      return caregiverBoundaryNotice;
    }

    // Check Cache
    final cacheKey = '$languageCode::${cleanPrompt.toLowerCase()}';
    if (_responseCache.containsKey(cacheKey)) {
      return _responseCache[cacheKey]!;
    }

    // 1. Primary AI Provider: Google Gemini (if configured and online)
    if (_gemini.isAvailable) {
      try {
        final res = await _gemini.chat(
          prompt: cleanPrompt,
          languageCode: languageCode,
          systemPrompt: systemPrompt ?? smritiVedaSystemPrompt,
        );
        if (res.isNotEmpty) {
          _responseCache[cacheKey] = res;
          return res;
        }
      } catch (e) {
        debugPrint('Gemini primary provider notice: $e');
      }
    }

    // 2. Secondary Fallback: OmniRoute Gateway (ONLY if explicitly configured)
    if (_omniRoute.isAvailable) {
      try {
        final res = await _omniRoute.chat(
          prompt: cleanPrompt,
          languageCode: languageCode,
          systemPrompt: systemPrompt ?? smritiVedaSystemPrompt,
        );
        if (res.isNotEmpty) {
          _responseCache[cacheKey] = res;
          return res;
        }
      } catch (e) {
        debugPrint('OmniRoute fallback notice: $e');
      }
    }

    // 3. Tertiary Fallback: Bhashini (if active)
    if (_bhashini.isAvailable) {
      try {
        final res = await _bhashini.chat(
          prompt: cleanPrompt,
          languageCode: languageCode,
          systemPrompt: systemPrompt ?? smritiVedaSystemPrompt,
        );
        if (res.isNotEmpty) {
          _responseCache[cacheKey] = res;
          return res;
        }
      } catch (e) {
        debugPrint('Bhashini fallback notice: $e');
      }
    }

    // 4. Reliable Offline Deterministic Contextual Guidance
    final offlineRes = await _offline.chat(
      prompt: cleanPrompt,
      languageCode: languageCode,
      systemPrompt: systemPrompt,
    );
    _responseCache[cacheKey] = offlineRes;
    return offlineRes;
  }
}
