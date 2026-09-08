import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class Dice3DWidget extends StatelessWidget {
  final int value;
  final bool isFaceUp;
  final double size;
  final double tiltX;
  final double tiltY;
  final double rotationZ;
  final VoidCallback? onTap;
  final bool isHighlighted;

  const Dice3DWidget({
    super.key,
    required this.value,
    this.isFaceUp = true,
    this.size = 64.0,
    this.tiltX = 0.15,
    this.tiltY = -0.12,
    this.rotationZ = 0.05,
    this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0015)
      ..rotateX(tiltX)
      ..rotateY(tiltY)
      ..rotateZ(rotationZ);

    return GestureDetector(
      onTap: onTap,
      child: Transform(
        transform: matrix,
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isFaceUp ? const Color(0xFFFAF8F5) : AppColors.surfaceCream,
            borderRadius: BorderRadius.circular(size * 0.22),
            border: Border.all(
              color: isHighlighted
                  ? AppColors.terracottaPrimary
                  : (isFaceUp ? const Color(0xFFD4C8B8) : AppColors.sandalwoodGold),
              width: isHighlighted ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x28000000),
                blurRadius: 10,
                offset: const Offset(3, 7),
              ),
              BoxShadow(
                color: AppColors.sandalwoodGold.withValues(alpha: 0.2),
                blurRadius: 3,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: isFaceUp ? _buildPips() : _buildHiddenFace(),
        ),
      ),
    );
  }

  Widget _buildHiddenFace() {
    return Center(
      child: Container(
        width: size * 0.72,
        height: size * 0.72,
        decoration: BoxDecoration(
          color: AppColors.terracottaSoft.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(size * 0.15),
          border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.5)),
        ),
        child: Center(
          child: Text(
            '?',
            style: GoogleFonts.newsreader(
              fontSize: size * 0.42,
              fontWeight: FontWeight.bold,
              color: AppColors.terracottaPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPips() {
    final pipSize = size * 0.18;
    return CustomPaint(
      size: Size(size, size),
      painter: _DicePipPainter(value: value, pipSize: pipSize),
    );
  }
}

class _DicePipPainter extends CustomPainter {
  final int value;
  final double pipSize;

  _DicePipPainter({required this.value, required this.pipSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2C2520)
      ..style = PaintingStyle.fill;

    // Inset positions
    final left = size.width * 0.24;
    final center = size.width * 0.5;
    final right = size.width * 0.76;
    final top = size.height * 0.24;
    final middle = size.height * 0.5;
    final bottom = size.height * 0.76;
    final radius = pipSize / 2;

    void drawDot(double x, double y) {
      canvas.drawCircle(Offset(x, y), radius, paint);
      // Subtle 3D pip highlight
      final highlight = Paint()
        ..color = const Color(0x33FFFFFF)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x - radius * 0.2, y - radius * 0.2), radius * 0.4, highlight);
    }

    switch (value) {
      case 1:
        drawDot(center, middle);
        break;
      case 2:
        drawDot(left, top);
        drawDot(right, bottom);
        break;
      case 3:
        drawDot(left, top);
        drawDot(center, middle);
        drawDot(right, bottom);
        break;
      case 4:
        drawDot(left, top);
        drawDot(right, top);
        drawDot(left, bottom);
        drawDot(right, bottom);
        break;
      case 5:
        drawDot(left, top);
        drawDot(right, top);
        drawDot(center, middle);
        drawDot(left, bottom);
        drawDot(right, bottom);
        break;
      case 6:
        drawDot(left, top);
        drawDot(right, top);
        drawDot(left, middle);
        drawDot(right, middle);
        drawDot(left, bottom);
        drawDot(right, bottom);
        break;
      default:
        drawDot(center, middle);
    }
  }

  @override
  bool shouldRepaint(covariant _DicePipPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.pipSize != pipSize;
  }
}
