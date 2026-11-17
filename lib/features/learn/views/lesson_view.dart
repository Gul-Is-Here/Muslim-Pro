import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/features/learn/viewmodels/lesson_view_model.dart';
import 'package:quran_pro/features/learn/views/widgets/learn_colors.dart';

/// Lesson player: teaching cards, then questions until each is answered correctly.
final class LessonView extends GetView<LessonViewModel> {
  const LessonView({super.key});

  Future<void> _close(BuildContext context) async {
    if (!controller.hasProgress) return Get.back<void>();
    final quit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('quit_lesson_title'.tr),
        content: Text('quit_lesson_body'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('keep_learning'.tr)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: LearnColors.error),
            child: Text('quit'.tr),
          ),
        ],
      ),
    );
    if (quit ?? false) Get.back<void>();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(_close(context));
    },
    child: Scaffold(
      backgroundColor: LearnColors.surface,
      body: SafeArea(
        child: Obx(
          () => Column(
            children: [
              if (controller.phase case LessonPhase.cards || LessonPhase.question)
                _TopBar(onClose: () => _close(context)),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: switch (controller.phase) {
                    LessonPhase.loading => const Center(
                      child: CircularProgressIndicator(color: LearnColors.primary),
                    ),
                    LessonPhase.cards => _CardStep(key: ValueKey('c${controller.cardIndex}')),
                    LessonPhase.question => _QuestionStep(
                      key: ValueKey('q${controller.question.hashCode}'),
                    ),
                    LessonPhase.finished => const _Result(),
                    LessonPhase.outOfHearts => const _OutOfHearts(),
                    LessonPhase.unavailable => _Message(
                      icon: Icons.cloud_off,
                      title: 'lesson_unavailable'.tr,
                      body: '',
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

final class _TopBar extends GetView<LessonViewModel> {
  const _TopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Obx(
    () => Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'close'.tr,
            onPressed: onClose,
            icon: const Icon(Icons.close, color: LearnColors.onVariant),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: controller.progress),
                duration: const Duration(milliseconds: 300),
                builder: (_, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 10,
                  backgroundColor: LearnColors.container,
                  color: LearnColors.primaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          if (controller.costsHearts) ...[
            const Icon(Icons.favorite, size: 20, color: LearnColors.error),
            const SizedBox(width: 4),
            Text(
              '${controller.hearts}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ] else
            Text(
              'review'.tr,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: LearnColors.gold,
              ),
            ),
        ],
      ),
    ),
  );
}

final class _CardStep extends GetView<LessonViewModel> {
  const _CardStep({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller.card!;
    final last = controller.cardIndex == controller.cardCount - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              Text(
                '${controller.cardIndex + 1} / ${controller.cardCount}  ·  ${controller.title}'
                    .toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: LearnColors.gold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                controller.text(c.title),
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: LearnColors.onSurface,
                ),
              ),
              if (c.arabic != null) ...[
                const SizedBox(height: 20),
                _ArabicPanel(
                  arabic: c.arabic!,
                  translit: c.translit,
                  onPlay: controller.canPlay(c.arabic!)
                      ? () => controller.playArabic(c.arabic!)
                      : null,
                ),
              ],
              const SizedBox(height: 20),
              Text(
                controller.text(c.body),
                style: const TextStyle(fontSize: 16, height: 1.6, color: LearnColors.onVariant),
              ),
              if (c.ref != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.menu_book_outlined, size: 16, color: LearnColors.outline),
                    const SizedBox(width: 6),
                    Text(
                      c.ref!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: LearnColors.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        _BottomBar(
          children: [
            if (controller.cardIndex > 0) ...[
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: controller.previousCard,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LearnColors.primary,
                    side: const BorderSide(color: LearnColors.highest),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Icon(Icons.arrow_back),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: _PrimaryButton(
                label: (last ? 'start_quiz' : 'continue').tr,
                onPressed: controller.nextCard,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Arabic text on a parchment panel, with its transliteration underneath.
final class _ArabicPanel extends StatelessWidget {
  const _ArabicPanel({required this.arabic, this.translit, this.onPlay});

  final String arabic;
  final String? translit;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final single = arabic.runes.length <= 2; // a lone Qaida letter reads better huge
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: LearnColors.goldFixed),
    );
    return Material(
      color: Colors.white,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onPlay, // the whole panel plays, not just the speaker button
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            children: [
              Text(
                arabic,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: single ? 72 : 26,
                  height: single ? 1.4 : 2,
                  fontWeight: FontWeight.w700,
                  color: LearnColors.primary,
                ),
              ),
              if (onPlay != null)
                IconButton.filledTonal(
                  tooltip: 'listen'.tr,
                  onPressed: onPlay,
                  style: IconButton.styleFrom(
                    backgroundColor: LearnColors.primaryFixed.withValues(alpha: 0.5),
                    foregroundColor: LearnColors.primary,
                  ),
                  icon: const Icon(Icons.volume_up),
                ),
              if (translit != null) ...[
                const SizedBox(height: 8),
                Text(
                  translit!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    color: LearnColors.onVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class _QuestionStep extends GetView<LessonViewModel> {
  const _QuestionStep({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    final q = controller.question;
    if (q == null) return const SizedBox.shrink(); // queue just emptied; results are next
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              Text(
                controller.text(q.prompt),
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: LearnColors.onSurface,
                ),
              ),
              if (q.arabic != null) ...[
                const SizedBox(height: 16),
                _ArabicPanel(
                  arabic: q.arabic!,
                  onPlay: controller.canPlay(q.arabic!)
                      ? () => controller.playArabic(q.arabic!)
                      : null,
                ),
              ],
              const SizedBox(height: 20),
              for (final (i, label) in controller.options.indexed) ...[
                _Option(index: i, label: label),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        if (controller.checked)
          const _Feedback()
        else
          _BottomBar(
            children: [
              Expanded(
                child: _PrimaryButton(
                  label: 'check'.tr,
                  onPressed: controller.selected == null ? null : controller.check,
                ),
              ),
            ],
          ),
      ],
    );
  });
}

final class _Option extends GetView<LessonViewModel> {
  const _Option({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) => Obx(() {
    final selected = controller.selected == index;
    final checked = controller.checked;
    final isAnswer = index == controller.answerIndex;
    final (border, fill) = switch ((checked, selected, isAnswer)) {
      (true, _, true) => (const Color(0xFF1E8E5A), const Color(0xFFE6F4EC)),
      (true, true, false) => (LearnColors.error, const Color(0xFFFDECEA)),
      (false, true, _) => (
        LearnColors.primaryContainer,
        LearnColors.primaryFixed.withValues(alpha: 0.35),
      ),
      _ => (LearnColors.highest, Colors.white),
    };
    final arabicGlyph = label.runes.length <= 2 && RegExp('[؀-ۿ]').hasMatch(label);
    return Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: border, width: selected || (checked && isAnswer) ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: checked ? null : () => controller.select(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  textAlign: arabicGlyph ? TextAlign.center : TextAlign.start,
                  style: arabicGlyph
                      ? const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 34,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          color: LearnColors.primary,
                        )
                      : const TextStyle(
                          fontSize: 16,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: LearnColors.onSurface,
                        ),
                ),
              ),
              if (checked && isAnswer)
                const Icon(Icons.check_circle, color: Color(0xFF1E8E5A))
              else if (checked && selected)
                const Icon(Icons.cancel, color: LearnColors.error),
            ],
          ),
        ),
      ),
    );
  });
}

final class _Feedback extends GetView<LessonViewModel> {
  const _Feedback();

  @override
  Widget build(BuildContext context) {
    final ok = controller.isCorrect;
    final color = ok ? const Color(0xFF1E8E5A) : LearnColors.error;
    return Container(
      color: ok ? const Color(0xFFE6F4EC) : const Color(0xFFFDECEA),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            spacing: 8,
            children: [
              Icon(ok ? Icons.check_circle : Icons.info, color: color),
              Text(
                (ok ? 'correct' : 'not_quite').tr,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
          if (!ok) ...[
            const SizedBox(height: 6),
            Text(
              'answer_is'.trParams({'answer': controller.correctAnswer}),
              style: TextStyle(fontSize: 14, height: 1.4, color: color),
            ),
            Text(
              'will_repeat'.tr,
              style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: _PrimaryButton(label: 'continue'.tr, onPressed: controller.next, color: color),
          ),
        ],
      ),
    );
  }
}

final class _Result extends GetView<LessonViewModel> {
  const _Result();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: LearnColors.goldFixed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium, size: 52, color: LearnColors.gold),
                ),
                const SizedBox(height: 20),
                Text(
                  (controller.isQuiz
                          ? 'quiz_complete'
                          : controller.isReview
                          ? 'review_complete'
                          : 'lesson_complete')
                      .tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: LearnColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  controller.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: LearnColors.onVariant),
                ),
                const SizedBox(height: 28),
                Row(
                  spacing: 10,
                  children: [
                    _Stat(
                      icon: Icons.stars,
                      value: '+${controller.xpEarned}',
                      label: 'xp_unit'.tr,
                      color: LearnColors.gold,
                    ),
                    _Stat(
                      icon: Icons.track_changes,
                      value: '${controller.accuracy}%',
                      label: 'accuracy'.tr,
                      color: LearnColors.primaryContainer,
                    ),
                    _Stat(
                      icon: Icons.local_fire_department,
                      value: '${controller.streak}',
                      label: 'streak_days'.tr,
                      color: const Color(0xFFD9822B),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      _BottomBar(
        children: [
          Expanded(
            child: _PrimaryButton(label: 'continue'.tr, onPressed: Get.back<void>),
          ),
        ],
      ),
    ],
  );
}

final class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label, required this.color});

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        spacing: 4,
        children: [
          Icon(icon, size: 22, color: color),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: LearnColors.onSurface,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 11, color: LearnColors.onVariant)),
        ],
      ),
    ),
  );
}

final class _OutOfHearts extends GetView<LessonViewModel> {
  const _OutOfHearts();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: _Message(
          icon: Icons.heart_broken,
          title: 'out_of_hearts'.tr,
          body: 'out_of_hearts_body'.trParams({'time': controller.nextHeartLabel ?? '--:--'}),
        ),
      ),
      _BottomBar(
        children: [
          Expanded(
            child: _PrimaryButton(label: 'back_to_path'.tr, onPressed: Get.back<void>),
          ),
        ],
      ),
    ],
  );
}

final class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Icon(icon, size: 64, color: LearnColors.error),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          if (body.isNotEmpty)
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.5, color: LearnColors.onVariant),
            ),
        ],
      ),
    ),
  );
}

final class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: LearnColors.container)),
    ),
    child: Row(children: children),
  );
}

final class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed, this.color});

  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color ?? LearnColors.primary,
        disabledBackgroundColor: LearnColors.container,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(label),
    ),
  );
}
