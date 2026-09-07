import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';
import '../services/caregiver_service.dart';
import '../services/db_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'welcome_screen.dart';

class CaregiverProfileScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const CaregiverProfileScreen({super.key, this.onNavigateTab});

  @override
  State<CaregiverProfileScreen> createState() => _CaregiverProfileScreenState();
}

class _CaregiverProfileScreenState extends State<CaregiverProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  String _selectedLang = 'en';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _contactController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = AppStateScope.of(context);
    if (!_isEditing) {
      _nameController.text = appState.userName;
      _contactController.text = appState.emergencyContact ?? '';
      _selectedLang = appState.selectedLanguage;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final fontScale = appState.fontScale;
    final caregiverId = appState.credentialId.isNotEmpty ? appState.credentialId : 'caregiver';
    final caregiverService = CaregiverService();
    final connectedSeniors = caregiverService.getConnectedSeniors(caregiverId);

    return Scaffold(
      backgroundColor: AppColors.canvasIvory,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Heading
              Text(
                'Caregiver Profile',
                style: GoogleFonts.newsreader(
                  fontSize: 24 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoalText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Personal information, authorized seniors, and security controls',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 13 * fontScale,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 20),

              // Caregiver Profile Card
              Container(
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
                child: _isEditing
                    ? _buildEditProfileForm(appState, caregiverId, fontScale)
                    : _buildProfileInfoView(appState, fontScale),
              ),

              const SizedBox(height: 20),

              // Managed Seniors Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Authorized Seniors',
                          style: GoogleFonts.newsreader(
                            fontSize: 18 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoalText,
                          ),
                        ),
                        if (widget.onNavigateTab != null)
                          TextButton(
                            onPressed: () => widget.onNavigateTab!(1), // Seniors Tab
                            child: Text(
                              'Manage (${connectedSeniors.length})',
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
                    if (connectedSeniors.isEmpty)
                      Text(
                        'No seniors currently authorized. Go to the Seniors tab to link family members.',
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 13 * fontScale,
                          color: AppColors.textSecondary,
                        ),
                      )
                    else
                      Column(
                        children: connectedSeniors.map((s) {
                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.terracottaSoft,
                              child: Text(
                                s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.terracottaPrimary,
                                ),
                              ),
                            ),
                            title: Text(
                              s.name,
                              style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('${s.relationship} • ID: ${s.patientId}'),
                            trailing: const Icon(Icons.check_circle, color: AppColors.sageSecondary, size: 20),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Security & Privacy Policy Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCream,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: AppColors.sageSecondary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Privacy & Access Guarantee',
                          style: GoogleFonts.newsreader(
                            fontSize: 16 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoalText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Access is strictly confined to seniors who have authorized your caregiver account.\n'
                      '• Cognitive telemetry, recitation audio sessions, and medical documents are kept private and encrypted.\n'
                      '• Designed in accordance with ABDM and NHA health data privacy standards.',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 12 * fontScale,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Role Switcher & Sign Out
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.borderSubtle),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SwitchListTile(
                      activeThumbColor: AppColors.terracottaPrimary,
                      title: Text(
                        'Caregiver Dashboard Mode',
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 15 * fontScale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text('Toggle between Caregiver Portal and Patient View'),
                      value: appState.isCaregiverMode,
                      onChanged: (val) {
                        appState.setCaregiverMode(val);
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                      title: Text(
                        'Sign Out',
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 15 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                      subtitle: const Text('Exit session and clear active caregiver credentials'),
                      onTap: () => _handleLogout(context, appState),
                    ),
                  ],
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoView(AppState appState, double fontScale) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.terracottaPrimary,
          child: Text(
            appState.userName.isNotEmpty ? appState.userName[0].toUpperCase() : 'C',
            style: GoogleFonts.newsreader(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appState.userName,
                style: GoogleFonts.newsreader(
                  fontSize: 20 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoalText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Role: Caregiver / Guardian',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 13 * fontScale,
                  color: AppColors.sageSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (appState.credentialId.isNotEmpty)
                Text(
                  'ID: ${appState.credentialId}',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppColors.terracottaPrimary),
          tooltip: 'Edit Profile',
          onPressed: () => setState(() => _isEditing = true),
        ),
      ],
    );
  }

  Widget _buildEditProfileForm(AppState appState, String caregiverId, double fontScale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit Caregiver Profile',
          style: GoogleFonts.newsreader(
            fontSize: 18 * fontScale,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoalText,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Caregiver Full Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contactController,
          decoration: InputDecoration(
            labelText: 'Contact Phone / Emergency Line',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _isEditing = false),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracottaPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final newName = _nameController.text.trim();
                final newContact = _contactController.text.trim();

                DbService().saveUserProfile(
                  name: newName,
                  role: 'Caregiver',
                  credentialId: caregiverId,
                  language: _selectedLang,
                  emergencyContact: newContact,
                  userId: caregiverId,
                );

                appState.login(
                  name: newName,
                  credentialId: caregiverId,
                  role: 'Caregiver',
                  language: _selectedLang,
                  emergencyContact: newContact,
                );

                setState(() => _isEditing = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Caregiver profile saved successfully!')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  void _handleLogout(BuildContext context, AppState appState) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Sign Out?', style: GoogleFonts.newsreader(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to sign out of SmritiVeda Caregiver mode?',
          style: GoogleFonts.atkinsonHyperlegible(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService().logout();
      appState.logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }
}
