import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/data/models/tasbeeh.dart';
import 'package:quran_pro/features/tasbeeh/viewmodels/tasbeeh_view_model.dart';

const _brown = Color(0xFF904D00);

final class DailyGoalCard extends GetView<TasbeehViewModel> {
  const DailyGoalCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Row(
              spacing: 10,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB7EDE3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_graph, size: 18, color: Color(0xFF00201C)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'daily_goal'.tr,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'daily_goal_sub'.tr,
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${controller.todayTotal}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${TasbeehState.dailyGoal}',
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              height: 10,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(99),
              ),
              alignment: AlignmentDirectional.centerStart,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 400),
                widthFactor: controller.goalProgress,
                heightFactor: 1,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                    gradient: LinearGradient(
                      colors: [AppColors.primary, Color(0xFF4EDEA3), Color(0xFFFE932C)],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Row(
                    children: [
                      if (controller.streak > 0) ...[
                        const Icon(Icons.local_fire_department, size: 16, color: _brown),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'dhikr_streak'.trParams({'n': '${controller.streak}'}),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _brown,
                            ),
                          ),
                        ),
                      ] else
                        const Spacer(),
                      Text(
                        'hadith_light_ref'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'hadith_light_words'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class FinishButton extends GetView<TasbeehViewModel> {
  const FinishButton({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    final logged = controller.justLogged;
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: logged ? AppColors.emerald800 : AppColors.primaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        onPressed: logged || controller.state.session == 0 ? null : controller.finishSession,
        icon: Icon(logged ? Icons.check_circle : Icons.save, size: 20),
        label: Text((logged ? 'session_logged' : 'finish_session').tr),
      ),
    );
  });
}

void showTasbeehHistory(BuildContext context, TasbeehViewModel vm) => unawaited(
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      final week = vm.week;
      final peak = math.max(1, week.map((d) => d.total).reduce(math.max));
      final sessions = vm.state.sessions;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.75),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 24),
            children: [
              Text('tasbeeh_history'.tr, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              Text('last_7_days'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: 8,
                  children: [
                    for (final d in week)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          spacing: 4,
                          children: [
                            Text(
                              '${d.total}',
                              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                            ),
                            Container(
                              height: 4 + 72 * d.total / peak,
                              decoration: BoxDecoration(
                                color: d.total == 0
                                    ? scheme.surfaceContainerHigh
                                    : AppColors.emerald500,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Text(
                              d.label,
                              maxLines: 1,
                              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('recent_sessions'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (sessions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('no_sessions'.tr, style: TextStyle(color: scheme.onSurfaceVariant)),
                )
              else
                for (final s in sessions.take(10))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_outline, color: AppColors.emerald700),
                    title: Text('session_entry'.trParams({'n': '${s.count}'})),
                    trailing: Text(
                      vm.sessionTime(s.at),
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ),
            ],
          ),
        ),
      );
    },
  ),
);
