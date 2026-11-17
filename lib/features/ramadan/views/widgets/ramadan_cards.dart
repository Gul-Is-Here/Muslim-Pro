import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/data/models/ramadan_progress.dart';
import 'package:quran_pro/features/ramadan/viewmodels/ramadan_view_model.dart';

const _shadow = [BoxShadow(color: Color(0x0A042F2E), blurRadius: 12, offset: Offset(0, 3))];

final class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: _shadow,
    ),
    child: child,
  );
}

final class _Heading extends StatelessWidget {
  const _Heading(this.icon, this.title, {this.trailing});

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 8,
    children: [
      Icon(icon, size: 20, color: AppColors.amber700),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
      ?trailing,
    ],
  );
}

// ---- 30-day calendar ----

final class FastCalendar extends GetView<RamadanViewModel> {
  const FastCalendar({super.key});

  @override
  Widget build(BuildContext context) => _Card(
    child: Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Heading(
            Icons.calendar_month_rounded,
            'ramadan_calendar'.tr,
            trailing: Text(
              'ramadan_fasted_count'.trParams({'n': '${controller.fasted}'}),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.emerald700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            controller.inRamadan ? 'ramadan_calendar_hint'.tr : 'ramadan_calendar_locked'.tr,
            style: const TextStyle(fontSize: 12.5, color: AppColors.gray500),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: RamadanViewModel.days,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (_, i) => _DayCell(day: i + 1),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _Legend(color: AppColors.emerald500, label: 'ramadan_fasted'.tr),
              _Legend(color: AppColors.amber500, label: 'ramadan_missed'.tr),
              _Legend(
                color: AppColors.primaryContainer,
                label: 'ramadan_odd_nights'.tr,
                star: true,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

final class _DayCell extends GetView<RamadanViewModel> {
  const _DayCell({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    final status = controller.statusOf(day);
    final isToday = controller.today == day;
    final open = controller.canMark(day);
    final (bg, fg, border) = switch (status) {
      FastStatus.fasted => (AppColors.emerald500, Colors.white, AppColors.emerald500),
      FastStatus.missed => (AppColors.amber100, AppColors.amber800, AppColors.amber400),
      FastStatus.none when open => (Colors.white, AppColors.gray800, AppColors.gray200),
      FastStatus.none => (AppColors.surface, AppColors.gray400, AppColors.gray100),
    };
    return Semantics(
      button: open,
      label: '${'ramadan_day_n'.trParams({'n': '$day'})}, ${status.name}',
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isToday ? AppColors.primaryContainer : border,
            width: isToday ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: open ? () => controller.cycleDay(day) : null,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == FastStatus.fasted)
                      const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                    else
                      Text(
                        '$day',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg),
                      ),
                    Text(
                      controller.shortDate(day),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 8.5,
                        color: status == FastStatus.fasted
                            ? Colors.white.withValues(alpha: 0.85)
                            : AppColors.gray400,
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.isOddNight(day))
                PositionedDirectional(
                  top: 3,
                  end: 4,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 10,
                    color: status == FastStatus.fasted ? Colors.white : AppColors.amber600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.star = false});

  final Color color;
  final String label;
  final bool star;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 5,
    children: [
      if (star)
        const Icon(Icons.auto_awesome, size: 12, color: AppColors.amber600)
      else
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
      Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.gray500)),
    ],
  );
}

// ---- Today's good deeds ----

final class DeedsChecklist extends GetView<RamadanViewModel> {
  const DeedsChecklist({super.key});

  static const Map<RamadanDeed, IconData> _icons = {
    RamadanDeed.taraweeh: Icons.mosque_outlined,
    RamadanDeed.quran: Icons.menu_book_outlined,
    RamadanDeed.sadaqah: Icons.volunteer_activism_outlined,
    RamadanDeed.adhkar: Icons.wb_sunny_outlined,
    RamadanDeed.iftarDua: Icons.front_hand_outlined,
  };

  @override
  Widget build(BuildContext context) => _Card(
    child: Obx(() {
      final done = controller.deedsDone;
      final total = RamadanDeed.values.length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Heading(
            Icons.task_alt_rounded,
            'ramadan_deeds'.tr,
            trailing: Text(
              '$done/$total',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.emerald700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: done / total,
              minHeight: 6,
              color: AppColors.emerald500,
              backgroundColor: AppColors.gray100,
            ),
          ),
          const SizedBox(height: 6),
          for (final d in RamadanDeed.values)
            _DeedRow(
              icon: _icons[d]!,
              label: 'ramadan_deed_${d.name}'.tr,
              done: controller.isDone(d),
              onTap: () => controller.toggleDeed(d),
            ),
        ],
      );
    }),
  );
}

final class _DeedRow extends StatelessWidget {
  const _DeedRow({
    required this.icon,
    required this.label,
    required this.done,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
      child: Row(
        spacing: 12,
        children: [
          Icon(icon, size: 20, color: done ? AppColors.emerald700 : AppColors.gray400),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: done ? AppColors.gray400 : AppColors.gray800,
                decoration: done ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.gray400,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: done ? AppColors.emerald500 : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: done ? AppColors.emerald500 : AppColors.gray200, width: 2),
            ),
            child: done ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
          ),
        ],
      ),
    ),
  );
}

// ---- Quran: a juz a day ----

