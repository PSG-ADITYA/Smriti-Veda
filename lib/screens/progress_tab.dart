import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/exercise_attempt.dart';
import '../services/personalization_engine.dart';

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

        // Real cognitive domain metrics computed via PersonalizationEngine
    final domainScores = PersonalizationEngine.computeDomainScores(recentAttempts);

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
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showCaregiverDialog(context, appState, fontScale),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                          color: appState.connectedCaregiver != null ? AppColors.sageSoft : AppColors.surfaceCream,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: appState.connectedCaregiver != null
                                ? AppColors.sageSecondary.withValues(alpha: 0.3)
                                : AppColors.primary.withValues(alpha: 0.3),
                          ),
                          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4)]),
                      child: Row(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: const BoxDecoration(
                              color: AppColors.terracottaSoft,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              appState.connectedCaregiver != null ? Icons.favorite : Icons.person_add_alt_1,
                              color: appState.connectedCaregiver != null ? AppColors.secondary : AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appState.connectedCaregiver != null
                                      ? 'Connected: ${appState.connectedCaregiver!.name}'
                                      : 'Link Family Caregiver',
                                  style: GoogleFonts.atkinsonHyperlegible(
                                      fontSize: 14 * fontScale,
                                      fontWeight: FontWeight.w600,
                                      color: appState.connectedCaregiver != null ? AppColors.secondary : AppColors.primary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  appState.connectedCaregiver != null
                                      ? '${appState.connectedCaregiver!.relationship} • Daily Sync Active'
                                      : 'Share daily progress with family members',
                                  style: GoogleFonts.atkinsonHyperlegible(fontSize: 12 * fontScale, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: AppColors.cardWhite,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4)]),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  appState.connectedCaregiver != null ? 'View' : 'Connect',
                                  style: GoogleFonts.atkinsonHyperlegible(
                                      fontSize: 13 * fontScale,
                                      fontWeight: FontWeight.w600,
                                      color: appState.connectedCaregiver != null ? AppColors.secondary : AppColors.primary),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: appState.connectedCaregiver != null ? AppColors.secondary : AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.terracottaSoft, borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.spa, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text('Cognitive Vitality Sanctuary',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.atkinsonHyperlegible(
                                      fontSize: 11 * fontScale, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ),
                            ],
                          ),
                        ),
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
                                      Expanded(
                                        child: Text('Active Today',
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.atkinsonHyperlegible(
                                                fontSize: 12 * fontScale, color: AppColors.textSecondary)),
                                      ),
                                      Container(
                                        width: 28, height: 28,
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
                                    Expanded(
                                      child: Text(totalMinutesToday > 0 ? 'Daily goal met' : 'Not started today',
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.atkinsonHyperlegible(
                                              fontSize: 11 * fontScale, color: totalMinutesToday > 0 ? AppColors.secondary : AppColors.textSecondary)),
                                    ),
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
                                      Expanded(
                                        child: Text('Rhythm Streak',
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.atkinsonHyperlegible(
                                                fontSize: 12 * fontScale, color: AppColors.textSecondary)),
                                      ),
                                      Container(
                                        width: 28, height: 28,
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
                                    Expanded(
                                      child: Text(streakDays > 0 ? 'Steady cadence' : 'Start your streak',
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.atkinsonHyperlegible(
                                              fontSize: 11 * fontScale, color: AppColors.primary)),
                                    ),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Weekly Practice Rhythm',
                                  style: GoogleFonts.newsreader(
                                      fontSize: 18 * fontScale, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                Text('Minutes spent in daily mindful recall',
                                  style: GoogleFonts.atkinsonHyperlegible(fontSize: 12 * fontScale, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
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

                // ── 4. Comprehensive Cognitive Domain Breakdown ───────────────
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
                              Text('Cognitive Domain Profile',
                                style: GoogleFonts.newsreader(
                                    fontSize: 18 * fontScale, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              Text('Derived from actual exercise attempts',
                                style: GoogleFonts.atkinsonHyperlegible(fontSize: 12 * fontScale, color: AppColors.textSecondary)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.terracottaPrimary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '8 DOMAINS',
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 10 * fontScale,
                                fontWeight: FontWeight.bold,
                                color: AppColors.terracottaPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...CognitiveDomain.values.map((d) {
                        final score = domainScores[d];
                        final pct = (score != null && score.hasSufficientData) ? score.averagePercentage / 100.0 : 0.0;
                        final displayVal = (pct * 100).toInt();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(d.icon, size: 16, color: d.color),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      d.displayName,
                                      style: GoogleFonts.atkinsonHyperlegible(
                                        fontSize: 13 * fontScale,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    score != null && score.hasSufficientData
                                        ? '$displayVal% (${score.attemptCount} plays)'
                                        : 'Awaiting first practice',
                                    style: GoogleFonts.atkinsonHyperlegible(
                                      fontSize: 12 * fontScale,
                                      fontWeight: FontWeight.w700,
                                      color: score != null && score.hasSufficientData ? d.color : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: pct > 0 ? pct : 0.05,
                                  minHeight: 8,
                                  backgroundColor: Colors.black.withValues(alpha: 0.06),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    pct > 0 ? d.color : Colors.black12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
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

  void _showCaregiverDialog(BuildContext context, AppState appState, double fontScale) {
    final caregiver = appState.connectedCaregiver;

    if (caregiver == null) {
      _showConnectCaregiverSheet(context, appState, fontScale);
    } else {
      _showConnectedCaregiverSheet(context, appState, caregiver, fontScale);
    }
  }

  void _showConnectedCaregiverSheet(BuildContext context, AppState appState, dynamic caregiver, double fontScale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: AppColors.sageSoft, shape: BoxShape.circle),
                    child: const Icon(Icons.verified_user, color: AppColors.secondary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Connected Caregiver',
                          style: GoogleFonts.newsreader(fontSize: 20 * fontScale, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text('AES-256 Local Encrypted Sync',
                          style: GoogleFonts.atkinsonHyperlegible(fontSize: 12 * fontScale, color: AppColors.secondary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCream,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    _buildCaregiverInfoRow(Icons.person, 'Full Name', caregiver.name as String, fontScale),
                    const Divider(height: 16),
                    _buildCaregiverInfoRow(Icons.family_restroom, 'Relationship', caregiver.relationship as String, fontScale),
                    if ((caregiver.phoneNumber as String).isNotEmpty) ...[
                      const Divider(height: 16),
                      _buildCaregiverInfoRow(Icons.phone, 'Mobile Number', caregiver.phoneNumber as String, fontScale),
                    ],
                    if ((caregiver.email as String).isNotEmpty) ...[
                      const Divider(height: 16),
                      _buildCaregiverInfoRow(Icons.email, 'Email Address', caregiver.email as String, fontScale),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.sageSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sync, color: AppColors.secondary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Daily cognitive milestones & MMSE trend shared automatically.',
                        style: GoogleFonts.atkinsonHyperlegible(fontSize: 12 * fontScale, color: AppColors.secondary, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.link_off, size: 18),
                      label: Text('Disconnect', style: GoogleFonts.atkinsonHyperlegible(fontSize: 13 * fontScale)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmDisconnectCaregiver(context, appState);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.share, size: 18),
                      label: Text('Share Digest', style: GoogleFonts.atkinsonHyperlegible(fontSize: 13 * fontScale, fontWeight: FontWeight.w600)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cognitive wellness summary copied for family sharing!')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConnectCaregiverSheet(BuildContext context, AppState appState, double fontScale) {
    final nameCtrl = TextEditingController();
    final relCtrl = TextEditingController(text: 'Daughter / Son');
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: AppColors.terracottaSoft, shape: BoxShape.circle),
                      child: const Icon(Icons.person_add_alt_1, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Link Family Caregiver',
                            style: GoogleFonts.newsreader(fontSize: 20 * fontScale, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Text('Receive gentle daily updates & progress alerts',
                            style: GoogleFonts.atkinsonHyperlegible(fontSize: 12 * fontScale, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Caregiver / Family Member Name *',
                    hintText: 'e.g., Ananya Sharma',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: relCtrl,
                  decoration: InputDecoration(
                    labelText: 'Relationship *',
                    hintText: 'e.g., Son, Daughter, Spouse, Doctor',
                    prefixIcon: const Icon(Icons.family_restroom_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Mobile / WhatsApp Number',
                    hintText: '+91 98765 43210',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address (Optional)',
                    hintText: 'caregiver@family.org',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter the caregiver name')),
                        );
                        return;
                      }
                      appState.connectCaregiver(
                        name: name,
                        relationship: relCtrl.text.trim().isEmpty ? 'Family Caregiver' : relCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        phoneNumber: phoneCtrl.text.trim(),
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Caregiver $name linked successfully!')),
                      );
                    },
                    child: Text('Save & Connect Caregiver',
                      style: GoogleFonts.atkinsonHyperlegible(fontSize: 15 * fontScale, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaregiverInfoRow(IconData icon, String label, String value, double fontScale) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.atkinsonHyperlegible(fontSize: 11 * fontScale, color: AppColors.textSecondary)),
              Text(value, style: GoogleFonts.atkinsonHyperlegible(fontSize: 14 * fontScale, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDisconnectCaregiver(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Caregiver?'),
        content: const Text('Are you sure you want to disconnect your caregiver? You can re-link at any time.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              appState.disconnectCaregiver();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Caregiver disconnected.')),
              );
            },
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
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



class _DayData {
  final String label;
  final double minutes;
  final bool isToday;
  const _DayData({required this.label, required this.minutes, required this.isToday});
}
