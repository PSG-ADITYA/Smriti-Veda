import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/connected_senior.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/caregiver_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const CaregiverDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<CaregiverDashboardScreen> createState() => _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final fontScale = appState.fontScale;
    final caregiverId = appState.credentialId.isNotEmpty ? appState.credentialId : 'caregiver';
    final caregiverService = CaregiverService();

    return ListenableBuilder(
      listenable: caregiverService,
      builder: (context, _) {
        final connectedSeniors = caregiverService.getConnectedSeniors(caregiverId);
        final activeSenior = caregiverService.getActiveSenior(caregiverId);

        // Fetch real attempts for the active connected senior if available
        List<ExerciseAttempt> realAttempts = [];
        if (activeSenior != null) {
          try {
            realAttempts = caregiverService.getSeniorAttempts(
              caregiverId,
              activeSenior.patientId,
              appState.attemptRepo,
            );
          } catch (_) {
            realAttempts = [];
          }
        }

        return Scaffold(
          backgroundColor: AppColors.canvasIvory,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Warm Caregiver Greeting Header
                  _buildCaregiverHeader(appState.userName, fontScale),

                  const SizedBox(height: 20),

                  // 2. Connected Seniors Section / Empty State
                  if (connectedSeniors.isEmpty)
                    _buildEmptySeniorsCard(context, caregiverId, fontScale)
                  else
                    _buildActiveSeniorCard(
                      context,
                      activeSenior!,
                      connectedSeniors,
                      caregiverId,
                      realAttempts,
                      fontScale,
                    ),

                  const SizedBox(height: 24),

                  // 3. Cognitive Performance & Exercise History (Real Data Only)
                  _buildRealPerformanceSection(
                    activeSenior,
                    realAttempts,
                    fontScale,
                  ),

                  const SizedBox(height: 24),

                  // 4. Quick Actions
                  _buildQuickActions(context, caregiverId, connectedSeniors.isNotEmpty, fontScale),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Caregiver Header with warm greeting and role badge
  Widget _buildCaregiverHeader(String userName, double fontScale) {
    final displayName = userName.isNotEmpty ? userName : 'Caregiver';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A2D241C),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.terracottaSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.terracottaPrimary.withValues(alpha: 0.2)),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.terracottaPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.sageSecondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Caregiver Guardian Portal',
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 11 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sageSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome, $displayName',
                  style: GoogleFonts.newsreader(
                    fontSize: 20 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoalText,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  'Monitoring family cognitive wellness & safety',
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
  }

  /// Empty State Card when no senior is connected
  Widget _buildEmptySeniorsCard(BuildContext context, String caregiverId, double fontScale) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A2D241C),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceCream,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_search_outlined,
              size: 34,
              color: AppColors.terracottaPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Connected Seniors Yet',
            style: GoogleFonts.newsreader(
              fontSize: 20 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoalText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Connect an elderly parent or family member using their Patient ID or registered email to view their daily memory practice, cognitive progress, and medical reports.',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 14 * fontScale,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_link_rounded, size: 20),
              label: Text(
                'Connect Senior',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 16 * fontScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracottaPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              onPressed: () => showConnectSeniorModal(context, caregiverId),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: AppColors.sageSecondary),
              label: Text(
                '1-Tap Connect: Aditya Verma (Demo)',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 14 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sageSecondary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.sageSecondary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                await CaregiverService().connectSenior(
                  caregiverId,
                  patientId: 'uid_demo_sih',
                  relationship: 'Father',
                  customName: 'Aditya Verma (Demo Senior)',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Connected to Aditya Verma successfully!')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Active Senior Overview Card with Real Status & Metrics
  Widget _buildActiveSeniorCard(
    BuildContext context,
    ConnectedSenior senior,
    List<ConnectedSenior> allSeniors,
    String caregiverId,
    List<ExerciseAttempt> attempts,
    double fontScale,
  ) {
    final totalCompleted = attempts.length;
    double avgScore = 0;
    if (totalCompleted > 0) {
      final totalScore = attempts.fold<double>(0.0, (sum, a) => sum + (a.rawScore / a.maxScore * 100));
      avgScore = totalScore / totalCompleted;
    }

    final latestAttempt = attempts.isNotEmpty ? attempts.last : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A2D241C),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Senior Header Row
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.terracottaSoft,
                child: Text(
                  senior.name.isNotEmpty ? senior.name[0].toUpperCase() : 'S',
                  style: GoogleFonts.newsreader(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.terracottaPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            senior.name,
                            style: GoogleFonts.newsreader(
                              fontSize: 18 * fontScale,
                              fontWeight: FontWeight.bold,
                              color: AppColors.charcoalText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade300, width: 0.8),
                          ),
                          child: Text(
                            'Connected',
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 10 * fontScale,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${senior.relationship} • ID: ${senior.patientId}',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 13 * fontScale,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (allSeniors.length > 1)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.terracottaPrimary),
                  tooltip: 'Switch Active Senior',
                  onSelected: (pid) {
                    CaregiverService().setActiveSeniorId(pid);
                  },
                  itemBuilder: (_) => allSeniors.map((s) {
                    return PopupMenuItem(
                      value: s.patientId,
                      child: Text(s.name, style: GoogleFonts.atkinsonHyperlegible()),
                    );
                  }).toList(),
                ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 16),

          // Real Metric Stat Badges
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Exercises Done',
                  value: '$totalCompleted',
                  icon: Icons.fitness_center_rounded,
                  color: AppColors.terracottaPrimary,
                  fontScale: fontScale,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Avg Mastery',
                  value: totalCompleted > 0 ? '${avgScore.toStringAsFixed(0)}%' : 'N/A',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.sageSecondary,
                  fontScale: fontScale,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Latest Activity Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.canvasIvory,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    latestAttempt != null
                        ? 'Latest: ${latestAttempt.domain.name} • ${latestAttempt.timestamp.day}/${latestAttempt.timestamp.month}/${latestAttempt.timestamp.year}'
                        : 'No exercises completed yet by ${senior.name}',
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 12 * fontScale,
                      color: AppColors.charcoalText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double fontScale,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 11 * fontScale,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: GoogleFonts.newsreader(
                    fontSize: 18 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoalText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Real Cognitive Performance Section (Zero Fake Statistics)
  Widget _buildRealPerformanceSection(
    ConnectedSenior? activeSenior,
    List<ExerciseAttempt> attempts,
    double fontScale,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recent Cognitive Activity',
                style: GoogleFonts.newsreader(
                  fontSize: 18 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoalText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (activeSenior != null && attempts.isNotEmpty && widget.onNavigateTab != null)
              TextButton(
                onPressed: () => widget.onNavigateTab!(2), // Switch to Insights Tab
                child: Text(
                  'View All',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 13 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.terracottaPrimary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (activeSenior == null)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              'Connect an authorized senior to monitor daily cognitive performance records.',
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 13 * fontScale,
                color: AppColors.textSecondary,
              ),
            ),
          )
        else if (attempts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                    const Icon(Icons.info_outline, size: 20, color: AppColors.sageSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'No Practice Sessions Recorded Yet',
                      style: GoogleFonts.newsreader(
                        fontSize: 15 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoalText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${activeSenior.name} has not logged any cognitive exercises on their device yet. Practice logs will appear here automatically once completed.',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 13 * fontScale,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: attempts.reversed.take(3).map((attempt) {
              final pct = (attempt.rawScore / attempt.maxScore * 100).clamp(0, 100).toInt();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.terracottaSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '$pct%',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 13 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: AppColors.terracottaPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attempt.exerciseId.replaceAll('_', ' ').toUpperCase(),
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 14 * fontScale,
                              fontWeight: FontWeight.bold,
                              color: AppColors.charcoalText,
                            ),
                          ),
                          Text(
                            'Domain: ${attempt.domain.name} • ${attempt.timestamp.day}/${attempt.timestamp.month}/${attempt.timestamp.year}',
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
            }).toList(),
          ),
      ],
    );
  }

  /// Quick Action Buttons for Family Caregivers
  Widget _buildQuickActions(
    BuildContext context,
    String caregiverId,
    bool hasConnectedSenior,
    double fontScale,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.newsreader(
            fontSize: 18 * fontScale,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoalText,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.person_add_alt_1_rounded,
                label: 'Connect Senior',
                color: AppColors.terracottaPrimary,
                fontScale: fontScale,
                onTap: () => showConnectSeniorModal(context, caregiverId),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                icon: Icons.insights_rounded,
                label: 'View Insights',
                color: AppColors.sageSecondary,
                fontScale: fontScale,
                onTap: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(2); // Insights
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.medical_services_outlined,
                label: 'Medical Reports',
                color: AppColors.sandalwoodGold,
                fontScale: fontScale,
                onTap: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(3); // Medical Reports
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                icon: Icons.manage_accounts_outlined,
                label: 'Caregiver Profile',
                color: AppColors.charcoalText,
                fontScale: fontScale,
                onTap: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(4); // Profile
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required double fontScale,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        SoundService().playTapSound();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0A2D241C),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 13 * fontScale,
                fontWeight: FontWeight.bold,
                color: AppColors.charcoalText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal Dialog to Connect a Senior by Patient ID or registered profile
void showConnectSeniorModal(BuildContext context, String caregiverId) {
  final idController = TextEditingController();
  final relationshipController = TextEditingController(text: 'Parent');
  final nameController = TextEditingController();
  bool isSubmitting = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.add_link_rounded, color: AppColors.terracottaPrimary),
            const SizedBox(width: 10),
            Text(
              'Connect Senior',
              style: GoogleFonts.newsreader(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the Senior\'s Patient ID or Email to establish an authorized connection:',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: idController,
                decoration: InputDecoration(
                  labelText: 'Patient ID or Email (e.g. uid_demo_sih or patient123)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Senior Full Name (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationshipController,
                decoration: InputDecoration(
                  labelText: 'Relationship (e.g. Father, Mother, Spouse)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.family_restroom),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.smart_toy_outlined, size: 16),
                    label: const Text('Demo Senior'),
                    onPressed: () {
                      setDialogState(() {
                        idController.text = 'uid_demo_sih';
                        nameController.text = 'Aditya Verma (Demo Senior)';
                        relationshipController.text = 'Father';
                      });
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.person_outline, size: 16),
                    label: const Text('Default Patient'),
                    onPressed: () {
                      setDialogState(() {
                        idController.text = 'patient123';
                        nameController.text = 'Senior Patient';
                        relationshipController.text = 'Mother';
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracottaPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(110, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: isSubmitting
                ? null
                : () async {
                    final pid = idController.text.trim();
                    if (pid.isEmpty) return;

                    setDialogState(() => isSubmitting = true);
                    final success = await CaregiverService().connectSenior(
                      caregiverId,
                      patientId: pid,
                      relationship: relationshipController.text.trim(),
                      customName: nameController.text.trim().isNotEmpty
                          ? nameController.text.trim()
                          : null,
                    );
                    setDialogState(() => isSubmitting = false);

                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Senior successfully connected and authorized!'
                                : 'Failed to connect senior. Please verify Patient ID.',
                          ),
                        ),
                      );
                    }
                  },
            child: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Connect'),
          ),
        ],
      ),
    ),
  );
}
