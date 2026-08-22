import 'package:flutter/material.dart';

import '../theme.dart';

/// Avatar rond du conseiller, repris du bouton « Discuter avec un agent ».
class AvatarAgent extends StatelessWidget {
  const AvatarAgent({super.key, this.taille = 84});

  final double taille;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: taille,
      height: taille,
      child: CustomPaint(painter: _PeintreAgent()),
    );
  }
}

class _PeintreAgent extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final p = Paint()..isAntiAlias = true;

    // Fond orange
    p.color = Palette.orange;
    canvas.drawCircle(Offset(50 * s, 50 * s), 50 * s, p);

    // Buste blanc
    p.color = Colors.white;
    final buste = Path()
      ..moveTo(28 * s, 100 * s)
      ..cubicTo(30 * s, 82 * s, 39 * s, 72 * s, 50 * s, 72 * s)
      ..cubicTo(61 * s, 72 * s, 70 * s, 82 * s, 72 * s, 100 * s)
      ..close();
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: Offset(50 * s, 50 * s), radius: 50 * s)),
    );
    canvas.drawPath(buste, p);
    canvas.restore();

    // Visage
    p.color = const Color(0xFFF7D3B5);
    canvas.drawCircle(Offset(50 * s, 42 * s), 19 * s, p);

    // Cheveux
    p.color = const Color(0xFF3F4A52);
    final cheveux = Path()
      ..moveTo(50 * s, 22 * s)
      ..cubicTo(59 * s, 22 * s, 66 * s, 28 * s, 66 * s, 36 * s)
      ..lineTo(34 * s, 36 * s)
      ..cubicTo(34 * s, 28 * s, 41 * s, 22 * s, 50 * s, 22 * s)
      ..close();
    canvas.drawPath(cheveux, p);

    // Casque
    p.color = const Color(0xFF5B6BD6);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 4 * s;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(50 * s, 41 * s), radius: 20 * s),
      3.14159,
      3.14159,
      false,
      p,
    );
    p.style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(26 * s, 38 * s, 8 * s, 14 * s),
        Radius.circular(4 * s),
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(66 * s, 38 * s, 8 * s, 14 * s),
        Radius.circular(4 * s),
      ),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Illustration « TAX » des écrans de connexion et d'inscription.
class IllustrationTax extends StatelessWidget {
  const IllustrationTax({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        // Le fond suit le thème : un gris clair en mode clair, un gris chaud
        // sombre sinon — sans quoi ce bandeau resterait une tache claire.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.cl.sombre
              ? const [Color(0xFF2A2521), Color(0xFF1C1917)]
              : const [Color(0xFFDFE2E5), Color(0xFFCFD3D7)],
        ),
      ),
      child: CustomPaint(painter: _PeintreTax()),
    );
  }
}

class _PeintreTax extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    // Repère : dessin conçu sur 300 × 220, ajusté à la taille réelle.
    final s = size.width / 300;
    canvas.save();
    canvas.scale(s);
    final h = size.height / s;

    // Quadrillage de fond
    p
      ..color = const Color(0x33B9BFC5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i * 26 < h; i++) {
      canvas.drawLine(Offset(0, i * 26), Offset(300, i * 26), p);
    }
    for (var i = 0; i < 12; i++) {
      canvas.drawLine(Offset(i * 26, 0), Offset(i * 26, h), p);
    }
    p.style = PaintingStyle.fill;

    // Feuille d'impôt
    canvas.save();
    canvas.translate(96, 14);
    p.color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 118, 132),
        const Radius.circular(4),
      ),
      p,
    );
    final tp = TextPainter(
      text: const TextSpan(
        text: 'TAX',
        style: TextStyle(
          color: Color(0xFF2B3A4A),
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(46, 14));

    p
      ..color = const Color(0xFF5B9BD5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(58, 52), const Offset(104, 52), p);
    canvas.drawLine(const Offset(58, 64), const Offset(104, 64), p);
    canvas.drawLine(const Offset(58, 76), const Offset(96, 76), p);
    canvas.drawLine(const Offset(14, 112), const Offset(104, 112), p);
    canvas.drawLine(const Offset(14, 122), const Offset(80, 122), p);
    p.style = PaintingStyle.fill;

    // Camembert
    p.color = const Color(0xFFF5F7F9);
    canvas.drawCircle(const Offset(32, 70), 20, p);
    p.color = const Color(0xFF5B9BD5);
    canvas.drawArc(
      const Rect.fromLTWH(12, 50, 40, 40),
      -1.5708,
      2.2,
      true,
      p,
    );
    p.color = const Color(0xFFF5A623);
    canvas.drawArc(
      const Rect.fromLTWH(12, 50, 40, 40),
      0.7,
      1.9,
      true,
      p,
    );
    canvas.restore();

    // Loupe
    canvas.save();
    canvas.translate(18, 16);
    p.color = const Color(0xFFDFF0FB);
    canvas.drawCircle(const Offset(34, 34), 26, p);
    p
      ..color = const Color(0xFF2B3A4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(const Offset(34, 34), 26, p);
    p
      ..style = PaintingStyle.fill
      ..strokeWidth = 1;
    canvas.save();
    canvas.translate(16, 56);
    canvas.rotate(0.66);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-8, 0, 16, 40),
        const Radius.circular(8),
      ),
      p,
    );
    canvas.restore();
    canvas.restore();

    // Réveil
    canvas.save();
    canvas.translate(24, 126);
    p.color = const Color(0xFFDFF0FB);
    canvas.drawCircle(const Offset(34, 34), 30, p);
    p
      ..color = const Color(0xFF3A6EA5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(const Offset(34, 34), 30, p);
    p.style = PaintingStyle.fill;
    p.color = Colors.white;
    canvas.drawCircle(const Offset(34, 34), 23, p);
    p
      ..color = const Color(0xFF2B3A4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(34, 34), const Offset(34, 19), p);
    canvas.drawLine(const Offset(34, 34), const Offset(45, 41), p);
    p.style = PaintingStyle.fill;
    canvas.restore();

    // Billets
    canvas.save();
    canvas.translate(104, 148);
    for (final (i, c) in const <Color>[
      Color(0xFF2F9E63),
      Color(0xFF4CBD7D),
      Color(0xFF6FD196),
    ].indexed) {
      p.color = c;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 14 - i * 8, 86, 34),
          const Radius.circular(3),
        ),
        p,
      );
    }
    canvas.restore();

    // Pièces
    canvas.save();
    canvas.translate(206, 92);
    for (var i = 0; i < 4; i++) {
      p.color = i.isEven ? const Color(0xFFF7C948) : const Color(0xFFF0B429);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(34, 64 - i * 10),
          width: 60,
          height: 22,
        ),
        p,
      );
    }
    p.color = const Color(0xFFF7C948);
    canvas.drawCircle(const Offset(76, 46), 20, p);
    p
      ..color = const Color(0xFFD99E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(const Offset(76, 46), 20, p);
    p.style = PaintingStyle.fill;
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
