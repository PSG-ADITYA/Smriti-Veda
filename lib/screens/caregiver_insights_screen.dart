import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/connected_senior.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/caregiver_service.dart';
import '../theme/app_theme.dart';
import 'caregiver_dashboard_screen.dart';

class CaregiverInsightsScreen extends StatelessWidget {
  const CaregiverInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final fontScale = appState.fontScale;
    final caregiverId = appState.credentialId.isNotEmpty ? appState.credentialId : 'caregiver';
    final caregiverService = CaregiverService();

    return ListenableBuilder(
      listenable: caregiverService,
      builder: (context, _) {
        final seniors = caregiverService.getConnectedSeniors(caregiverId);
        final activeSenior = caregiverService.getActiveSenior(caregiverId);

        return Scaffold(
          backgroundColor: AppColors.canvasIvory,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Screen Title
                  Text(
                    'Cognitive Insights & Progress',
                    style: GoogleFonts.newsreader(
                      fontSize: 24 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoalText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Clinical observation logs and domain-specific progression',
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 13 * fontScale,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Senior Selector / Empty State
                  if (seniors.isEmpty)
                    _buildNoSeniorEmptyState(context, caregiverId, fontScale)
                  else ...[
                    _buildSeniorSelectorHeader(seniors, activeSenior!, fontScale),
                    const SizedBox(height: 20),
                    _buildSeniorInsightsBody(
                      context,
                      caregiverId,
                      activeSenior,
                      appState,
                      caregiverService,
                      fontScale,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoSeniorEmptyState(BuildContext context, String caregiverId, double fontScale) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          const Icon(Icons.analytics_outlined, size: 48, color: AppColors.sageSecondary),
          const SizedBox(height: 16),
          Text(
            'No Senior Selected',
            style: GoogleFonts.newsreader(
              fontSize: 20 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoalText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect an authorized senior to review clinical scores, domain progress, and daily practice history.',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 14 * fontScale,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracottaPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(180, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => showConnectSeniorModal(context, caregiverId),
            child: const Text('Connect Senior'),
          ),
        ],
      ),
    );
  }

  Widget _buildSeniorSelectorHeader(
    List<ConnectedSenior> seniors,
    ConnectedSenior activeSenior,
    double fontScale,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.terracottaSoft,
            child: Text(
              activeSenior.name.isNotEmpty ? activeSenior.name[0].toUpperCase() : 'S',
              style: GoogleFonts.newsreader(
                fontWeight: FontWeight.bold,
                color: AppColors.terracottaPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeSenior.name,
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 15 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoalText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${activeSenior.relationship} • Authorized Access',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (seniors.length > 1)
            PopupMenuButton<String>(
              icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: AppColors.terracottaPrimary),
              onSelected: (pid) {
                CaregiverService().setActiveSeniorId(pid);
              },
              itemBuilder: (_) => seniors.map((s) {
                return PopupMenuItem(
                  value: s.patientId,
                  child: Text(s.name, style: GoogleFonts.atkinsonHyperlegible()),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSeniorInsightsBody(
    BuildContext context,
    String caregiverId,
    ConnectedSenior senior,
    AppState appState,
    CaregiverService caregiverService,
    double fontScale,
  ) {
    // 1. Enforce Security Boundary Check
    if (!caregiverService.isAuthorized(caregiverId, senior.patientId)) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          children: [
            const Icon(Icons.gpp_bad_outlined, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              'Access Denied',
              style: GoogleFonts.newsreader(
                fontSize: 18 * fontScale,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Security Boundary: You are not authorized to view cognitive telemetry for this patient ID (${senior.patientId}).',
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 13 * fontScale,
                color: Colors.red.shade900,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // 2. Fetch Real Attempts
    List<ExerciseAttempt> attempts = [];
    try {
      attempts = caregiverService.getSeniorAttempts(
        caregiverId,
        senior.patientId,
        appState.attemptRepo,
      );
    } catch (_) {
      attempts = [];
    }

    if (attempts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart_rounded, size: 24, color: AppColors.sageSecondary),
                const SizedBox(width: 8),
                Text(
                  'No Exercise Records Available',
                  style: GoogleFonts.newsreader(
                    fontSize: 18 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoalText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${senior.name} has not completed any cognitive exercises on this device yet. Once daily practice sessions are completed, domain accuracy, response speed, and memory trends will be calculated automatically.',
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 14 * fontScale,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    // Calculate Real Metrics
    final totalAttempts = attempts.length;
    final totalScorePct = attempts.fold<double>(0.0, (sum, a) => sum + (a.rawScore / a.maxScore * 100));
    final avgMastery = (totalScorePct / totalAttempts).clamp(0, 100).toDouble();

    // Domain Breakdown
    final domainCounts = <String, int>{};
    for (final a in attempts) {
      domainCounts[a.domain.name] = (domainCounts[a.domain.name] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top High-Level Metric Tiles
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                'Total Sessions',
                '$totalAttempts',
                Icons.check_circle_outline,
                AppColors.terracottaPrimary,
                fontScale,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                'Avg Accuracy',
                '${avgMastery.toStringAsFixed(0)}%',
                Icons.psychology_outlined,
                AppColors.sageSecondary,
                fontScale,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Domain Breakdown Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cognitive Domains Practiced',
                style: GoogleFonts.newsreader(
                  fontSize: 18 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoalText,
                ),
              ),
              const SizedBox(height: 14),
              ...domainCounts.entries.map((e) {
                final pct = (e.value / totalAttempts).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDomainName(e.key),
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 13 * fontScale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${e.value} sessions (${(pct * 100).toStringAsFixed(0)}%)',
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 12 * fontScale,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: AppColors.surfaceCream,
                          valueColor: const AlwaysStoppedAnimation(AppColors.terracottaPrimary),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Recent Activity Chronological List
        Text(
          'Exercise Session History',
          style: GoogleFonts.newsreader(
            fontSize: 18 * fontScale,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoalText,
          ),
        ),
        const SizedBox(height: 12),
        ...attempts.reversed.map((a) {
          final scorePct = (a.rawScore / a.maxScore * 100).clamp(0, 100).toInt();
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.terracottaSoft,
                  child: Text(
                    '$scorePct%',
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.terracottaPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.exerciseId.replaceAll('_', ' ').toUpperCase(),
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontWeight: FontWeight.bold,
                          fontSize: 14 * fontScale,
                        ),
                      ),
                      Text(
                        'Mode: ${a.responseMode} • ${a.timestamp.day}/${a.timestamp.month}/${a.timestamp.year} ${a.timestamp.hour}:${a.timestamp.minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 12 * fontScale,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMetricTile(
    String title,
    String value,
    IconData icon,
    Color color,
    double fontScale,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.newsreader(
              fontSize: 22 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoalText,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 12 * fontScale,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDomainName(String raw) {
    switch (raw) {
      case 'culturalOral':
        return 'Oral Heritage & Recitation';
      case 'everydayMemory':
        return 'Everyday Daily Memory';
      case 'universalCognitive':
        return 'Universal Cognitive Tasks';
      default:
        return raw;
    }
  }
}
