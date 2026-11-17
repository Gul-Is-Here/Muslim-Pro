import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Faint eight-point-star lattice (two overlapping squares per cell) for dark jewel surfaces.
final class StarLattice extends StatelessWidget {
  const StarLattice({this.cell = 64, this.opacity = 0.05, super.key});

  final double cell;
  final double opacity;

  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(child: CustomPaint(painter: _LatticePainter(cell, opacity)));
}

final class _LatticePainter extends CustomPainter {
  const _LatticePainter(this.cell, this.opacity);

  final double cell;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: opacity);
    for (var y = 0.0; y < size.height + cell; y += cell) {
      for (var x = 0.0; x < size.width + cell; x += cell) {
        final c = Offset(x, y);
        for (final turn in const [0.0, math.pi / 4]) {
          canvas.drawPath(
            Path()..addPolygon([
              for (var i = 0; i < 4; i++)
                c + Offset.fromDirection(turn + math.pi / 4 + i * math.pi / 2, cell * 0.42),
            ], true),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_LatticePainter old) => old.cell != cell || old.opacity != opacity;
}
