import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/data/models/adhkar.dart';
import 'package:quran_pro/features/adhkar/viewmodels/adhkar_view_model.dart';

final class AdhkarView extends GetView<AdhkarViewModel> {
  const AdhkarView({super.key});

  static const Map<AdhkarCategory, IconData> icons = {
    AdhkarCategory.morningEvening: Icons.wb_twilight_rounded,
    AdhkarCategory.afterSalah: Icons.mosque_outlined,
    AdhkarCategory.sleep: Icons.bedtime_outlined,
    AdhkarCategory.waking: Icons.wb_sunny_outlined,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    appBar: AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      title: Text(
        'hisnul_muslim'.tr,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.gray900),
      ),
      actions: [
        Obx(
          () => IconButton(
            tooltip: 'adhkar_meaning'.tr,
            onPressed: controller.toggleMeaning,
            icon: Icon(
              controller.showMeaning ? Icons.translate_rounded : Icons.translate_outlined,
              color: controller.showMeaning ? AppColors.emerald700 : AppColors.gray400,
            ),
          ),
        ),
        IconButton(
          tooltip: 'adhkar_reset'.tr,
          onPressed: () => _confirmReset(context),
          icon: const Icon(Icons.restart_alt_rounded, color: AppColors.gray700),
        ),
        const SizedBox(width: 4),
      ],
    ),
    body: Obx(() {
      if (controller.loading) return const Center(child: CircularProgressIndicator());
      final items = controller.items;
      return CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _Tabs()),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
            sliver: SliverToBoxAdapter(child: _Progress()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _DhikrCard(dhikr: items[i]),
            ),
          ),
        ],
      );
    }),
  );

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('adhkar_reset'.tr),
        content: Text('adhkar_reset_body'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('cancel'.tr)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text('adhkar_reset'.tr)),
        ],
      ),
    );
    if (ok ?? false) controller.resetTab();
  }
}

final class _Tabs extends GetView<AdhkarViewModel> {
  const _Tabs();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
    child: Obx(
      () => Row(
        spacing: 8,
        children: [
          for (final c in AdhkarCategory.values)
            ChoiceChip(
              selected: controller.tab == c,
              onSelected: (_) => controller.selectTab(c),
              showCheckmark: false,
              avatar: Icon(
                AdhkarView.icons[c],
                size: 18,
                color: controller.tab == c ? Colors.white : AppColors.emerald800,
              ),
              label: Text('adhkar_cat_${c.name}'.tr),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w700,
                color: controller.tab == c ? Colors.white : AppColors.gray800,
              ),
              selectedColor: AppColors.primaryContainer,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: controller.tab == c ? AppColors.primaryContainer : AppColors.gray200,
              ),
              shape: const StadiumBorder(),
            ),
        ],
      ),
    ),
  );
}

final class _Progress extends GetView<AdhkarViewModel> {
  const _Progress();

  @override
  Widget build(BuildContext context) => Obx(() {
    final done = controller.doneIn(controller.tab);
    final total = controller.totalIn(controller.tab);
    final complete = total > 0 && done == total;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.jewelTop, AppColors.primaryContainer],
        ),
      ),
      child: Row(
        spacing: 14,
        children: [
          SizedBox.square(
            dimension: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: total == 0 ? 0 : done / total,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    color: AppColors.mint,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                Icon(
                  complete ? Icons.check_rounded : AdhkarView.icons[controller.tab],
                  color: Colors.white,
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complete
                      ? 'adhkar_all_done'.tr
                      : 'adhkar_progress'.trParams({'done': '$done', 'total': '$total'}),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'adhkar_hint'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.emerald100.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  });
}

final class _DhikrCard extends GetView<AdhkarViewModel> {
  const _DhikrCard({required this.dhikr});

  final Dhikr dhikr;

  @override
  Widget build(BuildContext context) => Obx(() {
    final count = controller.countOf(dhikr);
    final done = controller.isDone(dhikr);
    final status = controller.statusOf(dhikr);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: done ? 0.72 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: done ? AppColors.emerald200 : const Color(0x0F042F2E)),
          boxShadow: const [
            BoxShadow(color: Color(0x08042F2E), blurRadius: 10, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 0),
              child: Row(
                spacing: 8,
                children: [
                  _Chip('#${dhikr.number}', fg: AppColors.gray500, bg: AppColors.gray100),
                  if (dhikr.repeat > 1)
                    _Chip('×${dhikr.repeat}', fg: AppColors.amber800, bg: AppColors.amber100),
                  const Spacer(),
                  if (dhikr.hasAudio)
                    IconButton(
                      tooltip: 'listen'.tr,
                      onPressed: () => controller.play(dhikr),
                      icon: switch (status) {
                        AudioStatus.loading => const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        AudioStatus.playing => const Icon(
                          Icons.pause_circle_filled_rounded,
                          color: AppColors.emerald700,
                        ),
                        _ => const Icon(
                          Icons.play_circle_outline_rounded,
                          color: AppColors.gray500,
                        ),
                      },
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                dhikr.arabic,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 21,
                  height: 2,
                  color: AppColors.gray900,
                ),
              ),
            ),
            if (controller.showMeaning) ...[
              if (dhikr.translit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    dhikr.translit,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                      color: AppColors.emerald800,
                    ),
                  ),
                ),
              if (dhikr.english.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    dhikr.english,
                    style: const TextStyle(fontSize: 13.5, height: 1.55, color: AppColors.gray700),
                  ),
                ),
            ],
            Padding(
              padding: const EdgeInsets.all(12),
              child: _Counter(
                count: count,
                repeat: dhikr.repeat,
                done: done,
                onTap: () => controller.count(dhikr),
              ),
            ),
          ],
        ),
      ),
    );
  });
}

final class _Chip extends StatelessWidget {
  const _Chip(this.text, {required this.fg, required this.bg});

  final String text;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Text(
      text,
      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: fg),
    ),
  );
}

/// Full-width tap target: counts one repetition, fills as it goes, turns green when complete.
final class _Counter extends StatelessWidget {
  const _Counter({
    required this.count,
    required this.repeat,
    required this.done,
    required this.onTap,
  });

  final int count;
  final int repeat;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: done ? 'adhkar_done'.tr : 'adhkar_tap'.tr,
    value: '$count / $repeat',
    child: Material(
      color: done ? AppColors.emerald50 : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: done ? null : onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: repeat == 0 ? 0 : count / repeat,
                child: ColoredBox(color: AppColors.emerald100.withValues(alpha: done ? 0 : 0.7)),
              ),
            ),
            SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [
                  Icon(
                    done ? Icons.check_circle_rounded : Icons.touch_app_outlined,
                    size: 20,
                    color: done ? AppColors.emerald700 : AppColors.primaryContainer,
                  ),
                  Text(
                    done ? 'adhkar_done'.tr : 'adhkar_tap'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: done ? AppColors.emerald700 : AppColors.primaryContainer,
                    ),
                  ),
                  if (repeat > 1)
                    Text(
                      '$count / $repeat',
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
