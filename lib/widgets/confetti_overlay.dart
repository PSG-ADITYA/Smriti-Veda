import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class ConfettiOverlay extends StatefulWidget {
  final Widget child;

  const ConfettiOverlay({super.key, required this.child});

  static ConfettiOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<ConfettiOverlayState>();
  }

  static void show(
    BuildContext context, {
    String title = 'Congratulations! 🎉',
    String subtitle = 'Great job completing your cognitive exercise!',
  }) {
    of(context)?.triggerCelebration(title: title, subtitle: subtitle);
  }

  @override
  State<ConfettiOverlay> createState() => ConfettiOverlayState();
}

class ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  bool _isPlaying = false;
  String _celebrationTitle = 'Congratulations!';
  String _celebrationSubtitle = 'You completed the exercise!';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        if (_isPlaying) {
          setState(() {
            for (var p in _particles) {
              p.update();
            }
          });
        }
      });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isPlaying = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void triggerCelebration({
    String title = 'Congratulations! 🎉',
    String subtitle = 'Outstanding performance in your cognitive exercise!',
  }) {
    SoundService().playFanfareSound();
    SoundService().speakText('$title $subtitle');

    final random = Random();
    _particles.clear();
    const colors = [
      AppColors.terracottaPrimary,
      AppColors.sageSecondary,
      AppColors.sandalwoodGold,
      Colors.amber,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.cyan,
      Colors.lightGreenAccent,
    ];

    for (int i = 0; i < 90; i++) {
      _particles.add(
        _ConfettiParticle(
          x: random.nextDouble(),
          y: -random.nextDouble() * 0.4,
          speedY: 0.005 + random.nextDouble() * 0.012,
          speedX: (random.nextDouble() - 0.5) * 0.008,
          size: 6 + random.nextDouble() * 10,
          color: colors[random.nextInt(colors.length)],
          rotation: random.nextDouble() * 2 * pi,
          rotationSpeed: (random.nextDouble() - 0.5) * 0.2,
          isCircle: random.nextBool(),
        ),
      );
    }

    setState(() {
      _celebrationTitle = title;
      _celebrationSubtitle = subtitle;
      _isPlaying = true;
    });

    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isPlaying)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(particles: _particles),
              ),
            ),
          ),
        if (_isPlaying)
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.terracottaPrimary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: AppColors.sandalwoodGold, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('🎉 ', style: TextStyle(fontSize: 28)),
                        Text('✨ ', style: TextStyle(fontSize: 28)),
                        Text('🌟 ', style: TextStyle(fontSize: 28)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _celebrationTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.newsreader(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.terracottaPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _celebrationSubtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 16,
                        color: AppColors.charcoalText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  double x;
  double y;
  double speedY;
  double speedX;
  double size;
  Color color;
  double rotation;
  double rotationSpeed;
  bool isCircle;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.speedY,
    required this.speedX,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.isCircle,
  });

  void update() {
    y += speedY;
    x += speedX;
    rotation += rotationSpeed;
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()..color = p.color;
      final px = p.x * size.width;
      final py = p.y * size.height;

      if (py > 0 && py < size.height && px > 0 && px < size.width) {
        canvas.save();
        canvas.translate(px, py);
        canvas.rotate(p.rotation);

        if (p.isCircle) {
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
        } else {
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
            paint,
          );
        }
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
