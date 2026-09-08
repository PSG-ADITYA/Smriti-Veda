enum GameDifficulty {
  easy,
  medium,
  hard;

  String get label {
    switch (this) {
      case GameDifficulty.easy:
        return 'Easy';
      case GameDifficulty.medium:
        return 'Medium';
      case GameDifficulty.hard:
        return 'Hard';
    }
  }

  String get description {
    switch (this) {
      case GameDifficulty.easy:
        return 'Gentle pacing with fewer items, ideal for comfortable daily practice.';
      case GameDifficulty.medium:
        return 'Balanced challenge with moderate items and realistic timing.';
      case GameDifficulty.hard:
        return 'Expanded items and faster sequences for focused retention.';
    }
  }
}
