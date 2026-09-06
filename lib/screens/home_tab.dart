import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/everyday_memory.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/db_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'everyday_memory_screen.dart';
import 'main_screen.dart';
import 'medical_reports_screen.dart';
import 'personalized_questionnaire_screen.dart';
import 'sequence_recall_screen.dart';

class HomeTab extends StatefulWidget {
  final Function(int) onNavigateTab;
  const HomeTab({super.key, required this.onNavigateTab});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _audioPlaying = false;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
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

    // Compute real stats from exercise attempt log
    final recentAttempts = repo.getRecentAttempts(limit: 50);
    final totalAttempts = recentAttempts.length;
    double memoryScore = 0, practiceScore = 0, sequenceScore = 0, attentionScore = 0;
    int memCount = 0, practCount = 0, seqCount = 0, attCount = 0;
    for (final a in recentAttempts) {
      final pct = a.maxScore > 0 ? (a.rawScore / a.maxScore * 100) : 0.0;
      if (a.domain == ExerciseDomain.universalCognitive) {
        memoryScore += pct; memCount++;
      } else if (a.domain == ExerciseDomain.culturalOral) {
        practiceScore += pct; practCount++;
      } else {
        sequenceScore += pct; seqCount++;
      }
    }
    final memPct = memCount > 0 ? (memoryScore / memCount / 100).clamp(0.0, 1.0) : 0.0;
    final practPct = practCount > 0 ? (practiceScore / practCount / 100).clamp(0.0, 1.0) : 0.0;
    final seqPct = seqCount > 0 ? (sequenceScore / seqCount / 100).clamp(0.0, 1.0) : 0.0;
    final attPct = attCount > 0 ? (attentionScore / attCount / 100).clamp(0.0, 1.0) : 0.0;

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
                                    Text(_formattedDate().toUpperCase(),
                                      style: GoogleFonts.atkinsonHyperlegible(
                                          fontSize: 11 * fontScale, fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2, color: AppColors.secondary)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('${_greeting()}, $userName',
                                  style: GoogleFonts.newsreader(
                                      fontSize: 28 * fontScale, fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary, height: 1.15)),
                                const SizedBox(height: 4),
                                Text('Ready for today\'s practice?',
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
                const SizedBox(height: 16),

                // ── 1.5. AI Personalized Cognitive Plan & Medical Hub Quick Cards ──
                _SurfaceCard(
                  color: AppColors.cardWhite,
                  elevated: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: AppColors.terracottaPrimary, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                "AI PERSONAL COGNITIVE REGIMEN",
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 11 * fontScale,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.9,
                                  color: AppColors.terracottaPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.sageSecondary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "GEMINI AI ACTIVE",
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
                                side: BorderSide(color: AppColors.terracottaPrimary.withOpacity(0.4)),
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

                // ── 2. Today's Practice Hero ──────────────────────────
                _SurfaceCard(
                  color: AppColors.cardWhite,
                  elevated: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          Row(
                            children: [
                              const Icon(Icons.anchor, color: AppColors.primary, size: 22),
                              const SizedBox(width: 8),
                              Text('Daily Memory Anchors',
                                style: GoogleFonts.newsreader(
                                    fontSize: 20 * fontScale, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            ],
                          ),
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
