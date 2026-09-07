import 'dart:math';

class MotivationalQuote {
  final String text;
  final String author;
  final String category; // 'memory', 'daily_effort', 'peace', 'encouragement'

  const MotivationalQuote({
    required this.text,
    required this.author,
    this.category = 'encouragement',
  });
}

class MotivationalQuoteService {
  static const List<MotivationalQuote> _quotes = [
    MotivationalQuote(
      text: 'Every memory is precious. Small steps taken every day nurture lasting clarity.',
      author: 'Smriti Veda Wisdom',
      category: 'memory',
    ),
    MotivationalQuote(
      text: 'Take your time. Steady practice strengthens the mind like water shapes the stone.',
      author: 'Traditional Proverb',
      category: 'daily_effort',
    ),
    MotivationalQuote(
      text: 'Your effort today is a gift of awareness to your future self.',
      author: 'Cognitive Wellness Principle',
      category: 'encouragement',
    ),
    MotivationalQuote(
      text: 'A calm breath and a focused mind can remember mountains.',
      author: 'Ayurvedic Saying',
      category: 'peace',
    ),
    MotivationalQuote(
      text: 'Patience with yourself is the highest form of cognitive care.',
      author: 'Elder Care Guidance',
      category: 'encouragement',
    ),
    MotivationalQuote(
      text: 'Like rhythmic music, consistent recall keeps the mind in sweet harmony.',
      author: 'Smriti Veda',
      category: 'memory',
    ),
    MotivationalQuote(
      text: 'Celebrate each small victory. Every exercise is a milestone in wellness.',
      author: 'Caregiver Circle',
      category: 'daily_effort',
    ),
  ];

  static MotivationalQuote getQuoteOfTheDay() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return _quotes[dayOfYear % _quotes.length];
  }

  static MotivationalQuote getRandomCelebrationQuote() {
    final rng = Random();
    return _quotes[rng.nextInt(_quotes.length)];
  }

  static List<MotivationalQuote> getAllQuotes() => List.unmodifiable(_quotes);
}
