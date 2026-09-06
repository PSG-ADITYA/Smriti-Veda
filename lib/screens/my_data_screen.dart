import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/db_service.dart';
import '../theme/app_theme.dart';
import 'medical_reports_screen.dart';
import 'profile_screen.dart';

class MyDataScreen extends StatelessWidget {
  const MyDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final profile = DbService().getUserProfile() ?? {};
    final files = DbService().getPatientFiles();
    final appointments = DbService().getAppointments();
    final attempts = appState.attemptRepository.getRecentAttempts(userId: appState.activeUser.id);

    final totalAttempts = attempts.length;
    final uniAttempts = attempts.where((a) => a.domain == ExerciseDomain.universalCognitive).toList();
    final oralAttempts = attempts.where((a) => a.domain == ExerciseDomain.culturalOral).toList();
    final uniAcc = uniAttempts.isEmpty ? 0.0 : (uniAttempts.fold<double>(0.0, (s, a) => s + (a.maxScore > 0 ? a.rawScore / a.maxScore : 0.0)) / uniAttempts.length * 100);
    final oralAcc = oralAttempts.isEmpty ? 0.0 : (oralAttempts.fold<double>(0.0, (s, a) => s + (a.maxScore > 0 ? a.rawScore / a.maxScore : 0.0)) / oralAttempts.length * 100);
    final streakDays = attempts.isEmpty ? 0 : attempts.map((a) => "${a.timestamp.year}-${a.timestamp.month}-${a.timestamp.day}").toSet().length;

    final ageStr = (profile['age'] != null && profile['age'].toString().isNotEmpty && profile['age'] != 0) ? '${profile['age']} Years' : 'Not specified';
    final emergencyStr = (profile['emergencyContact'] != null && profile['emergencyContact'].toString().isNotEmpty) ? profile['emergencyContact'] : 'Not provided';

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
          'My Data Hub',
          style: GoogleFonts.newsreader(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.terracottaPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.3)),
                boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.sageSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined, color: AppColors.sageSecondary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Personal Data Vault',
                          style: GoogleFonts.newsreader(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoalText,
                          ),
                        ),
                        Text(
                          'Transparent overview of profile, cognitive metrics, practice logs, and medical records stored on SmritiVeda.',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 13,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profile Summary Section
            _buildDataSectionCard(
              title: 'PROFILE & ACCOUNT INFORMATION',
              icon: Icons.person_outline,
              iconColor: AppColors.terracottaPrimary,
              actionLabel: 'Edit Profile',
              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: Column(
                children: [
                  _buildDataRow('Name', profile['name'] ?? appState.userName),
                  _buildDataRow('Role / Type', profile['role'] ?? appState.userRole),
                  _buildDataRow('Credential ID', profile['credentialId'] ?? appState.credentialId),
                  _buildDataRow('Preferred Language', profile['language'] ?? appState.selectedLanguage),
                  _buildDataRow('Age', ageStr),
                  _buildDataRow('Emergency Contact', emergencyStr),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Cognitive Performance History
            _buildDataSectionCard(
              title: 'COGNITIVE PERFORMANCE HISTORY',
              icon: Icons.psychology_outlined,
              iconColor: AppColors.sageSecondary,
              child: Column(
                children: [
                  _buildDataRow('Total Exercises Logged', '$totalAttempts Attempts'),
                  _buildDataRow('Universal Games Accuracy', uniAttempts.isNotEmpty ? '${uniAcc.toStringAsFixed(1)}% Average' : 'No attempts recorded'),
                  _buildDataRow('Oral Recitation Accuracy', oralAttempts.isNotEmpty ? '${oralAcc.toStringAsFixed(1)}% Average' : 'No attempts recorded'),
                  _buildDataRow('Current Practice Streak', streakDays > 0 ? '$streakDays Consecutive Days' : '0 Days (Start today)'),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Medical Reports Summary
            _buildDataSectionCard(
              title: 'MEDICAL DOCUMENTS & REPORTS',
              icon: Icons.medical_information_outlined,
              iconColor: AppColors.sandalwoodGold,
              actionLabel: 'View Medical Hub',
              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicalReportsScreen())),
              child: Column(
                children: [
                  _buildDataRow('Saved Reports Count', '${files.length} Documents'),
                  if (files.isNotEmpty)
                    _buildDataRow('Latest Report', '${files.last.title} (${files.last.uploadDate.toString().split(' ')[0]})')
                  else
                    _buildDataRow('Status', 'No medical reports uploaded yet'),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Appointments & Reminders Summary
            _buildDataSectionCard(
              title: 'APPOINTMENTS & REMINDERS',
              icon: Icons.calendar_today_outlined,
              iconColor: AppColors.terracottaPrimary,
              child: Column(
                children: appointments.isEmpty
                    ? [_buildDataRow('Status', 'No appointments scheduled')]
                    : appointments.map((apt) {
                        return _buildDataRow(
                          apt.title,
                          '${apt.doctorName} • ${apt.date.toString().split(' ')[0]} at ${apt.time.format(context)}',
                        );
                      }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.newsreader(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: iconColor,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  child: Text(
                    actionLabel,
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 13,
              color: AppColors.secondaryText,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoalText,
            ),
          ),
        ],
      ),
    );
  }
}
