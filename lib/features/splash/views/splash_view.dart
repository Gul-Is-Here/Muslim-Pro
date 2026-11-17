import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/features/splash/viewmodels/splash_view_model.dart';

// Night palette for the splash only; the native launch screen uses _top too, so there is no flash.
const _top = Color(0xFF092C24);
const _mid = Color(0xFF061C17);
const _ink = Color(0xFF03100D);
const _gold = Color(0xFFFFDCC3);
const _sage = Color(0xFF9CD1C7);
const Color _mint = AppColors.mint;

/// Brand mark over slowly turning geometry. Pure presentation: [SplashViewModel] decides when to
/// leave.
final class SplashView extends GetView<SplashViewModel> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) => const AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(backgroundColor: _ink, body: _Splash()),
  );
}

final class _Splash extends StatefulWidget {
  const _Splash();

  @override
  State<_Splash> createState() => _SplashState();
}

final class _SplashState extends State<_Splash> with TickerProviderStateMixin {
  // One slow turn every 80 s; the inner ring runs backwards at a different speed.
  late final _spin = AnimationController(vsync: this, duration: const Duration(seconds: 80));
  late final _breathe = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  late final _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
    ..forward();
  late final _shimmer = AnimationController(vsync: this, duration: const Duration(seconds: 2));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect "remove animations": keep the entrance, drop the loops.
    if (MediaQuery.disableAnimationsOf(context)) {
      _spin.stop();
      _breathe.stop();
      _shimmer.stop();
    } else if (!_spin.isAnimating) {
      _spin.repeat();
      _breathe.repeat(reverse: true);
      _shimmer.repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _breathe.dispose();
    _intro.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  /// Fades and lifts [child] in during [start]..[end] of the entrance.
  Widget _enter(double start, double end, Widget child) {
    final a = CurvedAnimation(
      parent: _intro,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(a),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_top, _mid, _ink],
      ),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        // Auras: mint behind the emblem, a warmer touch below it.
        const Positioned.fill(child: _Glow(Alignment(0, -0.55), 0.75, Color(0x2610B981))),
        const Positioned.fill(child: _Glow(Alignment(0, -0.3), 0.45, Color(0x1AFBBF24))),
        const Positioned.fill(child: CustomPaint(painter: _StarsPainter())),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 3),
                // Watermark geometry shares the emblem's centre; drawn bigger than the emblem.
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Painted at full size around the emblem's box, outside its bounds.
                    RotationTransition(
                      turns: _spin,
                      child: const CustomPaint(size: Size.square(176), painter: _MandalaPainter()),
                    ),
                    RotationTransition(
                      turns: Tween<double>(begin: 0, end: -0.94).animate(_spin),
                      child: const CustomPaint(size: Size.square(176), painter: _RingsPainter()),
                    ),
                    FadeTransition(
                      opacity: CurvedAnimation(parent: _intro, curve: const Interval(0, 0.5)),
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.86, end: 1).animate(
                          CurvedAnimation(
                            parent: _intro,
                            curve: const Interval(0, 0.6, curve: Curves.easeOutBack),
                          ),
                        ),
                        child: _Emblem(breathe: _breathe),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _enter(0.25, 0.65, const _Wordmark()),
                const SizedBox(height: 6),
                _enter(
                  0.35,
                  0.75,
                  Text(
                    'نُورٌ لِلْقُلُوبِ • زَادُ الْمُؤْمِنِ وَسَكِينَتُهُ',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 19,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber200.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _enter(0.45, 0.85, const _Tagline()),
                const SizedBox(height: 16),
                _enter(0.55, 0.95, const _Features()),
                const Spacer(flex: 4),
                _enter(0.7, 1, _Footer(shimmer: _shimmer)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

final class _Glow extends StatelessWidget {
  const _Glow(this.center, this.radius, this.color);

  final Alignment center;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: center,
        radius: radius,
        colors: [color, color.withValues(alpha: 0)],
      ),
    ),
  );
}

/// Rub el Hizb medallion with the name in gilded Amiri, on a breathing glow.
final class _Emblem extends StatelessWidget {
  const _Emblem({required this.breathe});

