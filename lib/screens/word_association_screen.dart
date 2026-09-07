import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_overlay.dart';

class WordPairRound {
  final String category;
  final List<Map<String, dynamic>> pairs;

  const WordPairRound({
    required this.category,
    required this.pairs,
  });
}

const List<WordPairRound> kWordRounds = [
  WordPairRound(
    category: 'Everyday Household Associations',
    pairs: [
      {
        'word': 'RAIN (वर्षा)',
        'icon': Icons.water_drop_rounded,
        'options': ['UMBRELLA (छाता)', 'SAND (रेत)', 'SHOE (जूता)', 'CLOCK (घड़ी)'],
        'correctIdx': 0,
        'explanation': 'Rain calls for an umbrella for protection and comfort.',
      },
      {
        'word': 'TEA (चाय)',
        'icon': Icons.coffee_rounded,
        'options': ['BICYCLE (साइकिल)', 'CUP (प्याला)', 'HAMMER (हथौड़ा)', 'SHIRT (कमीज़)'],
        'correctIdx': 1,
        'explanation': 'Tea is served warmly in a cup or kulhad.',
      },
      {
        'word': 'DOCTOR (चिकित्सक)',
        'icon': Icons.local_hospital_rounded,
        'options': ['GUITAR (गिटार)', 'PENCIL (पेंसिल)', 'MEDICINE (दवा)', 'PLANT (पौधा)'],
        'correctIdx': 2,
        'explanation': 'A doctor prescribes medicine for healing.',
      },
      {
        'word': 'LAMP (दीपक)',
        'icon': Icons.lightbulb_outline_rounded,
        'options': ['LIGHT (प्रकाश)', 'WHEEL (पहिया)', 'RICE (चावल)', 'BRUSH (ब्रश)'],
        'correctIdx': 0,
        'explanation': 'A lamp brings illuminating light into the home.',
      },
    ],
  ),
  WordPairRound(
    category: 'Nature & Seasonal Harmony',
    pairs: [
      {
        'word': 'RIVER (नदी)',
        'icon': Icons.waves_rounded,
        'options': ['FLOWER (फूल)', 'BOAT (नाव)', 'STOOL (स्टूल)', 'SCISSORS (कैंची)'],
        'correctIdx': 1,
        'explanation': 'A boat glides across the waters of a river.',
      },
      {
        'word': 'TREE (वृक्ष)',
        'icon': Icons.park_rounded,
        'options': ['SHADE (छाया)', 'CHIMNEY (चिमनी)', 'TRAIN (ट्रेन)', 'SOAP (साबुन)'],
        'correctIdx': 0,
        'explanation': 'A large tree offers cool shade to travelers.',
      },
      {
        'word': 'BIRD (पक्षी)',
        'icon': Icons.flutter_dash_rounded,
        'options': ['CUPBOARD (अलमारी)', 'NEST (घोंसला)', 'LOCK (ताला)', 'MIRROR (दर्पण)'],
        'correctIdx': 1,
        'explanation': 'A bird builds a safe nest high in the branches.',
      },
      {
        'word': 'GARDEN (बगीचा)',
        'icon': Icons.yard_rounded,
        'options': ['FLOWERS (पुष्प)', 'KEYBOARD (कीबोर्ड)', 'HIGHWAY (सड़क)', 'TICKET (टिकट)'],
        'correctIdx': 0,
        'explanation': 'A garden is celebrated for its fragrant flowers.',
      },
    ],
  ),
];

class WordAssociationScreen extends StatefulWidget {
  const WordAssociationScreen({super.key});

  @override
  State<WordAssociationScreen> createState() => _WordAssociationScreenState();
}

class _WordAssociationScreenState extends State<WordAssociationScreen> {
  int _roundIndex = 0;
  final Map<int, int> _userAnswers = {};
  bool _isSubmitted = false;
  double _scorePct = 0.0;
  final Stopwatch _stopwatch = Stopwatch();

  WordPairRound get _currentRound => kWordRounds[_roundIndex];

  @override
  void initState() {
    super.initState();
    _loadRound();
  }

  void _loadRound() {
    _userAnswers.clear();
    _isSubmitted = false;
    _scorePct = 0.0;
    _stopwatch.reset();
    _stopwatch.start();
    setState(() {});
  }

  void _selectOption(int pairIdx, int optionIdx) {
    if (_isSubmitted) return;
    SoundService.playTap();
    setState(() {
      _userAnswers[pairIdx] = optionIdx;
    });
  }

