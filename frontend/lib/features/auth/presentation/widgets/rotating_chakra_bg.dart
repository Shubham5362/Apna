import 'dart:math' as math;
import 'package:flutter/material.dart';

class RotatingChakraBg extends StatefulWidget {
  final double size;
  const RotatingChakraBg({super.key, this.size = 600});

  @override
  State<RotatingChakraBg> createState() => _RotatingChakraBgState();
}

class _RotatingChakraBgState extends State<RotatingChakraBg>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 60),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _ChakraPainter(),
          ),
        );
      },
    );
  }
}

class _ChakraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = const Color(0xFF000080).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Outer Circle
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.9, paint);

    // 24 Spokes
    for (int i = 0; i < 24; i++) {
      final angle = (i * 15) * math.pi / 180;
      final x2 = center.dx + radius * math.cos(angle);
      final y2 = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
