import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/core/utils/compass_math.dart';

double _rad(double deg) => deg * math.pi / 180;

/// Compass card: rings, degree ticks and N/E/S/W rotate with the device (north stays north);
/// a fixed notch at the top marks where the phone points.
final class CompassDialPainter extends CustomPainter {
  CompassDialPainter({required this.heading, required this.ring, required this.muted});

  final double heading;
  final Color ring;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas
      ..drawCircle(
        c,
        r - 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = ring,
      )
      ..save()
      ..translate(c.dx, c.dy)
      ..rotate(_rad(-heading));
    final tick = Paint()
      ..color = muted
      ..strokeCap = StrokeCap.round;
    for (var d = 0; d < 360; d += 5) {
      final major = d % 30 == 0;
      tick.strokeWidth = major ? 1.6 : 0.8;
      final a = _rad(d.toDouble());
      final outer = r - 8;
      final inner = outer - (major ? 10 : 5);
      canvas.drawLine(
        Offset(math.sin(a) * inner, -math.cos(a) * inner),
        Offset(math.sin(a) * outer, -math.cos(a) * outer),
        tick,
      );
    }
    for (final (deg, label) in [(0, 'N'), (90, 'E'), (180, 'S'), (270, 'W')]) {
      final a = _rad(deg.toDouble());
      final p = Offset(math.sin(a) * (r - 34), -math.cos(a) * (r - 34));
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: deg == 0 ? 15 : 12,
            fontWeight: FontWeight.w800,
            color: deg == 0 ? AppColors.amber600 : muted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas
        ..save()
        ..translate(p.dx, p.dy)
        ..rotate(a) // letters face outwards, like a printed compass card
        ..translate(-tp.width / 2, -tp.height / 2);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }
    canvas.restore();
    // Fixed lubber line: the direction the top of the phone points.
    final notch = Path()
      ..moveTo(c.dx, 4)
      ..lineTo(c.dx - 7, 18)
      ..lineTo(c.dx + 7, 18)
      ..close();
    canvas.drawPath(notch, Paint()..color = AppColors.primaryContainer);
  }

  @override
  bool shouldRepaint(CompassDialPainter old) =>
      old.heading != heading || old.ring != ring || old.muted != muted;
}

/// Horizontal heading tape for the camera view, centred on [heading]; the Qibla is marked.
final class HeadingRibbonPainter extends CustomPainter {
  HeadingRibbonPainter({required this.heading, required this.qibla});

  final double heading;
  final double? qibla;
  static const _span = 40.0; // degrees visible either side of centre

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final perDeg = size.width / (2 * _span);
    final start = ((heading - _span) / 5).ceil() * 5;
    for (var d = start; d <= heading + _span; d += 5) {
      final x = cx + (d - heading) * perDeg;
      final fade = 1 - ((d - heading).abs() / _span).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.25 + 0.6 * fade)
        ..strokeWidth = d % 15 == 0 ? 1.6 : 1;
      canvas.drawLine(
        Offset(x, size.height - (d % 15 == 0 ? 14 : 8)),
        Offset(x, size.height),
        paint,
      );
      if (d % 15 == 0 && (d - heading).abs() > 6) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${d % 360}°',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3 + 0.6 * fade),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, size.height - 32));
      }
    }
    final q = qibla;
    if (q != null) {
      final off = CompassMath.turn(heading, q);
      if (off.abs() <= _span) {
        final x = cx + off * perDeg;
        canvas.drawCircle(Offset(x, size.height - 4), 4, Paint()..color = AppColors.amber500);
      }
    }
  }

  @override
  bool shouldRepaint(HeadingRibbonPainter old) => old.heading != heading || old.qibla != qibla;
}
