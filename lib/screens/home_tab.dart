import '../locales/app_localizations.dart';
import '../widgets/languages_section.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/everyday_memory.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/db_service.dart';
import '../services/motivational_quote_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'everyday_memory_screen.dart';
import 'main_screen.dart';
import 'medical_reports_screen.dart';
import 'personalized_questionnaire_screen.dart';
import 'sequence_recall_screen.dart';
import 'attention_exercise_screen.dart';
import 'daily_routine_recall_screen.dart';
import 'fruit_memory_path_screen.dart';
import 'memory_melody_screen.dart';
import 'object_memory_screen.dart';
import 'pattern_memory_screen.dart';
import 'story_memory_screen.dart';
import 'word_association_screen.dart';
import '../services/personalization_engine.dart';


class HomeTab extends StatefulWidget {
  final Function(int) onNavigateTab;
  const HomeTab({super.key, required this.onNavigateTab});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _audioPlaying = false;
  MotivationalQuote _currentQuote = MotivationalQuoteService.getRandomQuote();

  String _greeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return context.tr('greeting_morning');
    if (hour < 17) return context.tr('greeting_afternoon');
    return context.tr('greeting_evening');
  }

  String _formattedDate() {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final fontScale = appState.fontScale;
    final repo = appState.attemptRepository;

    // Compute real cognitive domain performance profile
    final recentAttempts = repo.getRecentAttempts(limit: 100);
    final totalAttempts = recentAttempts.length;
    final domainScores = PersonalizationEngine.computeDomainScores(recentAttempts);
    final recommendation = PersonalizationEngine.getRecommendation(recentAttempts);

    final spatialScore = domainScores[CognitiveDomain.spatialMemory]?.averagePercentage ?? 0.0;
    final visualScore = domainScores[CognitiveDomain.visualMemory]?.averagePercentage ?? 0.0;
    final attentionScore = domainScores[CognitiveDomain.attentionFocus]?.averagePercentage ?? 0.0;
    final sequenceScore = domainScores[CognitiveDomain.sequentialMemory]?.averagePercentage ?? 0.0;
    final auditoryScore = domainScores[CognitiveDomain.auditoryRecall]?.averagePercentage ?? 0.0;

    final memPct = (visualScore > 0 ? visualScore / 100 : (spatialScore > 0 ? spatialScore / 100 : 0.75)).clamp(0.0, 1.0);
    final practPct = (auditoryScore > 0 ? auditoryScore / 100 : 0.70).clamp(0.0, 1.0);
    final seqPct = (sequenceScore > 0 ? sequenceScore / 100 : 0.65).clamp(0.0, 1.0);
    final attPct = (attentionScore > 0 ? attentionScore / 100 : 0.80).clamp(0.0, 1.0);

    final userName = appState.userName.isNotEmpty ? appState.userName : 'Friend';
    final streakDays = appState.dailyStreak;
    final userAppointments = DbService().getAppointments();
    final userReminders = appState.todayReminders.isNotEmpty ? appState.todayReminders : appState.reminders;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SmritiAppBar(
              screenLabel: 'Home',
              onVolumePressed: () {
                setState(() => _audioPlaying = !_audioPlaying);
              },
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── 1. Greeting + Audio Prompter ─────────────────────
                _SurfaceCard(
                  color: AppColors.surfaceCream,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                 Row(
                                   children: [
                                     Container(width: 10, height: 10,
                                         decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.secondary)),
                                     const SizedBox(width: 6),
                                     Expanded(
                                       child: Text(
                                         _formattedDate().toUpperCase(),
                                         maxLines: 1,
                                         overflow: TextOverflow.ellipsis,
                                         style: GoogleFonts.atkinsonHyperlegible(
                                           fontSize: 11 * fontScale,
                                           fontWeight: FontWeight.w700,
                                           letterSpacing: 1.2,
                                           color: AppColors.secondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 6),
                                Text('${_greeting(context)}, $userName',
                                  style: GoogleFonts.newsreader(
                                      fontSize: 28 * fontScale, fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary, height: 1.15)),
                                const SizedBox(height: 4),
                                Text(context.tr('ready_practice'),
                                  style: GoogleFonts.atkinsonHyperlegible(
                                      fontSize: 16 * fontScale, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: AppColors.terracottaSoft, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.psychology, color: AppColors.primary, size: 28),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Audio prompt button
                      GestureDetector(
                        onTap: () {
                          setState(() => _audioPlaying = !_audioPlaying);
                          if (_audioPlaying) {
                            SoundService.speak(
                              'Good day ${appState.userName}. Today is ${_formattedDate()}. Your personalized cognitive focus is Auditory Recitation and Memory Retention. Let us begin today\'s practice!',
                              languageCode: appState.selectedLanguage,
                            );
                          } else {
                            SoundService.stop();
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: _audioPlaying ? AppColors.terracottaSoft : AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _audioPlaying ? Icons.pause_circle : Icons.volume_up,
                                color: AppColors.primary, size: 26,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _audioPlaying ? 'Playing: Today is ${_formattedDate()}...' : 'Tap to listen to daily plan',
                                  style: GoogleFonts.atkinsonHyperlegible(
                                      fontSize: 15 * fontScale, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: AppColors.terracottaSoft, borderRadius: BorderRadius.circular(12)),
                                child: Text('15 sec', style: GoogleFonts.atkinsonHyperlegible(
                                    fontSize: 12 * fontScale, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── 1.2. Daily Motivational Reflection (Dynamic & Localized) ──
                InkWell(
                  onTap: () {
                    SoundService.playTap();
                    setState(() {
                      _currentQuote = MotivationalQuoteService.getRandomQuote();
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.canvasIvory,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.format_quote_rounded, color: AppColors.secondary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '"${_currentQuote.localizedText(appState.selectedLanguage)}"',
                                style: GoogleFonts.newsreader(
                                  fontSize: 14 * fontScale,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textPrimary,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '— ${_currentQuote.localizedAuthor(appState.selectedLanguage)}',
                                      style: GoogleFonts.atkinsonHyperlegible(
                                        fontSize: 11 * fontScale,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.refresh_rounded, size: 14, color: AppColors.secondaryText),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── 1.5. AI Personalized Cognitive Plan & Medical Hub Quick Cards ──
                _SurfaceCard(
                  color: AppColors.cardWhite,
                  elevated: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome, color: AppColors.terracottaPrimary, size: 20),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    "AI PERSONAL COGNITIVE REGIMEN",
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.atkinsonHyperlegible(
                                      fontSize: 11 * fontScale,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.9,
                                      color: AppColors.terracottaPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.sageSecondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "SMRITIVEDA AI ACTIVE",
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 10 * fontScale,
                                fontWeight: FontWeight.bold,
                                color: AppColors.sageSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        appState.aiPersonalPlanText ??
                            '''🧠 PERSONALIZED COGNITIVE FOCUS
• Target: Auditory Recitation & Memory Retention for ${appState.userName}.
• Heritage Language: ${appState.selectedLanguage.toUpperCase()} Traditional Oral Memory.
• Family Anchors: Daily recall of relatives, grandchildren & hometown memories.''',
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 14 * fontScale,
                          color: AppColors.charcoalText,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PersonalizedQuestionnaireScreen(isInitialSetup: false),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit_note_rounded, size: 18),
                              label: const Text('Edit AI Plan'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.terracottaPrimary,
                                side: BorderSide(color: AppColors.terracottaPrimary.withValues(alpha: 0.4)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MedicalReportsScreen()),
                                );
                              },
                              icon: const Icon(Icons.folder_shared_rounded, size: 18),
                              label: const Text('Medical Reports'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.sageSecondary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
            const LanguagesSection(),

                // ── 2. Adaptive Personalized Recommendation Card (SIH Flagship Loop) ──
                _SurfaceCard(
                  color: AppColors.cardWhite,
                  elevated: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: recommendation.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(recommendation.icon, size: 14, color: recommendation.color),
                                const SizedBox(width: 4),
                                Text(
                                  "RECOMMENDED • ${recommendation.targetDomain.displayName.toUpperCase()}",
                                  style: GoogleFonts.atkinsonHyperlegible(
                                    fontSize: 10 * fontScale,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: recommendation.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.sageSecondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              recommendation.difficultyLabel,
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 11 * fontScale,
                                fontWeight: FontWeight.bold,
                                color: AppColors.sageSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        recommendation.exerciseTitle,
                        style: GoogleFonts.newsreader(
                          fontSize: 22 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoalText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recommendation.exerciseSubtitle,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 14 * fontScale,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: recommendation.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: recommendation.color.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.insights_rounded, size: 18, color: recommendation.color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                recommendation.reason,
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 12 * fontScale,
                                  color: AppColors.charcoalText,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: () {
                          switch (recommendation.exerciseType) {
                            case ExerciseType.memoryMelody:
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoryMelodyScreen()));
                              break;
                            case ExerciseType.fruitMemoryPath:
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const FruitMemoryPathScreen()));
                              break;
                            case ExerciseType.attention:
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const AttentionExerciseScreen()));
                              break;
                            case ExerciseType.recognition:
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ObjectMemoryScreen()));
                              break;
                            case ExerciseType.patternRecall:
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const PatternMemoryScreen()));
                              break;
                            case ExerciseType.sequenceRecall:
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const SequenceRecallScreen()));
                              break;
                            case ExerciseType.storyMemory:
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const StoryMemoryScreen()));
                              break;
                            case ExerciseType.wordAssociation:
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const WordAssociationScreen()));
                              break;
                            case ExerciseType.dailyRoutineRecall:
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyRoutineRecallScreen()));
                              break;
                            default:
                              widget.onNavigateTab(1);
                              break;
                          }
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 24),
                        label: Text(
                          "Start ${recommendation.exerciseTitle}",
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 15 * fontScale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: recommendation.color,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // ── 2. Today's Practice Hero ──────────────────────────
                _SurfaceCard(
                  color: AppColors.cardWhite,
                  elevated: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: AppColors.terracottaSoft, borderRadius: BorderRadius.circular(20)),
                            child: Text("TODAY'S PRACTICE",
                              style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 11 * fontScale, fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8, color: AppColors.primary)),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule, size: 16, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text('5 min', style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 13 * fontScale, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Structured Oral Recitation & Memory',
                        style: GoogleFonts.newsreader(
                            fontSize: 22 * fontScale, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Text('Structured recall inspired by Indian oral memory traditions (Pada chunking & Krama overlapping). Practice with regional poems, songs, family stories, and familiar proverbs.',
                        style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 15 * fontScale, color: AppColors.textSecondary, height: 1.5)),
                      const SizedBox(height: 12),
                      // Practice imagery
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: double.infinity, height: 130,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF8E6842), Color(0xFF73502C)],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(child: Icon(Icons.record_voice_over_rounded, size: 60, color: Colors.white.withValues(alpha: 0.15))),
                              Positioned(
                                bottom: 10, left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Text('Multi-Cultural • Telugu, Hindi, Tamil & English',
                                    style: GoogleFonts.atkinsonHyperlegible(
                                        fontSize: 12 * fontScale, color: Colors.white, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () {
                          widget.onNavigateTab(1); // Go to Practice tab
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Continue Practice',
                              style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 16 * fontScale, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── 3. Secondary Exercise Card ────────────────────────
                _SurfaceCard(
                  color: AppColors.cardWhite,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                                color: AppColors.sageSoft, borderRadius: BorderRadius.circular(20)),
                            child: Text('MEMORY EXERCISE',
                              style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 11 * fontScale, fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8, color: AppColors.secondary)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: AppColors.surfaceCream, borderRadius: BorderRadius.circular(6)),
                            child: Text('Gentle Pace',
                              style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 12 * fontScale, color: AppColors.secondary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(color: AppColors.sageSoft, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.grid_view_rounded, color: AppColors.secondary, size: 32),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Sequence Recall',
                                  style: GoogleFonts.atkinsonHyperlegible(
                                      fontSize: 18 * fontScale, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                Text('Follow light patterns at an unhurried rhythm • 5 min',
                                  style: GoogleFonts.atkinsonHyperlegible(
                                      fontSize: 13 * fontScale, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SequenceRecallScreen())),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                              color: AppColors.cardWhite, borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.outlineVariant),
                              boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4)]),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Start Exercise',
                                style: GoogleFonts.atkinsonHyperlegible(
                                    fontSize: 16 * fontScale, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── 4. Daily Memory Anchors (Reminders & Appointments) ───────────────
                _SurfaceCard(
                  color: AppColors.surfaceCream,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.anchor, color: AppColors.primary, size: 22),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text('Daily Memory Anchors',
                                    style: GoogleFonts.newsreader(
                                        fontSize: 20 * fontScale, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Today', style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 12 * fontScale, color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (userAppointments.isEmpty && userReminders.isEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 30),
                              const SizedBox(height: 8),
                              Text(
                                'No appointments or reminders scheduled yet.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 14 * fontScale,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EverydayMemoryScreen()));
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Your First Reminder'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        ...userAppointments.take(2).map((appt) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _AnchorItem(
                            icon: Icons.medical_services,
                            iconBg: AppColors.terracottaSoft,
                            iconColor: AppColors.primary,
                            title: appt.title,
                            subtitle: '${appt.doctorName} • ${appt.location}',
                            timeLabel: appt.time.format(context),
                            tag: 'Appointment',
                            tagColor: AppColors.surfaceCream,
                            tagTextColor: AppColors.textSecondary,
                            fontScale: fontScale,
                          ),
                        )),
                        ...userReminders.take(2).map((rem) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _AnchorItem(
                            icon: rem.category == ReminderCategory.health ? Icons.medical_information : Icons.notifications_active_outlined,
                            iconBg: AppColors.sageSoft,
                            iconColor: AppColors.secondary,
                            title: rem.title,
                            subtitle: rem.description,
                            timeLabel: rem.time.format(context),
                            tag: rem.isCompleted ? 'Completed' : 'Scheduled',
                            tagColor: rem.isCompleted ? AppColors.sageSoft : AppColors.surfaceCream,
                            tagTextColor: rem.isCompleted ? AppColors.secondary : AppColors.textSecondary,
                            fontScale: fontScale,
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── 5. This Week's Recall ─────────────────────────────
                _SurfaceCard(
                  color: AppColors.cardWhite,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("This Week's Recall",
                                style: GoogleFonts.newsreader(
                                    fontSize: 20 * fontScale, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              Text('Gentle tracking for peace of mind',
                                style: GoogleFonts.atkinsonHyperlegible(
                                    fontSize: 12 * fontScale, color: AppColors.textSecondary)),
                            ],
                          ),
                          Container(
                            width: 40, height: 40,
                            decoration: const BoxDecoration(color: AppColors.sageSoft, shape: BoxShape.circle),
                            child: const Icon(Icons.trending_up, color: AppColors.secondary, size: 22),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (totalAttempts == 0) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCream,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.insights, color: AppColors.primary, size: 36),
                              const SizedBox(height: 10),
                              Text(
                                'No activities completed yet.',
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 16 * fontScale,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Complete your first memory activity to start building your progress.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 14 * fontScale,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        _MetricBar(label: 'Memory Recall', value: memPct, valueColor: AppColors.primary, fontScale: fontScale),
                        const SizedBox(height: 10),
                        _MetricBar(label: 'Traditional Practice', value: practPct, valueColor: AppColors.secondary, fontScale: fontScale),
                        const SizedBox(height: 10),
                        _MetricBar(label: 'Sequence Retention', value: seqPct, valueColor: AppColors.tertiary, fontScale: fontScale),
                        const SizedBox(height: 10),
                        _MetricBar(label: 'Attention & Focus', value: attPct, valueColor: AppColors.secondaryFixedDim, fontScale: fontScale),
                        const SizedBox(height: 14),
                        // Encouragement
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.sageSoft, borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              const Icon(Icons.eco, color: AppColors.secondary, size: 26),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      streakDays > 1 ? 'Wonderful consistency!' : 'Practice recorded!',
                                      style: GoogleFonts.atkinsonHyperlegible(
                                          fontSize: 15 * fontScale, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                                    Text(
                                      streakDays > 0
                                          ? 'You have completed $streakDays consecutive days of practice.'
                                          : 'You have completed $totalAttempts activity session(s).',
                                      style: GoogleFonts.atkinsonHyperlegible(
                                          fontSize: 13 * fontScale, color: AppColors.textPrimary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── 6. Footer note ──────────────────────────────────────
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.help_outline, size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text('Take your time. No rush, no timers.',
                          style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 13 * fontScale, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final bool elevated;

  const _SurfaceCard({required this.child, required this.color, this.elevated = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A2D241C),
            blurRadius: elevated ? 8 : 4,
            offset: Offset(0, elevated ? 2 : 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetricBar extends StatelessWidget {
  final String label;
  final double value; // 0.0–1.0
  final Color valueColor;
  final double fontScale;

  const _MetricBar({required this.label, required this.value, required this.valueColor, required this.fontScale});

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 14 * fontScale, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            Text('$pct%', style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 16 * fontScale, fontWeight: FontWeight.w700, color: valueColor)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.surfaceContainer,
            valueColor: AlwaysStoppedAnimation<Color>(valueColor),
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}

class _AnchorItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle, timeLabel, tag;
  final Color tagColor, tagTextColor;
  final double fontScale;

  const _AnchorItem({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.title, required this.subtitle, required this.timeLabel,
    required this.tag, required this.tagColor, required this.tagTextColor,
    required this.fontScale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.cardWhite, borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4)]),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 15 * fontScale, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(subtitle, style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(timeLabel, style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 16 * fontScale, fontWeight: FontWeight.w600, color: AppColors.primary)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(6)),
                child: Text(tag, style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 11 * fontScale, color: tagTextColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
