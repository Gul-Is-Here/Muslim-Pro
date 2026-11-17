import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/features/learn/viewmodels/learn_view_model.dart';
import 'package:quran_pro/features/learn/views/widgets/learn_colors.dart';
import 'package:quran_pro/features/learn/views/widgets/lessons_sheet.dart';

IconData unitIcon(String key) => switch (key) {
  'kalimas' => Icons.auto_stories,
  'wudu' => Icons.water_drop,
  'salah' => Icons.self_improvement,
  'duas' => Icons.front_hand,
  _ => Icons.menu_book,
};

/// Unit banner plus the winding path of units and reward chests.
final class LearnPathCard extends GetView<LearnViewModel> {
  const LearnPathCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: LearnColors.shadow,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x0D004334), Colors.white, Color(0x0D795902)],
      ),
    ),
    child: Obx(
      () => !controller.loaded
          ? const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator(color: LearnColors.primary)),
            )
          : Column(
              children: [
                const _UnitBanner(),
                const SizedBox(height: 28),
                _WindingPath(nodes: controller.path),
              ],
            ),
    ),
  );
}

final class _UnitBanner extends GetView<LearnViewModel> {
  const _UnitBanner();

  @override
  Widget build(BuildContext context) => Obx(() {
    final c = controller.current;
    final tag = c == null ? 'all_done_tag'.tr : controller.text(c.unit.tag);
    final title = c == null ? 'all_done_title'.tr : controller.text(c.unit.title);
    final sub = c == null
        ? 'all_done_sub'.tr
        : 'lesson_n'.trParams({'n': '${c.index + 1}', 'title': controller.text(c.lesson.title)});
    return Material(
      color: LearnColors.primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: c == null ? null : controller.resume,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (c != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: LearnColors.primaryFixedDim,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'unit_active'.trParams({
                                'n': '${controller.currentUnitNumber}',
                              }).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: Color(0xFF002018),
                              ),
                            ),
                          ),
                        Text(
                          tag,
                          style: const TextStyle(fontSize: 12, color: LearnColors.primaryFixed),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: LearnColors.primaryFixed.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: LearnColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: c?.unit.icon == 'qaida'
                    ? const Text(
                        'أ',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: LearnColors.goldContainer,
                        ),
                      )
                    : Icon(
                        c == null ? Icons.workspace_premium : unitIcon(c.unit.icon),
                        size: 26,
                        color: LearnColors.goldContainer,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  });
}

/// Node geometry: circle diameter and how much room its caption needs below.
({double size, double below}) _metrics(LearnNodeState s) => switch (s) {
  LearnNodeState.done => (size: 64, below: 44),
  LearnNodeState.active => (size: 72, below: 128),
  LearnNodeState.locked => (size: 56, below: 44),
  _ => (size: 56, below: 40), // chests
};

const _xPattern = [0.5, 0.74, 0.28]; // centre, right, left, repeating
const _gap = 28.0;

final class _WindingPath extends StatelessWidget {
  const _WindingPath({required this.nodes});

  final List<LearnNode> nodes;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = box.maxWidth;
      final centers = <Offset>[];
      final tops = <double>[];
      var y = 0.0;
      for (var i = 0; i < nodes.length; i++) {
        final m = _metrics(nodes[i].state);
        tops.add(y);
        centers.add(Offset(w * _xPattern[i % _xPattern.length], y + m.size / 2));
        y += m.size + m.below + _gap;
      }
      final active = nodes.indexWhere((n) => n.state == LearnNodeState.active);
      final reached = active >= 0 ? active : nodes.length - 1; // all done: the whole trail
      var lockedSeen = 0;
      return SizedBox(
        height: math.max(0, y - _gap),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _TrailPainter(centers: centers, reached: reached),
              ),
            ),
            for (var i = 0; i < nodes.length; i++)
              ..._node(
                nodes[i],
                centers[i],
                tops[i],
                w,
                // Locked units fade progressively further down the path.
                nodes[i].state == LearnNodeState.locked
                    ? math.max(0.5, 0.8 - 0.12 * lockedSeen++)
                    : 1,
              ),
          ],
        ),
      );
    },
  );

  List<Widget> _node(LearnNode n, Offset c, double top, double width, double opacity) {
    final m = _metrics(n.state);
    final captionWidth = n.state == LearnNodeState.active ? 210.0 : 160.0;
    final left = (c.dx - captionWidth / 2)
        .clamp(0.0, math.max(0.0, width - captionWidth))
        .toDouble();
    return [
      Positioned(
        left: c.dx - m.size / 2 - 16,
        top: top - 16,
        width: m.size + 32,
        height: m.size + 32,
        child: Opacity(
          opacity: opacity,
          child: Center(child: _NodeBadge(n)),
        ),
      ),
      Positioned(
        left: left,
        top: top + m.size + 8,
        width: captionWidth,
        child: Opacity(opacity: opacity, child: _Caption(n)),
      ),
    ];
  }
}

final class _TrailPainter extends CustomPainter {
  const _TrailPainter({required this.centers, required this.reached});

  final List<Offset> centers;
  final int reached;

