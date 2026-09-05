import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController(text: 'Dadi Ma / Grandpa');
  final _credentialController = TextEditingController(text: 'patient123');
  final _passwordController = TextEditingController(text: 'smriti2026');
  bool _obscurePassword = true;
  String _selectedRole = 'Patient'; // 'Patient' or 'Caregiver'
  String _selectedLanguage = 'hi'; // 'hi', 'as', 'bn', 'en'

  @override
  void dispose() {
    _nameController.dispose();
    _credentialController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin(AppState appState) {
    if (_credentialController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Credential ID')),
      );
      return;
    }
    appState.login(
      name: _nameController.text,
      credentialId: _credentialController.text,
      role: _selectedRole,
      language: _selectedLanguage,
    );
    widget.onLoginSuccess();
  }

  void _applyDemoPreset(String role) {
    setState(() {
      _selectedRole = role;
      if (role == 'Caregiver') {
        _credentialController.text = 'caregiver456';
        _nameController.text = 'Dr. Sharma (Caregiver)';
        _passwordController.text = 'care2026';
      } else {
        _credentialController.text = 'patient123';
        _nameController.text = 'Dadi Ma / Grandpa';
        _passwordController.text = 'smriti2026';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Sacred Emblem / Logo Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryGold, width: 2),
                  ),
                  child: const Icon(
                    Icons.temple_hindu,
                    size: 64,
                    color: AppColors.primarySaffron,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'स्मृति वेद (Smriti Veda)',
                  style: GoogleFonts.cinzel(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGold,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Cognitive Memory & Regional Oral Practice Platform for Seniors',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Quick Demo Preset Selection Bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'SIH QUICK DEMO LOGIN PRESETS',
                        style: GoogleFonts.cinzel(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _applyDemoPreset('Patient'),
                              icon: const Icon(Icons.elderly, size: 16),
                              label: const Text('Senior Patient'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _selectedRole == 'Patient' ? AppColors.primarySaffron : AppColors.primaryGold,
                                side: BorderSide(
                                  color: _selectedRole == 'Patient' ? AppColors.primarySaffron : AppColors.primaryGold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _applyDemoPreset('Caregiver'),
                              icon: const Icon(Icons.family_restroom, size: 16),
                              label: const Text('Caregiver / Doctor'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _selectedRole == 'Caregiver' ? AppColors.primarySaffron : AppColors.primaryGold,
                                side: BorderSide(
                                  color: _selectedRole == 'Caregiver' ? AppColors.primarySaffron : AppColors.primaryGold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. ACCOUNT CREDENTIALS',
                        style: GoogleFonts.cinzel(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _credentialController,
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Credential ID / Username',
                          hintText: 'e.g. patient123',
                          prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primarySaffron),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          filled: true,
                          fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Account Password',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primarySaffron),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.primaryGold,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          filled: true,
                          fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        '2. PRACTITIONER DISPLAY NAME',
                        style: GoogleFonts.cinzel(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _nameController,
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'Enter practitioner name...',
                          prefixIcon: const Icon(Icons.person_outline, color: AppColors.primarySaffron),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          filled: true,
                          fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Account Role Selector
                      Text(
                        '3. ACCOUNT ROLE',
                        style: GoogleFonts.cinzel(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRoleCard(
                              role: 'Patient',
                              label: 'Senior User',
                              subtitle: 'Cognitive Exercises',
                              icon: Icons.elderly,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRoleCard(
                              role: 'Caregiver',
                              label: 'Caregiver / Family',
                              subtitle: 'Progress Telemetry',
                              icon: Icons.family_restroom,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Language Selector
                      Text(
                        '4. PREFERRED REGIONAL LANGUAGE',
                        style: GoogleFonts.cinzel(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildLangChip('hi', 'हिंदी (Hindi)'),
                          _buildLangChip('as', 'অসমীয়া (Assamese - NER)'),
                          _buildLangChip('bn', 'বাংলা (Bengali)'),
                          _buildLangChip('en', 'English'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Login Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleLogin(appState),
                    icon: const Icon(Icons.login, size: 24),
                    label: Text(
                      'LOG IN TO PLATFORM (प्रवेशम्)',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primarySaffron,
                      foregroundColor: Colors.white,
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primarySaffron.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primarySaffron : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primarySaffron : AppColors.primaryGold,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primarySaffron : (isDark ? Colors.white : Colors.black87),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangChip(String code, String label) {
    final isSelected = _selectedLanguage == code;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primarySaffron,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.primaryGold,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedLanguage = code);
        }
      },
    );
  }
}
