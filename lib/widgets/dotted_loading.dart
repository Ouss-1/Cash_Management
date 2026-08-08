import 'package:flutter/material.dart';
import 'dart:math' as math;

class DottedLoading extends StatefulWidget {
  final Color color;
  final double size;
  final int dotCount;

  const DottedLoading({
    Key? key,
    this.color = const Color(0xFF7B2CBF),
    this.size = 40.0,
    this.dotCount = 5,
  }) : super(key: key);

  @override
  State<DottedLoading> createState() => _DottedLoadingState();
}

class _DottedLoadingState extends State<DottedLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 3,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(widget.dotCount, (index) {
              // Create wave effect
              final delay = index * 0.2;
              final animValue = (_controller.value + delay) % 1.0;
              final scale = math.sin(animValue * math.pi);

              return Transform.scale(
                scale: 0.5 + (scale * 0.5),
                child: Container(
                  width: widget.size / widget.dotCount,
                  height: widget.size / widget.dotCount,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.5 + (scale * 0.5)),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class DottedSquareLoading extends StatefulWidget {
  final Color color;
  final double size;

  const DottedSquareLoading({
    Key? key,
    this.color = const Color(0xFF7B2CBF),
    this.size = 60.0,
  }) : super(key: key);

  @override
  State<DottedSquareLoading> createState() => _DottedSquareLoadingState();
}

class _DottedSquareLoadingState extends State<DottedSquareLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _DottedSquareLoadingPainter(
              animationValue: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _DottedSquareLoadingPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _DottedSquareLoadingPainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dotSize = size.width / 8;
    final spacing = size.width / 6;
    final rows = 3;
    final cols = 8;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final x = col * spacing;
        final y = row * spacing + size.height / 4;

        // Calculate fill based on animation
        final progress = (animationValue + (col / cols)) % 1.0;
        final opacity = math.sin(progress * math.pi);

        final paint = Paint()
          ..color = color.withOpacity(opacity.clamp(0.2, 1.0))
          ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x + dotSize, y),
            width: dotSize * 0.8,
            height: dotSize * 0.8,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DottedSquareLoadingPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color;
  }
}
