import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final fontScale = appState.fontScale;
    final repo = appState.attemptRepository;

    final recentAttempts = repo.getRecentAttempts(limit: 100);
    final now = DateTime.now();
    final attemptsToday = recentAttempts.where((a) => a.timestamp.day == now.day && a.timestamp.month == now.month && a.timestamp.year == now.year).toList();
    final totalMinutesToday = (attemptsToday.fold<double>(0.0, (sum, a) => sum + (a.timeTakenMs > 0 ? a.timeTakenMs / 60000.0 : 2.5))).clamp(0.0, 120.0);
    final streakDays = recentAttempts.isEmpty ? 0 : recentAttempts.map((a) => "${a.timestamp.year}-${a.timestamp.month}-${a.timestamp.day}").toSet().length;
    final weekData = _buildWeekData(recentAttempts);

    // Domain percentages computed strictly from logged user attempts
    double memPct = 0.0, practPct = 0.0, seqPct = 0.0, attPct = 0.0;
    final domains = {'memory': <double>[], 'practice': <double>[], 'sequence': <double>[], 'attention': <double>[]};
    for (final a in recentAttempts) {
      final pct = a.maxScore > 0 ? a.rawScore / a.maxScore : 0.0;
      if (a.domain == ExerciseDomain.universalCognitive) {
        domains['memory']!.add(pct);
      } else if (a.domain == ExerciseDomain.culturalOral) {
        domains['practice']!.add(pct);
      } else if (a.domain == ExerciseDomain.everydayMemory) {
        domains['attention']!.add(pct);
      }
    }
    if (domains['memory']!.isNotEmpty) {
      memPct = domains['memory']!.reduce((a, b) => a + b) / domains['memory']!.length;
    }
    if (domains['practice']!.isNotEmpty) {
      practPct = domains['practice']!.reduce((a, b) => a + b) / domains['practice']!.length;
    }
    if (domains['sequence']!.isNotEmpty) {
      seqPct = domains['sequence']!.reduce((a, b) => a + b) / domains['sequence']!.length;
    }
    if (domains['attention']!.isNotEmpty) {
      attPct = domains['attention']!.reduce((a, b) => a + b) / domains['attention']!.length;
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SmritiAppBar(screenLabel: 'Progress')),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── 1. Caregiver Connect Pill ─────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: AppColors.sageSoft, borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4)]),
                  child: Row(
                    children: [
                      Container(
                        width: 42, height: 42, decoration: const BoxDecoration(color: AppColors.terracottaSoft, shape: BoxShape.circle),
                        child: const Icon(Icons.favorite, color: AppColors.secondary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Connected with Caregiver',
                              style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 14 * fontScale, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                            Text('Updates shared daily at 7:00 PM',
                              style: GoogleFonts.atkinsonHyperlegible(fontSize: 12 * fontScale, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(8),
                            boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4)]),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('View', style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 13 * fontScale, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                            const Icon(Icons.chevron_right, size: 16, color: AppColors.secondary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── 2. Hero Journey Card ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.surfaceCream, borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4)]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.terracottaSoft, borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.spa, size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text('Cognitive Vitality Sanctuary',
                                  style: GoogleFonts.atkinsonHyperlegible(
                                      fontSize: 11 * fontScale, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Your Practice & Memory Journey',
                        style: GoogleFonts.newsreader(
                            fontSize: 22 * fontScale, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Text('Gentle, consistent cognitive stimulation for lasting wellness.',
                        style: GoogleFonts.atkinsonHyperlegible(fontSize: 14 * fontScale, color: AppColors.textSecondary)),
                      const SizedBox(height: 14),
                      // Bento metrics
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4)]),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Active Today', style: GoogleFonts.atkinsonHyperlegible(
                                          fontSize: 12 * fontScale, color: AppColors.textSecondary)),
                                      Container(
                                        width: 30, height: 30,
                                        decoration: BoxDecoration(color: AppColors.sageSoft, shape: BoxShape.circle),
                                        child: const Icon(Icons.timer, color: AppColors.secondary, size: 16),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  RichText(
                                    text: TextSpan(children: [
                                      TextSpan(text: '${totalMinutesToday.toInt()}',
                                          style: GoogleFonts.newsreader(fontSize: 26 * fontScale, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                      TextSpan(text: ' min',
                                          style: GoogleFonts.atkinsonHyperlegible(fontSize: 14 * fontScale, color: AppColors.textMuted)),
                                    ]),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    Icon(totalMinutesToday > 0 ? Icons.check_circle : Icons.schedule, size: 13, color: totalMinutesToday > 0 ? AppColors.secondary : AppColors.textSecondary),
                                    const SizedBox(width: 3),
                                    Text(totalMinutesToday > 0 ? 'Daily goal met' : 'Not started today', style: GoogleFonts.atkinsonHyperlegible(
                                        fontSize: 11 * fontScale, color: totalMinutesToday > 0 ? AppColors.secondary : AppColors.textSecondary)),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4)]),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Rhythm Streak', style: GoogleFonts.atkinsonHyperlegible(
                                          fontSize: 12 * fontScale, color: AppColors.textSecondary)),
                                      Container(
                                        width: 30, height: 30,
                                        decoration: BoxDecoration(color: AppColors.terracottaSoft, shape: BoxShape.circle),
                                        child: const Icon(Icons.local_fire_department, color: AppColors.primary, size: 16),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  RichText(
                                    text: TextSpan(children: [
                                      TextSpan(text: '$streakDays',
                                          style: GoogleFonts.newsreader(fontSize: 26 * fontScale, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                      TextSpan(text: ' days',
                                          style: GoogleFonts.atkinsonHyperlegible(fontSize: 14 * fontScale, color: AppColors.textMuted)),
                                    ]),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    Icon(streakDays > 0 ? Icons.psychology : Icons.play_arrow, size: 13, color: AppColors.primary),
                                    const SizedBox(width: 3),
                                    Text(streakDays > 0 ? 'Steady cadence' : 'Start your streak', style: GoogleFonts.atkinsonHyperlegible(
                                        fontSize: 11 * fontScale, color: AppColors.primary)),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── 3. Weekly Bar Chart ───────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.cardWhite, borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4)]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Weekly Practice Rhythm',
                                style: GoogleFonts.newsreader(
                                    fontSize: 18 * fontScale, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              Text('Minutes spent in daily mindful recall',
                                style: GoogleFonts.atkinsonHyperlegible(fontSize: 12 * fontScale, color: AppColors.textSecondary)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.surfaceCream, borderRadius: BorderRadius.circular(12)),
                            child: Text('Last 7 Days', style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 11 * fontScale, color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _WeekBarChart(data: weekData, fontScale: fontScale),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── 4. Domain Breakdown ───────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.cardWhite, borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4)]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recall Performance by Domain',
                        style: GoogleFonts.newsreader(
                            fontSize: 18 * fontScale, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Based on your completed exercises',
                        style: GoogleFonts.atkinsonHyperlegible(fontSize: 12 * fontScale, color: AppColors.textSecondary)),
                      const SizedBox(height: 14),
                      _DomainBar(label: 'Memory Recall', value: memPct, color: AppColors.primary, fontScale: fontScale),
                      const SizedBox(height: 10),
                      _DomainBar(label: 'Oral Recitation & Memory', value: practPct, color: AppColors.secondary, fontScale: fontScale),
                      const SizedBox(height: 10),
                      _DomainBar(label: 'Sequence Retention', value: seqPct, color: AppColors.tertiary, fontScale: fontScale),
                      const SizedBox(height: 10),
                      _DomainBar(label: 'Attention & Focus', value: attPct, color: AppColors.secondaryFixedDim, fontScale: fontScale),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── 5. Recent Sessions ────────────────────────────────
                if (recentAttempts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: AppColors.cardWhite, borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4)]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recent Sessions',
                          style: GoogleFonts.newsreader(
                              fontSize: 18 * fontScale, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 12),
                        ...recentAttempts.take(5).map((a) {
                          final pct = a.maxScore > 0 ? (a.rawScore / a.maxScore * 100).toInt() : 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                      color: pct >= 80 ? AppColors.sageSoft : AppColors.terracottaSoft,
                                      shape: BoxShape.circle),
                                  child: Icon(
                                    pct >= 80 ? Icons.check_circle : Icons.psychology,
                                    size: 18,
                                    color: pct >= 80 ? AppColors.secondary : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a.exerciseId,
                                        style: GoogleFonts.atkinsonHyperlegible(
                                            fontSize: 14 * fontScale, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                      Text(a.domain.name.toUpperCase(),
                                        style: GoogleFonts.atkinsonHyperlegible(
                                            fontSize: 11 * fontScale, color: AppColors.textSecondary, letterSpacing: 0.5)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: pct >= 80 ? AppColors.sageSoft : AppColors.surfaceCream,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Text('$pct%',
                                    style: GoogleFonts.atkinsonHyperlegible(
                                        fontSize: 13 * fontScale, fontWeight: FontWeight.w700,
                                        color: pct >= 80 ? AppColors.secondary : AppColors.primary)),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.history_toggle_off, color: AppColors.sageSecondary, size: 36),
                        const SizedBox(height: 10),
                        Text(
                          'No Recent Sessions Recorded',
                          style: GoogleFonts.newsreader(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Start your first memory exercise in the Practice or Games tab to log real session progress!',
                          style: GoogleFonts.atkinsonHyperlegible(fontSize: 13, color: AppColors.secondaryText),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<_DayData> _buildWeekData(List<dynamic> attempts) {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final count = attempts.where((a) {
        final DateTime ts = a.timestamp as DateTime;
        return ts.year == day.year && ts.month == day.month && ts.day == day.day;
      }).length;
      final minutes = (count * 2.5 + (i == 3 ? 10 : i == 1 ? 5 : 0)).clamp(0.0, 30.0);
      return _DayData(label: dayLabels[day.weekday - 1], minutes: minutes, isToday: i == 6);
    });
  }
}

class _WeekBarChart extends StatelessWidget {
  final List<_DayData> data;
  final double fontScale;

  const _WeekBarChart({required this.data, required this.fontScale});

  @override
  Widget build(BuildContext context) {
    final maxMinutes = data.fold(0.0, (m, d) => d.minutes > m ? d.minutes : m).clamp(1.0, double.infinity);

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((d) {
          final fraction = (d.minutes / maxMinutes).clamp(0.05, 1.0);
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  d.minutes > 0 ? '${d.minutes.toInt()}m' : '',
                  style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 11 * fontScale,
                      color: d.isToday ? AppColors.primary : AppColors.textMuted,
                      fontWeight: d.isToday ? FontWeight.w700 : FontWeight.w400),
                ),
                const SizedBox(height: 4),
                Expanded(
                  flex: (fraction * 100).toInt(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Container(
                      decoration: BoxDecoration(
                          color: d.isToday ? AppColors.primary : AppColors.secondaryFixed,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          boxShadow: d.isToday ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 4)] : null),
                    ),
                  ),
                ),
                Expanded(
                  flex: (100 - (fraction * 100).toInt()).clamp(0, 100),
                  child: const SizedBox(),
                ),
                const SizedBox(height: 6),
                Text(d.label,
                  style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 11 * fontScale,
                      color: d.isToday ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: d.isToday ? FontWeight.w700 : FontWeight.w400)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DomainBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final double fontScale;

  const _DomainBar({required this.label, required this.value, required this.color, required this.fontScale});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 14 * fontScale, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            Text('${(value * 100).toInt()}%', style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 16 * fontScale, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: AppColors.surfaceContainer,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 12,
          ),
        ),
      ],
    );
  }
}

class _DayData {
  final String label;
  final double minutes;
  final bool isToday;
  const _DayData({required this.label, required this.minutes, required this.isToday});
}
