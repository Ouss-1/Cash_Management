import 'package:flutter/material.dart';
import '../utils/typography.dart';
import 'dart:math' as math;

class DottedProgressBar extends StatefulWidget {
  final double percentage; // 0.0 to 1.0
  final Color filledColor;
  final Color emptyColor;
  final double height;
  final int dotCount;
  final bool showPercentage;
  final String? label;

  const DottedProgressBar({
    Key? key,
    required this.percentage,
    this.filledColor = const Color(0xFF7B2CBF),
    this.emptyColor = const Color(0xFF404040),
    this.height = 24.0,
    this.dotCount = 40,
    this.showPercentage = true,
    this.label,
  }) : super(key: key);

  @override
  State<DottedProgressBar> createState() => _DottedProgressBarState();
}

class _DottedProgressBarState extends State<DottedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: widget.percentage).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(DottedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.percentage,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null || widget.showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: AppTypography.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (widget.showPercentage)
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Text(
                        '${(_animation.value * 100).toInt()}%',
                        style: AppTypography.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.filledColor,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        SizedBox(
          height: widget.height,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final dotWidth = (constraints.maxWidth / widget.dotCount);
                  final filledDots = (widget.dotCount * _animation.value).round();

                  return Row(
                    children: List.generate(widget.dotCount, (index) {
                      final isFilled = index < filledDots;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 2.5, // Fixed gap for consistent segmented look
                          ),
                          decoration: BoxDecoration(
                            color: isFilled ? widget.filledColor : widget.emptyColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4), // More rounded segments
                          ),
                        ),
                      );
                    }),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class CircularDottedProgress extends StatefulWidget {
  final double percentage;
  final Color filledColor;
  final Color emptyColor;
  final double size;
  final int dotCount;
  final Widget? center;

  const CircularDottedProgress({
    Key? key,
    required this.percentage,
    this.filledColor = const Color(0xFF7B2CBF),
    this.emptyColor = const Color(0xFF404040),
    this.size = 120.0,
    this.dotCount = 24,
    this.center,
  }) : super(key: key);

  @override
  State<CircularDottedProgress> createState() => _CircularDottedProgressState();
}

class _CircularDottedProgressState extends State<CircularDottedProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: widget.percentage).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CircularDottedPainter(
                  percentage: _animation.value,
                  filledColor: widget.filledColor,
                  emptyColor: widget.emptyColor,
                  dotCount: widget.dotCount,
                ),
              );
            },
          ),
          if (widget.center != null) widget.center!,
        ],
      ),
    );
  }
}

class _CircularDottedPainter extends CustomPainter {
  final double percentage;
  final Color filledColor;
  final Color emptyColor;
  final int dotCount;

  _CircularDottedPainter({
    required this.percentage,
    required this.filledColor,
    required this.emptyColor,
    required this.dotCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final dotSize = 4.0;
    final filledDots = (dotCount * percentage).round();

    for (int i = 0; i < dotCount; i++) {
      final angle = (i * 360 / dotCount - 90) * 3.14159 / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      final paint = Paint()
        ..color = i < filledDots ? filledColor : emptyColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), dotSize, paint);
    }
  }

  @override
  bool shouldRepaint(_CircularDottedPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.filledColor != filledColor ||
        oldDelegate.emptyColor != emptyColor ||
        oldDelegate.dotCount != dotCount;
  }
}
