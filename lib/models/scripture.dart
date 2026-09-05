class ScriptureCategory {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final int count;

  const ScriptureCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.count,
  });
}

class WordMeaning {
  final String sanskritWord;
  final String transliteration;
  final String englishMeaning;

  const WordMeaning({
    required this.sanskritWord,
    required this.transliteration,
    required this.englishMeaning,
  });
}

class Verse {
  final String id;
  final String suktamId;
  final int verseNumber;
  final String sanskritText;
  final String transliteration;
  final String englishMeaning;
  final List<WordMeaning> wordBreakdown;
  final String commentary;
  final String? audioAsset;

  const Verse({
    required this.id,
    required this.suktamId,
    required this.verseNumber,
    required this.sanskritText,
    required this.transliteration,
    required this.englishMeaning,
    this.wordBreakdown = const [],
    this.commentary = '',
    this.audioAsset,
  });
}

class Suktam {
  final String id;
  final String categoryId;
  final String titleSanskrit;
  final String titleTransliteration;
  final String titleEnglish;
  final String deity;
  final String rishi;
  final String meter;
  final String summary;
  final List<Verse> verses;
  final bool isFeatured;

  const Suktam({
    required this.id,
    required this.categoryId,
    required this.titleSanskrit,
    required this.titleTransliteration,
    required this.titleEnglish,
    required this.deity,
    required this.rishi,
    required this.meter,
    required this.summary,
    required this.verses,
    this.isFeatured = false,
  });
}

class Flashcard {
  final String id;
  final String verseId;
  final String suktamTitle;
  final String sanskritText;
  final String transliteration;
  final String englishMeaning;
  final List<String> quizOptions;
  final int correctOptionIndex;
  final String missingWordHint;

  const Flashcard({
    required this.id,
    required this.verseId,
    required this.suktamTitle,
    required this.sanskritText,
    required this.transliteration,
    required this.englishMeaning,
    required this.quizOptions,
    required this.correctOptionIndex,
    required this.missingWordHint,
  });
}
