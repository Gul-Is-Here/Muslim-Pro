// Draws the Noor app icon (the splash emblem, simplified for small sizes) and writes the 1024 px
// masters that tool/app_icon/make_icons.sh resizes into every Android and iOS slot.
// Run: flutter test tool/app_icon/app_icon_test.dart && tool/app_icon/make_icons.sh
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _side = 1024.0;
const _gold = Color(0xFFE4AA73);
const _mint = Color(0xFF6FFBBE);

enum _Layer { full, foreground, background, monochrome }

void main() {
  testWidgets('render app icon masters', (tester) async {
    await tester.runAsync(() async {
      final font = FontLoader('Amiri')
        ..addFont(
          Future.value(
            ByteData.sublistView(File('assets/fonts/Amiri-Regular.ttf').readAsBytesSync()),
          ),
        );
      await font.load();
      final out = Directory('build/app_icon')..createSync(recursive: true);
      for (final layer in _Layer.values) {
        final recorder = ui.PictureRecorder();
        _paint(Canvas(recorder), layer);
        final image = await recorder.endRecording().toImage(_side.toInt(), _side.toInt());
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('${out.path}/${layer.name}.png').writeAsBytesSync(png!.buffer.asUint8List());
      }
    });
  });
}

void _paint(Canvas canvas, _Layer layer) {
  const c = Offset(_side / 2, _side / 2);
  if (layer == _Layer.full || layer == _Layer.background) _background(canvas);
  if (layer == _Layer.background) return;
  // Adaptive-icon layers are 108 dp with a 66 dp safe circle; the full icon can fill more.
  final tip = layer == _Layer.full ? 335.0 : 262.0;
  _mark(canvas, c, tip, mono: layer == _Layer.monochrome);
}

void _background(Canvas canvas) {
  const rect = Rect.fromLTWH(0, 0, _side, _side);
  canvas
    ..drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E4A40), Color(0xFF07302A), Color(0xFF031A15)],
        ).createShader(rect),
    )
    // Soft light behind the star.
    ..drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [_mint.withValues(alpha: 0.16), _mint.withValues(alpha: 0)],
        ).createShader(rect),
    );
}

/// Eight-point star (gold and mint squares) around نُور; [tip] is the star's corner radius.
void _mark(Canvas canvas, Offset c, double tip, {required bool mono}) {
  final half = tip / math.sqrt2; // half side of each square
  final stroke = tip * 0.055;
  Path square(double turn) {
    final m = Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..rotateZ(turn);
    return (Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: half * 2, height: half * 2),
            Radius.circular(tip * 0.06),
          ),
        ))
        .transform(m.storage);
  }

  final star = Path.combine(PathOperation.union, square(0), square(math.pi / 4));
  final line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke
    ..strokeJoin = StrokeJoin.round;
  if (mono) {
    canvas.drawPath(star, line..color = Colors.white);
  } else {
    canvas
      ..drawPath(star, Paint()..color = const Color(0xFF052520))
      ..drawPath(square(math.pi / 4), Paint.from(line)..color = _mint.withValues(alpha: 0.6))
      ..drawPath(square(0), Paint.from(line)..color = _gold)
      ..drawCircle(
        c,
        tip * 0.6,
        Paint.from(line)
          ..strokeWidth = stroke * 0.45
          ..color = _gold.withValues(alpha: 0.55),
      );
  }

  final text = TextPainter(
    textDirection: TextDirection.rtl,
    text: TextSpan(
      text: 'نور', // no damma: at icon sizes it floats loose
      style: TextStyle(
        fontFamily: 'Amiri',
        fontSize: tip * 0.8,
        height: 1,
        fontWeight: FontWeight.w700,
        foreground: mono
            ? (Paint()..color = Colors.white)
            : (Paint()
                ..shader = ui.Gradient.linear(
                  c - Offset(0, tip * 0.3),
                  c + Offset(0, tip * 0.3),
                  const [Color(0xFFFFF6ED), Color(0xFFFFE3C6), _gold],
                  const [0, 0.5, 1],
                )),
      ),
    ),
  )..layout();
  // Amiri sits high in its line box; nudge down so the word looks centred in the star.
  text.paint(canvas, c - Offset(text.width / 2, text.height / 2 - tip * 0.07));
}
