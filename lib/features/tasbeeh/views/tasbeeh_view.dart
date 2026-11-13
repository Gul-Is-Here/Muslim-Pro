import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/core/theme/app_text_styles.dart';
import 'package:quran_pro/data/models/tasbeeh.dart';
import 'package:quran_pro/features/tasbeeh/viewmodels/tasbeeh_view_model.dart';
import 'package:quran_pro/features/tasbeeh/views/widgets/tasbeeh_counter.dart';
import 'package:quran_pro/features/tasbeeh/views/widgets/tasbeeh_sections.dart';

final class TasbeehView extends GetView<TasbeehViewModel> {
  const TasbeehView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          'digital_tasbeeh'.tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'reset_count'.tr,
            icon: Icon(Icons.restart_alt, color: scheme.onSurfaceVariant),
            onPressed: () => confirmReset(context, controller),
          ),
          IconButton(
            tooltip: 'tasbeeh_history'.tr,
            icon: Icon(Icons.insights, color: scheme.onSurfaceVariant),
            onPressed: () => showTasbeehHistory(context, controller),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 32),
          children: const [
            _DhikrChips(),
            SizedBox(height: 8),
            _DhikrCard(),
            SizedBox(height: 16),
            Center(child: TasbeehCounter()),
            SizedBox(height: 8),
            _Totals(),
            SizedBox(height: 16),
            _TargetSelector(),
            SizedBox(height: 8),
            _Controls(),
            SizedBox(height: 16),
            DailyGoalCard(),
            SizedBox(height: 16),
            FinishButton(),
          ],
        ),
      ),
    );
  }
}

final class _DhikrChips extends GetView<TasbeehViewModel> {
  const _DhikrChips();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44,
      child: Obx(() {
        final selected = controller.dhikr;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: Dhikr.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final d = Dhikr.values[i];
            final on = d == selected;
            return ChoiceChip(
              selected: on,
              onSelected: (_) => controller.selectDhikr(d),
              label: Text(d.transliteration),
              showCheckmark: true,
              checkmarkColor: AppColors.mint,
              selectedColor: AppColors.primaryContainer,
              backgroundColor: scheme.surfaceContainerLow,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: on ? Colors.white : scheme.onSurfaceVariant,
              ),
            );
          },
        );
      }),
    );
  }
}

final class _DhikrCard extends GetView<TasbeehViewModel> {
  const _DhikrCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -40,
            top: -40,
            child: Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.emerald200.withValues(alpha: 0.35), Colors.transparent],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() {
              final d = controller.dhikr;
              return Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      d.arabic,
                      key: ValueKey(d),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: AppTextStyles.quranArabic.copyWith(
                        fontSize: 32,
                        height: 1.6,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        d.transliteration,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      CircleAvatar(radius: 2, backgroundColor: scheme.outlineVariant),
                      Text(
                        d.meaningKey.tr,
                        style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (d.postSalah)
                        _Pill(
                          icon: Icons.spa,
                          text: 'tasbeeh_post_salah'.tr,
                          bg: AppColors.mint.withValues(alpha: 0.4),
                          fg: AppColors.emerald950,
                          iconColor: AppColors.emerald800,
                        ),
                      _Pill(
                        icon: Icons.flag,
                        text: 'tasbeeh_target'.trParams({
                          'n': controller.state.unlimited
                              ? 'tasbeeh_no_limit'.tr
                              : controller.targetLabel,
                        }),
                        bg: const Color(0xFFFFDCC3),
                        fg: const Color(0xFF2F1500),
                        iconColor: const Color(0xFF904D00),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

final class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.text,
    required this.bg,
    required this.fg,
    required this.iconColor,
  });

  final IconData icon;
  final String text;
  final Color bg;
  final Color fg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Icon(icon, size: 13, color: iconColor),
        Text(
          text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
        ),
      ],
    ),
  );
}

final class _Totals extends GetView<TasbeehViewModel> {
  const _Totals();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget stat(IconData icon, Color color, String key, int n) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Icon(icon, size: 16, color: color),
        Text(
          key.trParams({'n': '$n'}),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          stat(Icons.timelapse, const Color(0xFF904D00), 'session_total', controller.state.session),
          stat(Icons.done_all, AppColors.emerald700, 'today_total', controller.todayTotal),
        ],
      ),
    );
  }
}

final class _TargetSelector extends GetView<TasbeehViewModel> {
  const _TargetSelector();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(
      () => SegmentedButton<int>(
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          backgroundColor: scheme.surfaceContainerLow,
          foregroundColor: scheme.onSurfaceVariant,
          selectedBackgroundColor: scheme.surfaceContainerLowest,
          selectedForegroundColor: AppColors.primary,
          side: BorderSide.none,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        segments: [
          for (final t in TasbeehState.targets)
            ButtonSegment(
              value: t,
              tooltip: t == 0 ? 'tasbeeh_no_limit'.tr : null,
              label: t == 0 ? const Icon(Icons.all_inclusive, size: 18) : Text('$t'),
            ),
        ],
        selected: {controller.state.target},
        onSelectionChanged: (s) => controller.selectTarget(s.first),
      ),
    );
  }
}

final class _Controls extends GetView<TasbeehViewModel> {
  const _Controls();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      final s = controller.state;
      return Row(
        spacing: 8,
        children: [
          _ControlTile(
            icon: s.haptics ? Icons.vibration : Icons.smartphone,
            color: s.haptics ? AppColors.emerald700 : scheme.outline,
            label: 'haptics'.tr,
            selected: s.haptics,
            onTap: controller.toggleHaptics,
          ),
          _ControlTile(
            icon: s.sound ? Icons.volume_up : Icons.volume_off,
            color: s.sound ? const Color(0xFF904D00) : scheme.outline,
            label: 'chime'.tr,
            selected: s.sound,
            onTap: controller.toggleSound,
          ),
          _ControlTile(
            icon: Icons.undo,
            color: scheme.onSurfaceVariant,
            label: 'undo'.tr,
            onTap: s.count == 0 ? null : controller.undo,
          ),
          _ControlTile(
            icon: Icons.refresh,
            color: scheme.error,
            label: 'reset'.tr,
            labelColor: scheme.error,
            onTap: () => confirmReset(context, controller),
          ),
        ],
      );
    });
  }
}

final class _ControlTile extends StatelessWidget {
  const _ControlTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.selected,
    this.labelColor,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;
  final bool? selected; // toggles only
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Semantics(
        toggled: selected,
        child: Material(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          elevation: 0.5,
          shadowColor: Colors.black26,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Opacity(
              opacity: onTap == null ? 0.4 : 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  spacing: 4,
                  children: [
                    Icon(icon, size: 20, color: color),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: labelColor ?? scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void confirmReset(BuildContext context, TasbeehViewModel vm) {
  if (vm.state.count == 0 && vm.state.round == 1) return; // nothing to reset
  unawaited(
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('reset_count_title'.tr),
        content: Text('reset_count_body'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr)),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              vm.reset();
            },
            child: Text('reset'.tr),
          ),
        ],
      ),
    ),
  );
}
