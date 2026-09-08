import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'db_service.dart';

class MemoryMelodyQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String taskType; // 'item_recall', 'sequence_recall', 'attention', 'delayed_recall'
  final String hint;

  const MemoryMelodyQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.taskType,
    required this.hint,
  });

  Map<String, dynamic> toJson() => {
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer,
    'taskType': taskType,
    'hint': hint,
  };

  factory MemoryMelodyQuestion.fromJson(Map<String, dynamic> json) {
    return MemoryMelodyQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? '',
      taskType: json['taskType'] ?? 'item_recall',
      hint: json['hint'] ?? '',
    );
  }
}

class EventOrderStep {
  final int id;
  final String text;
  final int correctOrder;
  final String iconName;

  const EventOrderStep({
    required this.id,
    required this.text,
    required this.correctOrder,
    required this.iconName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'correctOrder': correctOrder,
    'iconName': iconName,
  };

  factory EventOrderStep.fromJson(Map<String, dynamic> json) {
    return EventOrderStep(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      correctOrder: json['correctOrder'] ?? 0,
      iconName: json['iconName'] ?? 'event',
    );
  }

  IconData get icon {
    switch (iconName.toLowerCase()) {
      case 'sun':
      case 'morning':
        return Icons.wb_sunny_rounded;
      case 'water':
      case 'drink':
        return Icons.local_drink_rounded;
      case 'medication':
      case 'medicine':
        return Icons.medication_rounded;
      case 'fruit':
      case 'apple':
      case 'banana':
        return Icons.eco_rounded;
      case 'walk':
      case 'garden':
        return Icons.directions_walk_rounded;
      case 'tea':
        return Icons.emoji_food_beverage_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }
}

class SongContent {
  final String id;
  final String title;
  final String theme;
  final String language;
  final String difficulty;
  final String lyrics;
  final List<String> lines;
  final List<EventOrderStep> events;
  final List<MemoryMelodyQuestion> questions;
  final MemoryMelodyQuestion delayedQuestion;
  final String? audioUrl;
  final int tempoBpm;

  const SongContent({
    required this.id,
    required this.title,
    required this.theme,
    required this.language,
    required this.difficulty,
    required this.lyrics,
    required this.lines,
    required this.events,
    required this.questions,
    required this.delayedQuestion,
    this.audioUrl,
    this.tempoBpm = 72,
  });
}

class SongGenerationService {
  static final Map<String, SongContent> _songCache = {};
  static final SongGenerationService _instance = SongGenerationService._internal();
  factory SongGenerationService() => _instance;
  SongGenerationService._internal();

  /// Curated regional offline songs (guaranteed 100% available without network)
  static final List<SongContent> _curatedSongs = [
    SongContent(
      id: 'curated_ravi_garden',
      title: "Ravi's Morning Garden Harmony",
      theme: 'Morning Routine & Garden',
      language: 'English',
      difficulty: 'Medium',
      lyrics: "Ravi wakes with the golden morning sun,\nDrinks warm herbal water, day begun.\nHe takes his morning medicine, eats a crisp red apple too,\nThen walks calmly into the garden with a quiet view.",
      lines: [
        'Ravi wakes with the golden morning sun,',
        'Drinks warm herbal water, day begun.',
        'He takes his morning medicine, eats a crisp red apple too,',
        'Then walks calmly into the garden with a quiet view.',
      ],
      events: [
        EventOrderStep(id: 1, text: 'Woke up with the morning sun', correctOrder: 1, iconName: 'sun'),
        EventOrderStep(id: 2, text: 'Drank warm herbal water', correctOrder: 2, iconName: 'water'),
        EventOrderStep(id: 3, text: 'Took morning medicine', correctOrder: 3, iconName: 'medicine'),
        EventOrderStep(id: 4, text: 'Walked into the garden', correctOrder: 4, iconName: 'garden'),
      ],
      questions: [
        MemoryMelodyQuestion(
          question: 'What fruit did Ravi eat during his morning routine?',
          options: ['Apple', 'Banana', 'Orange', 'Papaya'],
          correctAnswer: 'Apple',
          taskType: 'item_recall',
          hint: 'It was crisp and red.',
        ),
        MemoryMelodyQuestion(
          question: 'What did Ravi do right after taking his morning medicine?',
          options: ['Ate an apple and walked to the garden', 'Went back to sleep', 'Watered the plants', 'Read the newspaper'],
          correctAnswer: 'Ate an apple and walked to the garden',
          taskType: 'sequence_recall',
          hint: 'He enjoyed fruit before stepping into the garden.',
        ),
        MemoryMelodyQuestion(
          question: 'Attention Check: What kind of water did Ravi drink?',
          options: ['Warm herbal water', 'Cold iced water', 'River water', 'Coconut water'],
          correctAnswer: 'Warm herbal water',
          taskType: 'attention',
          hint: 'It was warm and healthy.',
        ),
      ],
      delayedQuestion: MemoryMelodyQuestion(
        question: 'Delayed Recall: What was the very first thing that greeted Ravi when he woke up?',
        options: ['Golden morning sun', 'Alarm clock', 'Neighbor calling', 'Rain shower'],
        correctAnswer: 'Golden morning sun',
        taskType: 'delayed_recall',
        hint: 'It shone brightly in the morning sky.',
      ),
    ),

    SongContent(
      id: 'curated_priya_assam',
      title: "Priya's Assam Tea Garden Walk",
      theme: 'Assam Tea Estate & Heritage',
      language: 'English',
      difficulty: 'Medium',
      lyrics: "Priya wraps her warm handloom shawl of green,\nSips fragrant ginger tea in a cup so clean.\nShe plucks three tender tea leaves by the bamboo hedge,\nAnd waves to friend Biren by the river water edge.",
      lines: [
        'Priya wraps her warm handloom shawl of green,',
        'Sips fragrant ginger tea in a cup so clean.',
        'She plucks three tender tea leaves by the bamboo hedge,',
        'And waves to friend Biren by the river water edge.',
      ],
      events: [
        EventOrderStep(id: 1, text: 'Wrapped warm green shawl', correctOrder: 1, iconName: 'morning'),
        EventOrderStep(id: 2, text: 'Sipped fragrant ginger tea', correctOrder: 2, iconName: 'tea'),
        EventOrderStep(id: 3, text: 'Plucked tender tea leaves', correctOrder: 3, iconName: 'fruit'),
        EventOrderStep(id: 4, text: 'Waved to friend Biren', correctOrder: 4, iconName: 'walk'),
      ],
      questions: [
        MemoryMelodyQuestion(
          question: 'What kind of tea did Priya enjoy in the morning?',
          options: ['Fragrant ginger tea', 'Black coffee', 'Sweet lassi', 'Cold lemonade'],
          correctAnswer: 'Fragrant ginger tea',
          taskType: 'item_recall',
          hint: 'It had soothing fresh ginger.',
        ),
        MemoryMelodyQuestion(
          question: 'What did Priya do immediately after sipping her tea?',
          options: ['Plucked three tender tea leaves', 'Waved to friend Biren', 'Washed her cup', 'Went to the market'],
          correctAnswer: 'Plucked three tender tea leaves',
          taskType: 'sequence_recall',
          hint: 'She visited the bamboo hedge.',
        ),
        MemoryMelodyQuestion(
          question: "Attention Check: What color was Priya's handloom shawl?",
          options: ['Green', 'Red', 'Yellow', 'Blue'],
          correctAnswer: 'Green',
          taskType: 'attention',
          hint: 'The color of lush tea leaves.',
        ),
      ],
      delayedQuestion: MemoryMelodyQuestion(
        question: 'Delayed Recall: Whom did Priya wave to at the river edge?',
        options: ['Friend Biren', 'Her brother', 'The boatman', 'The tea merchant'],
        correctAnswer: 'Friend Biren',
        taskType: 'delayed_recall',
        hint: 'A familiar neighbor by the water.',
      ),
    ),

    SongContent(
      id: 'curated_moni_brahmaputra',
      title: "Moni's Brahmaputra Riverbank Morning",
      theme: 'Riverfront & Temple Bells',
      language: 'English',
      difficulty: 'Easy',
      lyrics: "Moni hears the temple bell ring across the shore,\nFeeds little yellow corn to doves beside the door.\nShe fills her copper vessel with pure water clear,\nAnd listens to the river song she holds so dear.",
      lines: [
        'Moni hears the temple bell ring across the shore,',
        'Feeds little yellow corn to doves beside the door.',
        'She fills her copper vessel with pure water clear,',
        'And listens to the river song she holds so dear.',
      ],
      events: [
        EventOrderStep(id: 1, text: 'Heard the temple bell ring', correctOrder: 1, iconName: 'morning'),
        EventOrderStep(id: 2, text: 'Fed yellow corn to doves', correctOrder: 2, iconName: 'fruit'),
        EventOrderStep(id: 3, text: 'Filled copper water vessel', correctOrder: 3, iconName: 'water'),
        EventOrderStep(id: 4, text: 'Listened to the river song', correctOrder: 4, iconName: 'walk'),
      ],
      questions: [
        MemoryMelodyQuestion(
          question: 'What grain did Moni feed to the doves?',
          options: ['Yellow corn', 'White rice', 'Wheat grains', 'Sunflower seeds'],
          correctAnswer: 'Yellow corn',
          taskType: 'item_recall',
          hint: 'Bright yellow grains.',
        ),
        MemoryMelodyQuestion(
          question: 'What did Moni do right after feeding the doves?',
          options: ['Filled her copper vessel with water', 'Went to the temple', 'Rang the bell', 'Cooked lunch'],
          correctAnswer: 'Filled her copper vessel with water',
          taskType: 'sequence_recall',
          hint: 'She carried water from the riverbank.',
        ),
        MemoryMelodyQuestion(
          question: "Attention Check: What metal was Moni's water vessel made of?",
          options: ['Copper', 'Silver', 'Clay', 'Steel'],
          correctAnswer: 'Copper',
          taskType: 'attention',
          hint: 'Traditional warm reddish metal.',
        ),
      ],
      delayedQuestion: MemoryMelodyQuestion(
        question: 'Delayed Recall: What sound did Moni hear at the very beginning?',
        options: ['Temple bell across the shore', 'Train whistle', 'Thunder storm', 'Market vendor'],
        correctAnswer: 'Temple bell across the shore',
        taskType: 'delayed_recall',
        hint: 'A peaceful resonant chime.',
      ),
    ),
  ];

  /// Generates or selects dynamic song content for Memory Melody
  Future<SongContent> generateSong({
    String language = 'English',
    String theme = 'Morning Wellness',
    String difficulty = 'Medium',
    String patientName = 'Friend',
  }) async {
    final cacheKey = '$patientName|$theme|$language|$difficulty';
    if (_songCache.containsKey(cacheKey)) {
      return _songCache[cacheKey]!;
    }

    final apiKey = DbService().geminiApiKey;
    final isAiEnabled = DbService().isAiEnabled;

    if (isAiEnabled && apiKey.isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
        );

        final prompt = '''
You are the Cognitive Music & Rhythmic Memory Specialist in Smriti Veda (SIH26003).
Generate a memorable 4-line rhythmic song/story and associated cognitive recall questions for elderly patient "$patientName".
Theme: $theme
Language: $language
Difficulty: $difficulty

Output ONLY a single valid JSON object with NO markdown ticks or backticks:
{
  "title": "Morning Melody for $patientName",
  "theme": "$theme",
  "language": "$language",
  "difficulty": "$difficulty",
  "lyrics": "4-line rhyming verse (20-25 seconds length) mentioning at least 2 distinct items and 3 sequential actions",
  "lines": ["Line 1", "Line 2", "Line 3", "Line 4"],
  "events": [
    {"id": 1, "text": "First action", "correctOrder": 1, "iconName": "sun"},
    {"id": 2, "text": "Second action", "correctOrder": 2, "iconName": "water"},
    {"id": 3, "text": "Third action", "correctOrder": 3, "iconName": "medicine"},
    {"id": 4, "text": "Fourth action", "correctOrder": 4, "iconName": "walk"}
  ],
  "questions": [
    {
      "question": "Specific question about an item mentioned in the lyrics",
      "options": ["Correct Item", "Wrong A", "Wrong B", "Wrong C"],
      "correctAnswer": "Correct Item",
      "taskType": "item_recall",
      "hint": "Gentle hint for an elder"
    },
    {
      "question": "What happened immediately after [action]?",
      "options": ["Correct Next Action", "Wrong 1", "Wrong 2", "Wrong 3"],
      "correctAnswer": "Correct Next Action",
      "taskType": "sequence_recall",
      "hint": "Remember the sequence of lines"
    },
    {
      "question": "Attention question about a specific attribute (color, time, or detail)",
      "options": ["Correct Detail", "Wrong X", "Wrong Y", "Wrong Z"],
      "correctAnswer": "Correct Detail",
      "taskType": "attention",
      "hint": "Focus on the descriptive detail"
    }
  ],
  "delayedQuestion": {
    "question": "What was the very first thing mentioned in line 1?",
    "options": ["Correct First Element", "Wrong Opt 1", "Wrong Opt 2", "Wrong Opt 3"],
    "correctAnswer": "Correct First Element",
    "taskType": "delayed_recall",
    "hint": "Recall the opening words"
  }
}
''';

        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [{'text': prompt}]
              }
            ]
          }),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final resJson = jsonDecode(response.body);
          final candidates = resJson['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            String rawText = candidates.first['content']['parts'][0]['text'] as String;
            rawText = rawText.replaceAll('```json', '').replaceAll('```', '').trim();

            final parsed = jsonDecode(rawText) as Map<String, dynamic>;
            final song = _parseAiSong(parsed);
            if (song != null) {
              _songCache[cacheKey] = song;
              return song;
            }
          }
        }
      } catch (e) {
        debugPrint('Song Generation Notice: Using curated regional song ($e)');
      }
    }

    // High quality deterministic fallback matching theme/difficulty
    return getCuratedFallback(theme: theme, difficulty: difficulty);
  }

  static SongContent? _parseAiSong(Map<String, dynamic> json) {
    try {
      final lines = List<String>.from(json['lines'] ?? []);
      if (lines.length < 2) return null;

      final eventsJson = json['events'] as List? ?? [];
      final events = eventsJson.map((e) => EventOrderStep.fromJson(e as Map<String, dynamic>)).toList();

      final questionsJson = json['questions'] as List? ?? [];
      final questions = questionsJson.map((q) => MemoryMelodyQuestion.fromJson(q as Map<String, dynamic>)).toList();

      final delayedJson = json['delayedQuestion'] as Map<String, dynamic>?;
      if (delayedJson == null || questions.length < 2 || events.length < 3) return null;

      return SongContent(
        id: 'ai_song_${DateTime.now().millisecondsSinceEpoch}',
        title: json['title'] ?? 'Morning Melody',
        theme: json['theme'] ?? 'Daily Wellness',
        language: json['language'] ?? 'English',
        difficulty: json['difficulty'] ?? 'Medium',
        lyrics: json['lyrics'] ?? lines.join('\n'),
        lines: lines,
        events: events,
        questions: questions,
        delayedQuestion: MemoryMelodyQuestion.fromJson(delayedJson),
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns one of the curated regional offline songs
  static SongContent getCuratedFallback({String theme = '', String difficulty = 'Medium'}) {
    final lower = theme.toLowerCase();
    if (lower.contains('tea') || lower.contains('assam')) {
      return _curatedSongs[1];
    } else if (lower.contains('river') || lower.contains('bell') || lower.contains('water')) {
      return _curatedSongs[2];
    }
    return _curatedSongs[0];
  }

  static List<SongContent> get allCuratedSongs => List.unmodifiable(_curatedSongs);
}
