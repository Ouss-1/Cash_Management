import 'package:flutter/material.dart';
import 'dart:math' as math;

class DottedPatternPainter extends CustomPainter {
  final Color color;
  final double dotSize;
  final double spacing;
  final bool isDiamond;

  DottedPatternPainter({
    this.color = Colors.white,
    this.dotSize = 2.0,
    this.spacing = 8.0,
    this.isDiamond = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Create diamond/halftone pattern
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxDistance = math.sqrt(centerX * centerX + centerY * centerY);

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Calculate distance from center for gradient effect
        final dx = x - centerX;
        final dy = y - centerY;
        final distance = math.sqrt(dx * dx + dy * dy);
        final distanceRatio = (maxDistance - distance) / maxDistance;

        // Size dots based on distance (halftone effect)
        final currentDotSize = dotSize * distanceRatio;

        if (currentDotSize > 0.5) {
          paint.color = color.withOpacity(distanceRatio.clamp(0.1, 0.4));

          if (isDiamond) {
            // Draw diamond/square rotated 45 degrees
            final path = Path();
            path.moveTo(x, y - currentDotSize);
            path.lineTo(x + currentDotSize, y);
            path.lineTo(x, y + currentDotSize);
            path.lineTo(x - currentDotSize, y);
            path.close();
            canvas.drawPath(path, paint);
          } else {
            // Draw circle
            canvas.drawCircle(
              Offset(x, y),
              currentDotSize,
              paint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(DottedPatternPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dotSize != dotSize ||
        oldDelegate.spacing != spacing ||
        oldDelegate.isDiamond != isDiamond;
  }
}

class DottedPatternBackground extends StatelessWidget {
  final Widget child;
  final Color dotColor;
  final double dotSize;
  final double spacing;
  final bool isDiamond;

  const DottedPatternBackground({
    Key? key,
    required this.child,
    this.dotColor = Colors.white,
    this.dotSize = 2.0,
    this.spacing = 8.0,
    this.isDiamond = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: DottedPatternPainter(
              color: dotColor,
              dotSize: dotSize,
              spacing: spacing,
              isDiamond: isDiamond,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