final class KhatamCard extends GetView<RamadanViewModel> {
  const KhatamCard({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    final juz = controller.todaysJuz;
    return Material(
      color: AppColors.emerald50,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => controller.openJuz(juz),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            spacing: 14,
            children: [
              SizedBox.square(
                dimension: 58,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: juz / 30,
                        strokeWidth: 5,
                        strokeCap: StrokeCap.round,
                        color: AppColors.emerald700,
                        backgroundColor: AppColors.emerald100,
                      ),
                    ),
                    Text(
                      '$juz',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.emerald800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ramadan_khatam'.tr.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                        color: AppColors.emerald700,
                      ),
                    ),
                    Text(
                      'ramadan_read_juz'.trParams({'n': '$juz'}),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      controller.juzStart(juz),
                      style: const TextStyle(fontSize: 12.5, color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.emerald700),
            ],
          ),
        ),
      ),
    );
  });
}

// ---- Last ten nights ----

final class LastTenCard extends GetView<RamadanViewModel> {
  const LastTenCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.amber50, Color(0xFFFFF7E0)],
      ),
      border: Border.all(color: AppColors.amber200),
    ),
    child: Obx(() {
      final today = controller.today;
      final inLastTen = today != null && controller.isLastTen(today);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Heading(Icons.auto_awesome, 'ramadan_last_ten'.tr),
          const SizedBox(height: 8),
          Text(
            inLastTen && controller.isOddNight(today)
                ? 'ramadan_last_ten_tonight'.tr
                : 'ramadan_last_ten_body'.tr,
            style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.amber950),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bukhari 2017',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.amber700),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final night in const [21, 23, 25, 27, 29])
                _NightChip(night: night, tonight: today == night),
            ],
          ),
        ],
      );
    }),
  );
}

final class _NightChip extends StatelessWidget {
  const _NightChip({required this.night, required this.tonight});

  final int night;
  final bool tonight;

  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: tonight ? AppColors.primaryContainer : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: tonight ? AppColors.primaryContainer : AppColors.amber200),
    ),
    child: Column(
      children: [
        Icon(
          Icons.nightlight_round,
          size: 16,
          color: tonight ? AppColors.amber300 : AppColors.amber600,
        ),
        Text(
          '$night',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: tonight ? Colors.white : AppColors.amber950,
          ),
        ),
      ],
    ),
  );
}

// ---- Make-up fasts ----

final class QadaCard extends GetView<RamadanViewModel> {
  const QadaCard({super.key});

  @override
  Widget build(BuildContext context) => _Card(
    child: Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Heading(Icons.event_repeat_rounded, 'ramadan_qada'.tr),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 8,
            children: [
              Text(
                '${controller.owed}',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 40,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: controller.owed == 0 ? AppColors.emerald700 : AppColors.amber700,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  controller.owed == 0 ? 'ramadan_qada_none'.tr : 'ramadan_qada_left'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'ramadan_qada_from_missed'.trParams({'n': '${controller.missed}'}),
            style: const TextStyle(fontSize: 12.5, color: AppColors.gray500),
          ),
          const Divider(height: 24, color: AppColors.gray100),
          _Stepper(
            label: 'ramadan_qada_before'.tr,
            value: controller.owedBefore,
            onChange: controller.changeOwedBefore,
          ),
          const SizedBox(height: 8),
          _Stepper(
            label: 'ramadan_qada_made_up'.tr,
            value: controller.madeUp,
            onChange: controller.changeMadeUp,
          ),
        ],
      ),
    ),
  );
}

final class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.onChange});

  final String label;
  final int value;
  final void Function(int by) onChange;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.gray800,
          ),
        ),
      ),
      IconButton.outlined(
        tooltip: '−1',
        onPressed: value == 0 ? null : () => onChange(-1),
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.remove_rounded, size: 18),
      ),
      SizedBox(
        width: 36,
        child: Text(
          '$value',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
      IconButton.outlined(
        tooltip: '+1',
        onPressed: () => onChange(1),
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.add_rounded, size: 18),
      ),
    ],
  );
}

// ---- Duas ----

final class DuasSection extends GetView<RamadanViewModel> {
  const DuasSection({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: _Heading(Icons.front_hand_outlined, 'ramadan_duas'.tr),
      ),
      for (final d in RamadanViewModel.duas) ...[_DuaCard(dua: d), const SizedBox(height: 10)],
    ],
  );
}

final class _DuaCard extends GetView<RamadanViewModel> {
  const _DuaCard({required this.dua});

  final RamadanDua dua;

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                dua.titleKey.tr,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            if (dua.audio != null)
              Obx(() {
                final status = controller.duaStatus(dua);
                return IconButton.filledTonal(
                  tooltip: 'listen'.tr,
                  onPressed: () => controller.toggleDua(dua),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.emerald50,
                    foregroundColor: AppColors.emerald800,
                  ),
                  icon: switch (status) {
                    AudioStatus.loading => const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    AudioStatus.playing => const Icon(Icons.pause_rounded),
                    _ => const Icon(Icons.volume_up_rounded),
                  },
                );
              }),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          dua.arabic,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 22,
            height: 1.9,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dua.meaningKey.tr,
          style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.gray700),
        ),
        const SizedBox(height: 6),
        Text(
          dua.ref,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.gray400,
          ),
        ),
      ],
    ),
  );
}
