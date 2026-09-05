import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/sample_data.dart';
import '../models/scripture.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class SmritiTrainerTab extends StatefulWidget {
  const SmritiTrainerTab({super.key});

  @override
  State<SmritiTrainerTab> createState() => _SmritiTrainerTabState();
}

class _SmritiTrainerTabState extends State<SmritiTrainerTab> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _showAnswer = false;
  int? _selectedQuizOption;
  bool? _isCorrect;

  late AnimationController _flipController;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_showAnswer) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _showAnswer = !_showAnswer;
    });
  }

  void _nextCard() {
    setState(() {
      _showAnswer = false;
      _selectedQuizOption = null;
      _isCorrect = null;
      _currentIndex = (_currentIndex + 1) % SampleData.flashcards.length;
    });
    _flipController.reset();
  }

  void _submitQuiz(int selectedIndex, Flashcard card, AppState appState) {
    setState(() {
      _selectedQuizOption = selectedIndex;
      _isCorrect = (selectedIndex == card.correctOptionIndex);
    });
    if (_isCorrect == true) {
      appState.incrementMastery();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = SampleData.flashcards[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Smriti Trainer (स्मृति अभ्यास)',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Progress Indicator Banner
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Card ${_currentIndex + 1} of ${SampleData.flashcards.length}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGold,
                  ),
                ),
                Text(
                  'Mastered: ${appState.versesMastered} Shlokas',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primarySaffron,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Animated 3D Flip Flashcard
            GestureDetector(
              onTap: _flipCard,
              child: AnimatedBuilder(
                animation: _flipController,
                builder: (context, child) {
                  final angle = _flipController.value * pi;
                  final isUnder = (angle >= pi / 2);
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    alignment: Alignment.center,
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 220),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryGold.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGold.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: isUnder
                          ? Transform(
                              transform: Matrix4.identity()..rotateY(pi),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'English Translation & Meaning',
                                    style: GoogleFonts.cinzel(
                                      fontSize: 14,
                                      color: AppColors.primarySaffron,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    card.englishMeaning,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      color: isDark ? Colors.white : AppColors.textLightPrimary,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tap to flip back to verse',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  card.suktamTitle,
                                  style: GoogleFonts.cinzel(
                                    fontSize: 16,
                                    color: AppColors.primaryGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  card.sanskritText,
                                  style: AppTheme.devanagariStyle(
                                    fontSize: 20,
                                    color: isDark ? Colors.white : AppColors.textLightPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.flip, size: 16, color: AppColors.primarySaffron),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Tap card to reveal full meaning',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: AppColors.primarySaffron,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Interactive Verse Recall Quiz
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.quiz, color: AppColors.primaryGold),
                      const SizedBox(width: 8),
                      Text(
                        'VERSE RECALL QUIZ',
                        style: GoogleFonts.cinzel(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete the missing word in the verse above:',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hint: ${card.missingWordHint}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.primarySaffron,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ...List.generate(card.quizOptions.length, (optIndex) {
                    final optionText = card.quizOptions[optIndex];
                    final isSelected = _selectedQuizOption == optIndex;
                    final isCorrectOpt = optIndex == card.correctOptionIndex;

                    Color btnColor = isDark ? AppColors.darkSurfaceCard : Colors.white;
                    Color textColor = isDark ? Colors.white : Colors.black87;

                    if (_selectedQuizOption != null) {
                      if (isCorrectOpt) {
                        btnColor = Colors.green.shade800;
                        textColor = Colors.white;
                      } else if (isSelected && !isCorrectOpt) {
                        btnColor = Colors.red.shade800;
                        textColor = Colors.white;
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: _selectedQuizOption == null
                            ? () => _submitQuiz(optIndex, card, appState)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: btnColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryGold
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.primaryGold.withValues(alpha: 0.2),
                                child: Text(
                                  String.fromCharCode(65 + optIndex),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  optionText,
                                  style: AppTheme.devanagariStyle(
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              if (_selectedQuizOption != null && isCorrectOpt)
                                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                              if (_selectedQuizOption != null && isSelected && !isCorrectOpt)
                                const Icon(Icons.cancel, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Next Card Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _nextCard,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next Flashcard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primarySaffron,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
