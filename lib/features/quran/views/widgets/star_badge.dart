import 'dart:math';

import 'package:flutter/material.dart';

/// Rub el Hizb: two overlapping squares, the eight-point star used to number surahs.
final class StarBadge extends StatelessWidget {
  const StarBadge({required this.label, required this.color, this.size = 40, super.key});

  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: StarPainter(color.withValues(alpha: 0.14), stroke: color.withValues(alpha: 0.35)),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: label.length > 2 ? 11 : 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    ),
  );
}

final class StarPainter extends CustomPainter {
  const StarPainter(this.fill, {this.stroke});

  final Color fill;
  final Color? stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 * 0.86;
    final path = Path();
    for (final turn in const [0.0, pi / 4]) {
      path.addPolygon([
        for (var i = 0; i < 4; i++) c + Offset.fromDirection(turn + pi / 4 + i * pi / 2, r),
      ], true);
    }
    canvas.drawPath(path, Paint()..color = fill);
    if (stroke != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = stroke!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(StarPainter old) => old.fill != fill || old.stroke != stroke;
}
