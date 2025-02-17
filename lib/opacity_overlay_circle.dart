import 'package:flutter/material.dart';

class CircleOverlay extends StatelessWidget {
  final double circleDiameter;
  final double opacity;
  final Color overlayColor;

  const CircleOverlay({
    super.key,
    this.circleDiameter = 300,
    this.opacity = 0.7,
    this.overlayColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CircleOverlayPainter(
        circleDiameter: circleDiameter,
        opacity: opacity,
        overlayColor: overlayColor,
      ),
      child: Container(),
    );
  }
}

class CircleOverlayPainter extends CustomPainter {
  final double circleDiameter;
  final double opacity;
  final Color overlayColor;

  CircleOverlayPainter({
    required this.circleDiameter,
    required this.opacity,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = circleDiameter / 2;

    // Cria o path para todo o canvas
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Cria o path para o círculo
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    // Combina os paths usando o modo difference
    final path = Path.combine(
      PathOperation.difference,
      backgroundPath,
      circlePath,
    );

    // Calcula o valor alpha baseado na opacidade (0.0 - 1.0 para 0 - 255)
    final alphaValue = (opacity * 255).round();

    // Desenha o overlay com opacidade usando withAlpha
    final paint = Paint()
      ..color = overlayColor.withAlpha(alphaValue)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // Desenha a borda do círculo
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(CircleOverlayPainter oldDelegate) =>
      circleDiameter != oldDelegate.circleDiameter ||
          opacity != oldDelegate.opacity ||
          overlayColor != oldDelegate.overlayColor;
}