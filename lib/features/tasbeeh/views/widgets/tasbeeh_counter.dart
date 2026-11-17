import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/features/tasbeeh/viewmodels/tasbeeh_view_model.dart';

const _green = Color(0xFF24C189);
const _mint = Color(0xFF4EDEA3);
const _orange = Color(0xFFFE932C);
const _idle = Color(0xFFDAE2FD);
const _track = Color(0xFFEAEDFF);

/// The big tap target: progress ring, 33 beads and the count in the middle.
final class TasbeehCounter extends GetView<TasbeehViewModel> {
  const TasbeehCounter({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, box) {
            final size = box.maxWidth;
            return Stack(
              alignment: Alignment.center,
              children: [
                // Soft glow behind the ring.
                Container(
                  margin: EdgeInsets.all(size * 0.06),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.mint.withValues(alpha: 0.18),
                        _orange.withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                      stops: const [0.45, 0.8, 1],
                    ),
                  ),
                ),
                Obx(() {
                  final s = controller.state;
                  return CustomPaint(
                    size: Size.square(size),
                    painter: _RingPainter(progress: s.progress, beadsDone: s.count % 33),
                  );
                }),
                Semantics(
                  button: true,
                  label: 'tap_to_count'.tr,
                  child: Material(
                    type: MaterialType.transparency,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: controller.count,
                      splashColor: AppColors.mint.withValues(alpha: 0.25),
                      child: SizedBox.square(dimension: size),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Container(
                    width: size * 0.6,
                    height: size * 0.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [scheme.surfaceContainerLowest, scheme.surfaceContainerLow],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryContainer.withValues(alpha: 0.12),
                          blurRadius: 36,
                          offset: const Offset(0, 16),
                          spreadRadius: -8,
                        ),
                      ],
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(padding: EdgeInsets.all(16), child: _CounterFace()),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

final class _CounterFace extends GetView<TasbeehViewModel> {
  const _CounterFace();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      final s = controller.state;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 5,
              children: [
                const CircleAvatar(radius: 3, backgroundColor: _orange),
                Text(
                  controller.roundLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // Re-keyed per tap so each count gives a small bounce.
              TweenAnimationBuilder<double>(
                key: ValueKey(s.count),
                tween: Tween(begin: 1.12, end: 1),
                duration: const Duration(milliseconds: 160),
                builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
                child: Text(
                  '${s.count}',
                  style: const TextStyle(
                    fontSize: 44,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ ${controller.targetLabel}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              const Icon(Icons.touch_app, size: 14, color: _mint),
              Text(
                'tap_to_count'.tr.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

final class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.beadsDone});

  final double progress;
  final int beadsDone;
  static const _beads = 33;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 320; // design units
    final c = size.center(Offset.zero);
    final r = 132 * k;
    final rect = Rect.fromCircle(center: c, radius: r);

    // Dotted track: 2-unit dashes every 8 units around the ring.
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * k
      ..color = _track;
    const step = 8 / 132;
    for (var a = 0.0; a < 2 * math.pi; a += step) {
      canvas.drawArc(rect, a, 2 / 132, false, track);
    }

    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6 * k
          ..strokeCap = StrokeCap.round
          ..shader = const SweepGradient(
            colors: [_green, _mint, _orange],
            stops: [0, 0.6, 1],
            transform: GradientRotation(-math.pi / 2),
          ).createShader(rect),
      );
    }

    for (var i = 0; i < _beads; i++) {
      final a = i / _beads * 2 * math.pi - math.pi / 2;
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      if (i == beadsDone) {
        canvas
          ..drawCircle(
            p,
            9 * k,
            Paint()
              ..color = _orange.withValues(alpha: 0.45)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * k),
          )
          ..drawCircle(p, 7 * k, Paint()..color = _orange);
      } else {
        canvas.drawCircle(
          p,
          (i < beadsDone ? 5 : 4) * k,
          Paint()..color = i < beadsDone ? _green : _idle,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.beadsDone != beadsDone;
}
