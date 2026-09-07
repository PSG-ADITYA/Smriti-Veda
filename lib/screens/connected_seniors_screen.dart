import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/connected_senior.dart';
import '../providers/app_state.dart';
import '../services/caregiver_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'caregiver_dashboard_screen.dart';

class ConnectedSeniorsScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const ConnectedSeniorsScreen({super.key, this.onNavigateTab});

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

        return Scaffold(
          backgroundColor: AppColors.canvasIvory,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Description
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connected Seniors',
                              style: GoogleFonts.newsreader(
                                fontSize: 24 * fontScale,
                                fontWeight: FontWeight.bold,
                                color: AppColors.charcoalText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage authorized senior profiles and data access',
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 13 * fontScale,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        icon: const Icon(Icons.add, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.terracottaPrimary,
                          minimumSize: const Size(48, 48),
                        ),
                        tooltip: 'Connect Senior',
                        onPressed: () => showConnectSeniorModal(context, caregiverId),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Seniors List or Empty State
                  if (seniors.isEmpty)
                    _buildEmptyState(context, caregiverId, fontScale)
                  else
                    Column(
                      children: seniors.map((senior) {
                        return _buildSeniorCard(
                          context,
                          senior,
                          caregiverId,
                          appState,
                          fontScale,
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 24),

                  // Privacy & Authorization Security Boundary Box
                  _buildSecurityBoundaryNotice(fontScale),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String caregiverId, double fontScale) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A2D241C),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.terracottaSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 32,
              color: AppColors.terracottaPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Connected Seniors',
            style: GoogleFonts.newsreader(
              fontSize: 20 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoalText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Link a senior family member to monitor cognitive progress, safety alerts, and health documents.',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 14 * fontScale,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_link_rounded, size: 20),
              label: Text(
                'Connect Senior Now',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 15 * fontScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracottaPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => showConnectSeniorModal(context, caregiverId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeniorCard(
    BuildContext context,
    ConnectedSenior senior,
    String caregiverId,
    AppState appState,
    double fontScale,
  ) {
    final attempts = appState.attemptRepo.getAttempts(userId: senior.patientId);
    final totalCompleted = attempts.length;
    final latestAttempt = attempts.isNotEmpty ? attempts.last : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A2D241C),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Senior Header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.terracottaSoft,
                child: Text(
                  senior.name.isNotEmpty ? senior.name[0].toUpperCase() : 'S',
                  style: GoogleFonts.newsreader(
                    fontSize: 20,
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
                    Text(
                      senior.name,
                      style: GoogleFonts.newsreader(
                        fontSize: 18 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoalText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${senior.relationship} • ID: ${senior.patientId}',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 13 * fontScale,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Authorized',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 11 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 14),

          // Real Senior Activity Metrics
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 18, color: AppColors.sageSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$totalCompleted exercises completed',
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 13 * fontScale,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoalText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                latestAttempt != null
                    ? 'Active ${latestAttempt.timestamp.day}/${latestAttempt.timestamp.month}'
                    : 'No sessions yet',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 12 * fontScale,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Shortcuts
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.insights_rounded, size: 16),
                    label: Text(
                      'Progress',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 13 * fontScale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.terracottaPrimary,
                      side: const BorderSide(color: AppColors.terracottaPrimary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      CaregiverService().setActiveSeniorId(senior.patientId);
                      if (onNavigateTab != null) {
                        onNavigateTab!(2); // Insights tab
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.medical_services_outlined, size: 16),
                    label: Text(
                      'Medical',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 13 * fontScale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.sageSecondary,
                      side: const BorderSide(color: AppColors.sageSecondary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      CaregiverService().setActiveSeniorId(senior.patientId);
                      if (onNavigateTab != null) {
                        onNavigateTab!(3); // Medical tab
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                width: 44,
                child: IconButton(
                  icon: const Icon(Icons.link_off_rounded, color: Colors.redAccent, size: 20),
                  tooltip: 'Disconnect Senior',
                  onPressed: () => _confirmDisconnect(context, caregiverId, senior),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDisconnect(BuildContext context, String caregiverId, ConnectedSenior senior) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Disconnect ${senior.name}?',
          style: GoogleFonts.newsreader(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove authorization for ${senior.name}? You will no longer receive their daily cognitive updates.',
          style: GoogleFonts.atkinsonHyperlegible(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              SoundService().playTapSound();
              await CaregiverService().disconnectSenior(caregiverId, senior.patientId);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${senior.name} disconnected.')),
                );
              }
            },
            child: const Text('Disconnect', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBoundaryNotice(double fontScale) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined, color: AppColors.sageSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security & Privacy Boundary Active',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoalText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Caregivers can only view cognitive records and medical files for verified, authorized seniors. Unlinked senior data cannot be accessed.',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 11 * fontScale,
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
}
