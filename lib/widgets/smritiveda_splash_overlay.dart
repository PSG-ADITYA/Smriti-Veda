import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

/// Level 3 Interactive App-Start Pop-Up Animation for SmritiVeda
class SmritiVedaSplashOverlay extends StatefulWidget {
  final Widget child;
  final Duration autoHideDuration;

  const SmritiVedaSplashOverlay({
    super.key,
    required this.child,
    this.autoHideDuration = const Duration(milliseconds: 2200),
  });

  @override
  State<SmritiVedaSplashOverlay> createState() => _SmritiVedaSplashOverlayState();
}

class _SmritiVedaSplashOverlayState extends State<SmritiVedaSplashOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _auraAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _overlayFadeAnimation;

  bool _isSplashVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Elastic pop-in scale for logo mark (small -> scales up -> settles)
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.10, 0.65, curve: Curves.easeOutBack),
    );

    // Fade-in opacity
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.05, 0.45, curve: Curves.easeIn),
    );

    // Glowing aura expansion
    _auraAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.70, curve: Curves.easeOutCubic),
    );

    // Slide up text reveal
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    // Overlay dissolve fade out at the end
    _overlayFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.82, 1.0, curve: Curves.easeInOut),
      ),
    );

    _startSplashSequence();
  }

  void _startSplashSequence() {
    _controller.forward();

    // Play harmonious welcome audio sound at 300ms
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        SoundService.playSuccess();
      }
    });

    // Complete splash overlay after duration
    Timer(widget.autoHideDuration, () {
      if (mounted) {
        setState(() => _isSplashVisible = false);
      }
    });
  }

  void _skipSplash() {
    if (_isSplashVisible) {
      SoundService().playTapSound();
      setState(() => _isSplashVisible = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations ||
        MediaQuery.of(context).accessibleNavigation;

    if (disableAnimations && _isSplashVisible) {
      return widget.child;
    }

    return Stack(
      children: [
        // Main App Content
        widget.child,

        // Pop-In Splash Overlay Screen
        if (_isSplashVisible)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return FadeTransition(
                opacity: _overlayFadeAnimation,
                child: GestureDetector(
                  onTap: _skipSplash,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: AppColors.canvasIvory,
                    child: SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Radiant Glowing Aura & Pop-In Logo Container
                              AnimatedBuilder(
                                animation: _auraAnimation,
                                builder: (context, child) {
                                  return Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.terracottaSoft.withValues(alpha: 0.85),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.terracottaPrimary.withValues(
                                              alpha: 0.25 * _auraAnimation.value),
                                          blurRadius: 36 * _auraAnimation.value,
                                          spreadRadius: 8 * _auraAnimation.value,
                                        ),
                                        BoxShadow(
                                          color: AppColors.sandalwoodGold.withValues(
                                              alpha: 0.20 * _auraAnimation.value),
                                          blurRadius: 54 * _auraAnimation.value,
                                          spreadRadius: 16 * _auraAnimation.value,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: ScaleTransition(
                                        scale: _scaleAnimation,
                                        child: FadeTransition(
                                          opacity: _fadeAnimation,
                                          child: Image.asset(
                                            'assets/images/app_logo.png',
                                            width: 72,
                                            height: 72,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => const Icon(
                                              Icons.psychology_rounded,
                                              size: 64,
                                              color: AppColors.terracottaPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 32),

                              // Animated Title & Tagline Reveal
                              SlideTransition(
                                position: _textSlideAnimation,
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Column(
                                    children: [
                                      Text(
                                        'SMRITIVEDA',
                                        style: GoogleFonts.newsreader(
                                          fontSize: 38,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 3.0,
                                          color: AppColors.terracottaPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Ancient wisdom. Modern memory care.',
                                        style: GoogleFonts.newsreader(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          fontStyle: FontStyle.italic,
                                          color: AppColors.charcoalText,
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Gentle pulse badge indicator
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: AppColors.sandalwoodGold.withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Text(
                                          'Cognitive Memory Platform',
                                          style: GoogleFonts.atkinsonHyperlegible(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.sageSecondary,
                                            letterSpacing: 0.8,
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
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