  Path _through(int last) {
    final p = Path()..moveTo(centers.first.dx, centers.first.dy);
    for (var i = 1; i <= last; i++) {
      final a = centers[i - 1];
      final b = centers[i];
      final mid = (b.dy - a.dy) / 2;
      p.cubicTo(a.dx, a.dy + mid, b.dx, b.dy - mid, b.dx, b.dy);
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;
    final dot = Paint()..color = LearnColors.trail;
    for (final m in _through(centers.length - 1).computeMetrics()) {
      for (var d = 0.0; d <= m.length; d += 14) {
        canvas.drawCircle(m.getTangentForOffset(d)!.position, 4, dot);
      }
    }
    if (reached > 0) {
      canvas.drawPath(
        _through(reached),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..color = LearnColors.trailDone,
      );
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.reached != reached || !listEquals(old.centers, centers);
}

final class _NodeBadge extends GetView<LearnViewModel> {
  const _NodeBadge(this.node);

  final LearnNode node;

  void _tap(BuildContext context) => node.state == LearnNodeState.done
      ? showLessonsSheet(context, controller, unit: node.unit)
      : controller.tapNode(node);

  @override
  Widget build(BuildContext context) {
    final badge = switch (node.state) {
      LearnNodeState.done => Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: LearnColors.goldContainer,
              shape: BoxShape.circle,
              boxShadow: LearnColors.shadow,
            ),
            child: const DecoratedBox(
              decoration: BoxDecoration(color: LearnColors.gold, shape: BoxShape.circle),
              child: Icon(Icons.check_circle, size: 28, color: Colors.white),
            ),
          ),
          const Positioned(
            top: -6,
            right: -6,
            child: _Corner(icon: Icons.star_rounded, bg: LearnColors.goldFixed),
          ),
        ],
      ),
      LearnNodeState.active => _ActiveNode(node: node, onTap: controller.resume),
      LearnNodeState.chest => Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: LearnColors.goldContainer,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: LearnColors.goldFixedDim.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.redeem, size: 28, color: LearnColors.onGoldContainer),
          ),
          const Positioned(
            top: -8,
            right: -4,
            child: Icon(Icons.auto_awesome, size: 16, color: LearnColors.gold),
          ),
        ],
      ),
      LearnNodeState.chestOpen => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: LearnColors.goldFixed.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.card_giftcard, size: 26, color: LearnColors.gold),
      ),
      LearnNodeState.chestLocked => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: LearnColors.high, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.redeem, size: 26, color: LearnColors.outline),
      ),
      LearnNodeState.locked => Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: LearnColors.high, shape: BoxShape.circle),
            child: node.unit.icon == 'qaida'
                ? const Text(
                    'أ ب ت',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: LearnColors.outline,
                    ),
                  )
                : Icon(unitIcon(node.unit.icon), size: 26, color: LearnColors.outline),
          ),
          const Positioned(
            bottom: -4,
            right: -4,
            child: _Corner(icon: Icons.lock, bg: LearnColors.highest),
          ),
        ],
      ),
    };
    if (node.state == LearnNodeState.active) return badge;
    return Semantics(
      button: true,
      label: node.title,
      child: GestureDetector(onTap: () => _tap(context), child: badge),
    );
  }
}

final class _Corner extends StatelessWidget {
  const _Corner({required this.icon, required this.bg});

  final IconData icon;
  final Color bg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: bg, shape: BoxShape.circle, boxShadow: LearnColors.shadow),
    child: Icon(icon, size: 13, color: LearnColors.onVariant),
  );
}

/// Current unit: a soft pulse behind the button and a START tag above it.
final class _ActiveNode extends StatefulWidget {
  const _ActiveNode({required this.node, required this.onTap});

  final LearnNode node;
  final VoidCallback onTap;

  @override
  State<_ActiveNode> createState() => _ActiveNodeState();
}

final class _ActiveNodeState extends State<_ActiveNode> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 104,
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, _) => Container(
            width: 72 + 32 * _pulse.value,
            height: 72 + 32 * _pulse.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LearnColors.primary.withValues(alpha: 0.2 * (1 - _pulse.value)),
            ),
          ),
        ),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: LearnColors.primaryFixed.withValues(alpha: 0.4),
          ),
        ),
        Material(
          color: LearnColors.primary,
          shape: const CircleBorder(),
          elevation: 6,
          shadowColor: LearnColors.primary.withValues(alpha: 0.4),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onTap,
            child: SizedBox.square(
              dimension: 72,
              child: Center(
                child: widget.node.unit.icon == 'qaida'
                    ? const Text(
                        'أ',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      )
                    : Icon(unitIcon(widget.node.unit.icon), size: 34, color: Colors.white),
              ),
            ),
          ),
        ),
        Positioned(
          top: 6,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 2, 6, 2),
              decoration: BoxDecoration(
                color: LearnColors.gold,
                borderRadius: BorderRadius.circular(99),
                boxShadow: LearnColors.shadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'start_badge'.tr,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Icon(Icons.play_arrow, size: 12, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

final class _Caption extends GetView<LearnViewModel> {
  const _Caption(this.node);

  final LearnNode node;

  @override
  Widget build(BuildContext context) {
    final c = controller.current;
    if (node.state == LearnNodeState.active && c != null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: LearnColors.low,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'lesson_of'.trParams({
                'n': '${c.index + 1}',
                'total': '${c.unit.lessons.length}',
              }).toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: LearnColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              controller.text(c.lesson.title),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: LearnColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 34,
              child: FilledButton(
                onPressed: controller.resume,
                style: FilledButton.styleFrom(
                  backgroundColor: LearnColors.primary,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      (c.index == 0 ? 'start' : 'resume').tr,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'xp_plus'.trParams({'n': '${c.lesson.xp}'}),
                      style: const TextStyle(fontSize: 11, color: LearnColors.goldFixed),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    final muted = node.state == LearnNodeState.locked || node.state == LearnNodeState.chestLocked;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          node.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: muted ? 13 : 14,
            height: 1.25,
            fontWeight: muted ? FontWeight.w600 : FontWeight.w700,
            color: muted ? LearnColors.onVariant : LearnColors.onSurface,
          ),
        ),
        Text(
          node.subtitle,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: muted ? FontWeight.w500 : FontWeight.w700,
            color: muted ? LearnColors.outline : LearnColors.gold,
          ),
        ),
      ],
    );
  }
}
