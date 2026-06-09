import 'package:flutter/material.dart';

// Widget que cria um overlay circular com furo transparente no centro
// Usado para ajudar o usuário a enquadrar o prato na câmera
class CircleOverlay extends StatelessWidget {
  final double circleDiameter; // Diâmetro do círculo transparente
  final double opacity; // Opacidade da área escurecida ao redor

  const CircleOverlay({
    super.key,
    this.circleDiameter = 300,
    this.opacity = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    // CustomPaint permite desenhar formas personalizadas na tela
    return CustomPaint(
      painter: CircleOverlayPainter( // Pintor personalizado que desenha o overlay
        circleDiameter: circleDiameter,
        opacity: opacity,
      ),
      child: Container(), // Container vazio que ocupatodo o espaço disponível
    );
  }
}

// Classe responsável por desenhar o overlay circular personalizado
// Implementa CustomPainter para definir como desenhar na tela
class CircleOverlayPainter extends CustomPainter {
  final double circleDiameter; // Diâmetro do círculo transparente
  final double opacity; // Opacidade da área escurecida

  CircleOverlayPainter({
    required this.circleDiameter,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calcula o centro da tela
    final center = Offset(size.width / 2, size.height / 2);
    // Calcula o raio baseado no diâmetro
    final radius = circleDiameter / 2;

    // Cria um caminho (Path) que cobre toda a tela (fundo escuro)
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Cria um caminho para o círculo transparente no centro
    final circlePath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));

    // Combina os paths: subtrai o círculo do fundo (cria um "buraco")
    final path = Path.combine(
      PathOperation.difference, // Operação de diferença (fundo - círculo)
      backgroundPath,
      circlePath,
    );

    // Calcula o valor alpha (transparência) baseado na opacidade
    // Converte de 0.0-1.0 para 0-255
    final alphaValue = (opacity * 255).round();

    // Configura a tinta para preencher a área escurecida
    final paint = Paint()
      ..color = Colors.black.withAlpha(alphaValue) // Preto com transparência
      ..style = PaintingStyle.fill; // Estilo de preenchimento

    // Desenha o caminho (área escurecida com buraco no centro)
    canvas.drawPath(path, paint);

    // Configura a tinta para desenhar a borda do círculo
    final borderPaint = Paint()
      ..color = Colors.white // Cor branca para a borda
      ..style = PaintingStyle.stroke // Estilo de contorno (não preenchido)
      ..strokeWidth = 3; // Espessura da borda: 3 pixels

    // Desenha o círculo branco (apenas a borda)
    canvas.drawCircle(center, radius, borderPaint);

    // Adiciona um "x" no centro para ajudar no enquadramento do prato
    final centerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5) // Branco semi-transparente
      ..strokeWidth = 2; // Espessura da linha: 2 pixels

    // Desenha a linha horizontal do "x"
    canvas.drawLine(
      Offset(center.dx - 15, center.dy), // Ponto inicial (esquerda)
      Offset(center.dx + 15, center.dy), // Ponto final (direita)
      centerPaint,
    );

    // Desenha a linha vertical do "x"
    canvas.drawLine(
      Offset(center.dx, center.dy - 15), // Ponto inicial (topo)
      Offset(center.dx, center.dy + 15), // Ponto final (base)
      centerPaint,
    );
  }

  @override
  // Metodo que determina quando redesenhar o overlay
  // Redesenha apenas se o diâmetro ou opacidade mudaram
  bool shouldRepaint(CircleOverlayPainter oldDelegate) =>
      circleDiameter != oldDelegate.circleDiameter ||
          opacity != oldDelegate.opacity;
}