  Future<void> _submit(AppState appState) async {
    _stopwatch.stop();

    int correct = 0;
    for (int i = 0; i < _currentRound.pairs.length; i++) {
      if (_userAnswers[i] == _currentRound.pairs[i]['correctIdx']) {
        correct++;
      }
    }

    final total = _currentRound.pairs.length;
    _scorePct = (correct / total * 100.0);

    setState(() {
      _isSubmitted = true;
    });

    if (_scorePct >= 70.0) {
      SoundService.playFanfare();
      if (mounted) {
        ConfettiOverlay.show(
          context,
          title: 'Semantic Harmony! 🔗',
          subtitle: 'Matched $correct of $total word pairs accurately!',
        );
      }
    } else {
      SoundService.playError();
    }

    // Log attempt into repository
    await appState.attemptRepository.logAttempt(
      ExerciseAttempt(
        id: 'att_word_${DateTime.now().millisecondsSinceEpoch}',
        userId: appState.credentialId,
        domain: ExerciseDomain.universalCognitive,
        cognitiveDomain: CognitiveDomain.semanticMemory,
        type: ExerciseType.wordAssociation,
        exerciseId: 'word_association_round_${_roundIndex + 1}',
        responseMode: 'choice',
        rawScore: correct.toDouble(),
        maxScore: total.toDouble(),
        timeTakenMs: _stopwatch.elapsedMilliseconds,
      ),
    );
  }

  void _nextRoundOrReset() {
    if (_roundIndex < kWordRounds.length - 1) {
      _roundIndex++;
    } else {
      _roundIndex = 0;
    }
    _loadRound();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final fontScale = appState.fontScale;

    return Scaffold(
      backgroundColor: AppColors.canvasIvory,
      appBar: AppBar(
        backgroundColor: AppColors.canvasIvory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoalText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Word Association',
          style: GoogleFonts.newsreader(
            fontSize: 20 * fontScale,
            fontWeight: FontWeight.bold,
            color: AppColors.terracottaPrimary,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.sageSecondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book_rounded, size: 16, color: AppColors.sageSecondary),
                const SizedBox(width: 4),
                Text(
                  'Language & Semantic',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoalText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sandalwoodGold.withOpacity(0.4)),
                  boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ROUND ${_roundIndex + 1} OF ${kWordRounds.length}',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 11 * fontScale,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppColors.terracottaPrimary,
                          ),
                        ),
                        Text(
                          '${_currentRound.pairs.length} Word Pairs',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 12 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentRound.category,
                      style: GoogleFonts.newsreader(
                        fontSize: 18 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoalText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select the word that naturally connects with the given concept.',
                      style: GoogleFonts.atkinsonHyperlegible(fontSize: 12 * fontScale, color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Pairs List
              Column(
                children: List.generate(_currentRound.pairs.length, (pairIdx) {
                  final pair = _currentRound.pairs[pairIdx];
                  final selectedOpt = _userAnswers[pairIdx];
                  final isCorrectAnswer = _isSubmitted && selectedOpt == pair['correctIdx'];
                  final isWrongAnswer = _isSubmitted && selectedOpt != pair['correctIdx'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCorrectAnswer
                            ? AppColors.sageSecondary
                            : isWrongAnswer
                                ? AppColors.terracottaPrimary
                                : Colors.black12,
                        width: (isCorrectAnswer || isWrongAnswer) ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.terracottaPrimary.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(pair['icon'], color: AppColors.terracottaPrimary, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                pair['word'],
                                style: GoogleFonts.newsreader(
                                  fontSize: 18 * fontScale,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.charcoalText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate((pair['options'] as List).length, (optIdx) {
                            final isSelected = selectedOpt == optIdx;
                            return GestureDetector(
                              onTap: () => _selectOption(pairIdx, optIdx),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.terracottaPrimary.withOpacity(0.15)
                                      : AppColors.canvasIvory,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? AppColors.terracottaPrimary : Colors.black12,
                                    width: isSelected ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Text(
                                  pair['options'][optIdx],
                                  style: GoogleFonts.atkinsonHyperlegible(
                                    fontSize: 13 * fontScale,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: AppColors.charcoalText,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        if (_isSubmitted) ...[
                          const SizedBox(height: 8),
                          Text(
                            pair['explanation'],
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 12 * fontScale,
                              fontStyle: FontStyle.italic,
                              color: isCorrectAnswer ? AppColors.sageSecondary : AppColors.terracottaPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ),

              // Bottom Button
              if (!_isSubmitted)
                ElevatedButton.icon(
                  onPressed: _userAnswers.length == _currentRound.pairs.length ? () => _submit(appState) : null,
                  icon: const Icon(Icons.check_circle_outline, size: 22),
                  label: Text(
                    'Check Word Associations',
                    style: GoogleFonts.atkinsonHyperlegible(fontSize: 16 * fontScale, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sageSecondary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.sandalwoodGold),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Score: ${_scorePct.toInt()}%',
                        style: GoogleFonts.newsreader(
                          fontSize: 22 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: AppColors.terracottaPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Language association data recorded in your cognitive profile.',
                        style: GoogleFonts.atkinsonHyperlegible(fontSize: 13 * fontScale, color: AppColors.secondaryText),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: _nextRoundOrReset,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracottaPrimary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _roundIndex < kWordRounds.length - 1 ? 'Next Round ➔' : 'Play Again',
                          style: GoogleFonts.atkinsonHyperlegible(fontSize: 15 * fontScale, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
