import 'package:flutter/material.dart';
import 'dart:math';

class StarryBackground extends StatelessWidget {
  final Widget child;

  const StarryBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // This will ensure the stars are in the background
        Positioned.fill(
          child: CustomPaint(
            painter: StarryPainter(),
            size: Size.infinite,
            child: Container(),
          ),
        ),
        // Your main content will be displayed above the stars
        child,
      ],
    );
  }
}

class StarryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    canvas.drawRect(Offset.zero & size, Paint()..color = Color(0xFF3A4C7A));

    final Random random = Random(42); // Fixed seed for consistent star pattern
    int numStars = 100;

    for (int i = 0; i < numStars; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;

      Color starColor = Colors.grey[400]!;

      paint.color = starColor;
      paint.strokeWidth = 1;
      paint.style = PaintingStyle.fill;

      double radius = 1 + random.nextDouble() * 2;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
