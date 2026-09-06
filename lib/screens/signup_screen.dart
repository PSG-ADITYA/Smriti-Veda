import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'personalized_questionnaire_screen.dart';
import '../utils/validation_utils.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'Patient'; // 'Patient' or 'Caregiver'
  String _selectedLanguage = 'hi';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await AuthService().signUp(
      name: name,
      email: email,
      password: password,
      role: _selectedRole,
      language: _selectedLanguage,
    );

    if (mounted) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() => _isLoading = false);
      if (success) {
        final newUid = AuthService().currentUser?.uid ?? 'uid_new';
        // Explicitly mark newly created account as not yet onboarded
        DbService().setOnboarded(false, newUid);

        final appState = AppStateScope.of(context);
        appState.login(
          name: name,
          credentialId: newUid,
          role: _selectedRole,
          language: _selectedLanguage,
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PersonalizedQuestionnaireScreen()),
          (route) => false,
        );
      } else {
        SoundService.playError();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Account Already Exists',
                  style: GoogleFonts.newsreader(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoalText,
                  ),
                ),
              ],
            ),
            content: Text(
              'An account with email "$email" is already registered in Smriti Veda.\n\nPlease log in with your existing credentials or use Forgot Password / Forgot Username if needed.',
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 14,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.pop(context);
                },
                child: const Text('Try Different Email'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracottaPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text('Go to Log In ➔'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Create Account',
          style: GoogleFonts.newsreader(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.terracottaPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Join SmritiVeda',
                      style: GoogleFonts.newsreader(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoalText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Set up your profile to start personalized cognitive memory practice.',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 14,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Role Selection
                    Text(
                      'ACCOUNT TYPE',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.terracottaPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: SizedBox(
                              width: double.infinity,
                              child: Text(
                                '👴 Senior Patient',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedRole == 'Patient' ? Colors.white : AppColors.charcoalText,
                                ),
                              ),
                            ),
                            selected: _selectedRole == 'Patient',
                            selectedColor: AppColors.terracottaPrimary,
                            backgroundColor: Colors.white,
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedRole = 'Patient');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: SizedBox(
                              width: double.infinity,
                              child: Text(
                                '🩺 Caregiver / Doctor',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedRole == 'Caregiver' ? Colors.white : AppColors.charcoalText,
                                ),
                              ),
                            ),
                            selected: _selectedRole == 'Caregiver',
                            selectedColor: AppColors.terracottaPrimary,
                            backgroundColor: Colors.white,
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedRole = 'Caregiver');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Full Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        hintText: _selectedRole == 'Patient' ? 'e.g. Ramesh Kumar' : 'e.g. Dr. Priya Sharma',
                        prefixIcon: const Icon(Icons.person_outline, color: AppColors.terracottaPrimary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'name@example.com',
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.terracottaPrimary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty || !value.contains('@')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Language Selector Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedLanguage,
                      decoration: InputDecoration(
                        labelText: 'Preferred Language for Recitation',
                        prefixIcon: const Icon(Icons.translate, color: AppColors.sageSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'hi', child: Text('🇮🇳 Hindi')),
                        DropdownMenuItem(value: 'te', child: Text('🇮🇳 Telugu')),
                        DropdownMenuItem(value: 'ta', child: Text('🇮🇳 Tamil')),
                        DropdownMenuItem(value: 'as', child: Text('🇮🇳 Assamese')),
                        DropdownMenuItem(value: 'bn', child: Text('🇮🇳 Bengali')),
                        DropdownMenuItem(value: 'en', child: Text('🏡 English / Family Memory')),
                        DropdownMenuItem(value: 'sa', child: Text('📜 Sanskrit Traditional')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedLanguage = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'e.g. Pass@1234',
                        helperText: 'Must contain min 8 chars, A-Z, a-z, 0-9 & special symbol (!@#\$%^&*)',
                        helperMaxLines: 2,
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.terracottaPrimary),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: ValidationUtils.validatePassword,
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_reset, color: AppColors.terracottaPrimary),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracottaPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Complete Sign Up',
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