  final Animation<double> breathe;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 176,
    child: Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: breathe,
          builder: (_, child) => Transform.scale(
            scale: 1.15 + breathe.value * 0.08,
            child: Opacity(opacity: 0.75 + breathe.value * 0.25, child: child),
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Color(0x406FFBBE), Color(0x00059669)]),
            ),
          ),
        ),
        const CustomPaint(size: Size.square(176), painter: _EmblemPainter()),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (r) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF6ED), Color(0xFFFFE3C6), Color(0xFFE4AA73)],
            ).createShader(r),
            child: Text(
              'نُور',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 52,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: [Shadow(color: _gold.withValues(alpha: 0.55), blurRadius: 14)],
              ),
            ),
          ),
        ),
        // Morning star at the top of the orbit.
        const Positioned(
          top: -4,
          child: Icon(
            Icons.auto_awesome,
            size: 16,
            color: AppColors.amber200,
            shadows: [Shadow(color: _gold, blurRadius: 8)],
          ),
        ),
      ],
    ),
  );
}

final class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: (r) =>
        const LinearGradient(colors: [Colors.white, Color(0xFFF4FCFA), Color(0xFFD8F4ED)])
            .createShader(r),
    // Wide tracking adds space after the last letter too; pad the start to stay centred.
    child: const Padding(
      padding: EdgeInsetsDirectional.only(start: 12),
      child: Text(
        'NOOR',
        textDirection: TextDirection.ltr,
        style: TextStyle(
          fontSize: 34,
          height: 1.2,
          letterSpacing: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    ),
  );
}

final class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: _gold.withValues(alpha: 0.3)),
      gradient: LinearGradient(
        colors: [
          const Color(0xFF10B981).withValues(alpha: 0.1),
          const Color(0xFFFBBF24).withValues(alpha: 0.1),
          const Color(0xFF10B981).withValues(alpha: 0.1),
        ],
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        const Icon(Icons.auto_awesome, size: 13, color: AppColors.amber200),
        Flexible(
          child: Text(
            'splash_tagline'.tr.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w700,
              color: AppColors.amber100.withValues(alpha: 0.95),
            ),
          ),
        ),
      ],
    ),
  );
}

final class _Features extends StatelessWidget {
  const _Features();

  @override
  Widget build(BuildContext context) {
    Widget pill(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _sage.withValues(alpha: 0.9),
        ),
      ),
    );
    final dot = Text('•', style: TextStyle(fontSize: 12, color: _gold.withValues(alpha: 0.4)));
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [pill('nav_quran'.tr), dot, pill('prayer_times'.tr), dot, pill('hisnul_muslim'.tr)],
    );
  }
}

/// Short shimmer line and "by Allah's leave": a quiet sign that the app is opening.
final class _Footer extends StatelessWidget {
  const _Footer({required this.shimmer});

  final Animation<double> shimmer;

  @override
  Widget build(BuildContext context) => Column(
    spacing: 12,
    children: [
      Container(
        width: 140,
        height: 4,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(99),
        ),
        child: AnimatedBuilder(
          animation: shimmer,
          builder: (_, _) => DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-3 + shimmer.value * 4, 0),
                end: Alignment(-1 + shimmer.value * 4, 0),
                colors: [
                  _mint.withValues(alpha: 0),
                  _mint.withValues(alpha: 0.9),
                  _gold,
                  _mint.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
      Text(
        'بِإِذْنِ اللَّه',
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 14,
          color: AppColors.amber200.withValues(alpha: 0.7),
        ),
      ),
    ],
  );
}

// ---- Painters ----

/// Circle drawn as short dashes.
void _dashedCircle(Canvas canvas, Offset c, double r, Paint paint, double dash, double gap) {
  final step = (dash + gap) / r;
  final sweep = dash / r;
  for (var a = 0.0; a < 2 * math.pi; a += step) {
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, sweep, false, paint);
  }
}

/// Square of side [side] around [c], turned by [turn], with softened corners.
void _square(Canvas canvas, Offset c, double side, double turn, double radius, Paint paint) =>
    canvas
      ..save()
      ..translate(c.dx, c.dy)
      ..rotate(turn)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: side, height: side),
          Radius.circular(radius),
        ),
        paint,
      )
      ..restore();

