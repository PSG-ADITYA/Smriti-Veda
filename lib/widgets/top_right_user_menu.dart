import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state.dart';
import '../screens/medical_reports_screen.dart';
import '../screens/my_data_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/welcome_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class TopRightUserMenu extends StatelessWidget {
  const TopRightUserMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final userName = appState.userName;
    final userRole = appState.userRole;

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
            break;
          case 'my_data':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyDataScreen()),
            );
            break;
          case 'medical_reports':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MedicalReportsScreen()),
            );
            break;
          case 'logout':
            await AuthService().logout();
            appState.logout();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            }
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: GoogleFonts.newsreader(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoalText,
                ),
              ),
              Text(
                '$userRole • SmritiVeda Member',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
              ),
              const Divider(height: 16, color: AppColors.borderSubtle),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person_outline, size: 20, color: AppColors.terracottaPrimary),
              const SizedBox(width: 10),
              Text('Profile & Preferences', style: GoogleFonts.atkinsonHyperlegible(fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'my_data',
          child: Row(
            children: [
              const Icon(Icons.folder_open_rounded, size: 20, color: AppColors.sageSecondary),
              const SizedBox(width: 10),
              Text('My Data Hub', style: GoogleFonts.atkinsonHyperlegible(fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'medical_reports',
          child: Row(
            children: [
              const Icon(Icons.medical_information_outlined, size: 20, color: AppColors.sandalwoodGold),
              const SizedBox(width: 10),
              Text('Medical Reports', style: GoogleFonts.atkinsonHyperlegible(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
              const SizedBox(width: 10),
              Text(
                'Log Out',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.terracottaSoft,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.terracottaPrimary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.terracottaPrimary,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: GoogleFonts.newsreader(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_drop_down,
              color: AppColors.terracottaPrimary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
