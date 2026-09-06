class MemoryContentItem {
  final String id;
  final String category; // 'Verse', 'Song', 'Proverb', 'Rhyme', 'Saying'
  final String title;
  final String originalScriptText;
  final String transliteration;
  final String englishMeaning;
  final String englishExplanation;
  final String source; // 'Sanskrit Veda', 'Sant Kabir', 'Vemana Telugu', 'Thirukkural Tamil', 'Tagore Bengali', 'Assam Folk'
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final String cognitivePurpose;
  final List<String> chunks;
  final String? audioAssetUri;
  final String languageCode; // 'sa', 'hi', 'te', 'ta', 'as', 'bn'

  const MemoryContentItem({
    required this.id,
    required this.category,
    required this.title,
    required this.originalScriptText,
    required this.transliteration,
    required this.englishMeaning,
    required this.englishExplanation,
    this.source = 'Traditional Oral Memory',
    this.difficulty = 'Easy',
    required this.cognitivePurpose,
    required this.chunks,
    this.audioAssetUri,
    this.languageCode = 'en',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'title': title,
        'originalScriptText': originalScriptText,
        'transliteration': transliteration,
        'englishMeaning': englishMeaning,
        'englishExplanation': englishExplanation,
        'source': source,
        'difficulty': difficulty,
        'cognitivePurpose': cognitivePurpose,
        'chunks': chunks,
        'audioAssetUri': audioAssetUri,
        'languageCode': languageCode,
      };

  factory MemoryContentItem.fromJson(Map<String, dynamic> json) => MemoryContentItem(
        id: json['id'] ?? '',
        category: json['category'] ?? 'Verse',
        title: json['title'] ?? '',
        originalScriptText: json['originalScriptText'] ?? '',
        transliteration: json['transliteration'] ?? '',
        englishMeaning: json['englishMeaning'] ?? '',
        englishExplanation: json['englishExplanation'] ?? '',
        source: json['source'] ?? 'Traditional',
        difficulty: json['difficulty'] ?? 'Easy',
        cognitivePurpose: json['cognitivePurpose'] ?? 'Memory Practice',
        chunks: List<String>.from(json['chunks'] ?? []),
        audioAssetUri: json['audioAssetUri'],
        languageCode: json['languageCode'] ?? 'en',
      );
}