Paint _line(Color color, double width) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..color = color;

/// The large watermark: dashed orbits and a double eight-point star (design at 400 x 400).
final class _MandalaPainter extends CustomPainter {
  const _MandalaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const k = 460 / 400; // watermark is 460 wide
    final gold = _gold.withValues(alpha: 0.16);
    final mint = _mint.withValues(alpha: 0.16);
    final c = size.center(Offset.zero);
    _dashedCircle(canvas, c, 195 * k, _line(mint, 0.8), 3, 6);
    canvas.drawCircle(c, 180 * k, _line(gold, 0.5));
    _dashedCircle(canvas, c, 150 * k, _line(mint, 0.75), 8, 8);
    canvas.drawCircle(c, 125 * k, _line(gold, 0.5));
    for (final turn in const [0.0, math.pi / 4]) {
      _square(canvas, c, 230 * k, turn, 4, _line(gold, 0.8));
    }
    for (final turn in const [math.pi / 8, 3 * math.pi / 8]) {
      _square(canvas, c, 190 * k, turn, 4, _line(mint, 0.5));
    }
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
        c + Offset.fromDirection(i * math.pi / 2, 195 * k),
        2.5,
        Paint()..color = gold,
      );
    }
  }

  @override
  bool shouldRepaint(_MandalaPainter old) => false;
}

final class _RingsPainter extends CustomPainter {
  const _RingsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const k = 340 / 300;
    final gold = _gold.withValues(alpha: 0.14);
    final mint = _mint.withValues(alpha: 0.14);
    final c = size.center(Offset.zero);
    _dashedCircle(canvas, c, 140 * k, _line(gold, 0.75), 1, 7);
    canvas.drawCircle(c, 110 * k, _line(mint, 0.5));
  }

  @override
  bool shouldRepaint(_RingsPainter old) => false;
}

/// The medallion behind the name (design at 176 x 176).
final class _EmblemPainter extends CustomPainter {
  const _EmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 176;
    final c = size.center(Offset.zero);
    _dashedCircle(canvas, c, 82 * k, _line(_gold.withValues(alpha: 0.35), 0.75), 3, 4);
    canvas.drawCircle(c, 74 * k, _line(_mint.withValues(alpha: 0.45), 0.75));
    final fill = Paint()..color = const Color(0xF206221C);
    for (final (turn, stroke, width) in [(0.0, _gold, 1.25), (math.pi / 4, _mint, 1.1)]) {
      _square(canvas, c, 104 * k, turn, 8, fill);
      _square(canvas, c, 104 * k, turn, 8, _line(stroke, width));
    }
    canvas
      ..drawCircle(c, 44 * k, _line(_gold.withValues(alpha: 0.6), 0.85))
      ..drawCircle(c, 41 * k, Paint()..color = const Color(0xFF041813))
      ..drawCircle(c, 41 * k, _line(_mint.withValues(alpha: 0.3), 0.75))
      // Cardinal gems, the top one brightest.
      ..drawCircle(
        c + Offset(0, -82 * k),
        5,
        Paint()
          ..color = const Color(0x99FFE2B8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      )
      ..drawCircle(c + Offset(0, -82 * k), 3, Paint()..color = const Color(0xFFFFE2B8));
    for (final d in [Offset(0, 82 * k), Offset(-82 * k, 0), Offset(82 * k, 0)]) {
      canvas.drawCircle(c + d, 2, Paint()..color = _gold.withValues(alpha: 0.8));
    }
  }

  @override
  bool shouldRepaint(_EmblemPainter old) => false;
}

/// Fixed scatter of faint stars (seeded, so the sky never jumps).
final class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(11);
    for (var i = 0; i < 30; i++) {
      final warm = rng.nextBool();
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        0.4 + rng.nextDouble() * 1.1,
        Paint()
          ..color = (warm ? AppColors.amber100 : AppColors.emerald100).withValues(
            alpha: 0.15 + rng.nextDouble() * 0.45,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => false;
}
