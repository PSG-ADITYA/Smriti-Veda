import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'forgot_password_screen.dart';
import 'forgot_username_screen.dart';
import 'main_screen.dart';
import 'personalized_questionnaire_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _credentialController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    _credentialController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(AppState appState) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final credential = _credentialController.text.trim();
    final password = _passwordController.text;

    if (credential.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Email/Credential ID and Password')),
      );
      return;
    }

    final success = await AuthService().login(email: credential, password: password);
    if (!mounted) return;

    if (success) {
      final user = AuthService().currentUser!;
      final existingProfile = DbService().getUserProfile(user.uid);
      appState.login(
        name: user.name,
        credentialId: user.uid,
        role: user.role,
        language: user.language,
        age: existingProfile?['age'] as int?,
        emergencyContact: existingProfile?['emergencyContact'] as String?,
        medicalNotes: existingProfile?['medicalNotes'] as String?,
      );

      final bool completed = DbService().isOnboarded(user.uid);

      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else {
        if (completed) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const PersonalizedQuestionnaireScreen()),
            (route) => false,
          );
        }
      }
    } else {
      SoundService.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account not found or password incorrect. Please check your credentials or click "Create Account".'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.canvasIvory,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Brain Cognitive Logo Image Asset
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.terracottaPrimary.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.psychology,
                        size: 80,
                        color: AppColors.terracottaPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Smriti Veda',
                  style: GoogleFonts.newsreader(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppColors.terracottaPrimary,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Personalized AI Cognitive Gaming & Memory Platform',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 15,
                    color: AppColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Main Login Form Card
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: AppColors.sandalwoodGold.withValues(alpha: 0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Credentials',
                          style: GoogleFonts.newsreader(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoalText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _credentialController,
                          style: GoogleFonts.atkinsonHyperlegible(fontSize: 16, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Credential ID / Username',
                            prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.terracottaPrimary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            filled: true,
                            fillColor: AppColors.canvasIvory,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: GoogleFonts.atkinsonHyperlegible(fontSize: 16, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.terracottaPrimary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: AppColors.secondaryText,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            filled: true,
                            fillColor: AppColors.canvasIvory,
                          ),
                        ),
                        const SizedBox(height: 24),

                        ElevatedButton(
                          onPressed: () => _handleLogin(appState),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.terracottaPrimary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Enter Memory Platform ➔',
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 4,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ForgotUsernameScreen()),
                                );
                              },
                              child: Text(
                                'Forgot Username?',
                                style: GoogleFonts.atkinsonHyperlegible(
                                  color: AppColors.sageSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.atkinsonHyperlegible(
                                  color: AppColors.terracottaPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                                );
                              },
                              child: Text(
                                'Create Account',
                                style: GoogleFonts.atkinsonHyperlegible(
                                  color: AppColors.charcoalText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: AppColors.borderSubtle),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            DbService().activateDemoMode();
                            appState.login(
                              name: 'Aditya Verma (Demo Profile)',
                              credentialId: 'uid_demo_sih',
                              role: 'Patient',
                              language: 'en',
                              age: 72,
                              emergencyContact: '+91 98765 43210',
                              medicalNotes: 'Demonstration profile for SIH evaluation.',
                            );
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const MainScreen()),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.stars, color: AppColors.sandalwoodGold, size: 18),
                          label: Text(
                            'Explore Demo Mode (SIH Presentation)',
                            style: GoogleFonts.atkinsonHyperlegible(
                              color: AppColors.terracottaPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
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
}
