import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state.dart';
import '../services/db_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Step 0: Welcome Screen with Pop-Out Logo Animation
  // Step 1: Authentication Choice Screen (CREATE ACCOUNT / LOG IN)
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Subtle scale pop-out from 85% to 100% with smooth easing
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Gentle fade-in
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _goToAuthScreen() {
    SoundService().playClickSound();
    setState(() {
      _currentStep = 1;
    });
  }

  void _goBackToWelcome() {
    SoundService().playTapSound();
    setState(() {
      _currentStep = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations ||
        MediaQuery.of(context).accessibleNavigation;

    if (disableAnimations && _animController.isAnimating) {
      _animController.value = 1.0;
    }

    return Scaffold(
      backgroundColor: AppColors.canvasIvory,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.05),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _currentStep == 0
                    ? _buildWelcomeStep(context)
                    : _buildAuthChoiceStep(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// STEP 1 & STEP 2: Pop-out logo animation + clean Welcome screen with ONE button (NEXT →)
  Widget _buildWelcomeStep(BuildContext context) {
    return Column(
      key: const ValueKey('step_welcome'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        // STEP 1 — POP-OUT LOGO ANIMATION CONTAINER
        ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.terracottaSoft,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.terracottaPrimary.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.psychology_rounded,
                  size: 52,
                  color: AppColors.terracottaPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // APP TITLE & TAGLINE (Fades in cleanly)
        FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Text(
                'SMRITIVEDA',
                style: GoogleFonts.newsreader(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.2,
                  color: AppColors.terracottaPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              Text(
                'Ancient wisdom. Modern memory care.',
                style: GoogleFonts.newsreader(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: AppColors.charcoalText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                'Personalized cognitive practice inspired by traditional learning and modern memory exercises.',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 16,
                  color: AppColors.secondaryText,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // DECORATIVE FEATURE PILLARS CARD
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.sandalwoodGold.withValues(alpha: 0.3),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x082D241C),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildFeatureRow(
                icon: Icons.psychology,
                iconColor: AppColors.terracottaPrimary,
                title: 'Universal Cognitive Memory',
                subtitle: 'Object, sequence & spatial recall exercises',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.borderSubtle),
              ),
              _buildFeatureRow(
                icon: Icons.record_voice_over,
                iconColor: AppColors.sageSecondary,
                title: 'Cultural & Oral Practice',
                subtitle: 'Voice recitation in Telugu, Hindi, Tamil & more',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.borderSubtle),
              ),
              _buildFeatureRow(
                icon: Icons.auto_awesome,
                iconColor: AppColors.sandalwoodGold,
                title: 'AI Personalized Memory Care',
                subtitle: 'Custom daily plan tailored to family memories & goals',
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // STEP 2 — ONE PRIMARY BUTTON: NEXT →
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _goToAuthScreen,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracottaPrimary,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'NEXT',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 22),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Designed for Seniors & Caregivers • Non-Devotional Memory Platform',
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// STEP 4: Authentication Choice Screen (CREATE ACCOUNT / LOG IN)
  Widget _buildAuthChoiceStep(BuildContext context) {
    return Column(
      key: const ValueKey('step_auth_choice'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Back Navigation Button
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _goBackToWelcome,
            icon: const Icon(Icons.arrow_back, color: AppColors.charcoalText, size: 20),
            label: Text(
              'Back',
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoalText,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Header Logo Icon
        Container(
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.terracottaSoft,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.terracottaPrimary.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/app_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.psychology_rounded,
              size: 40,
              color: AppColors.terracottaPrimary,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Screen Heading & Subheading
        Text(
          'Welcome to SmritiVeda',
          style: GoogleFonts.newsreader(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoalText,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        Text(
          'Start your personalized memory practice.',
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 16,
            color: AppColors.secondaryText,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 44),

        // PRIMARY BUTTON: CREATE ACCOUNT
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              SoundService().playClickSound();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignupScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracottaPrimary,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'CREATE ACCOUNT',
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // SECONDARY BUTTON: LOG IN
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () {
              SoundService().playClickSound();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.terracottaPrimary,
              side: const BorderSide(color: AppColors.terracottaPrimary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'LOG IN',
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // TERTIARY BUTTON: EXPLORE DEMO MODE (SIH PRESENTATION)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: TextButton.icon(
            onPressed: () {
              SoundService().playClickSound();
              DbService().activateDemoMode();
              final appState = AppStateScope.of(context);
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
            icon: const Icon(Icons.stars_rounded, color: AppColors.sandalwoodGold, size: 20),
            label: Text(
              'Explore Demo Mode (SIH Presentation)',
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.terracottaPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Privacy & Trust Footnote
        Text(
          'Protected & Private • Standard 8+ Char Password Criteria & Authentication Security',
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.newsreader(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoalText,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
