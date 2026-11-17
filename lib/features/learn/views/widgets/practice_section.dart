import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/features/learn/viewmodels/learn_view_model.dart';
import 'package:quran_pro/features/learn/views/widgets/learn_colors.dart';
import 'package:quran_pro/features/learn/views/widgets/lessons_sheet.dart';

/// "Quick Practice Hub": Qaida letter pad, daily quiz, and the closing hadith.
final class PracticeSection extends GetView<LearnViewModel> {
  const PracticeSection({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          spacing: 6,
          children: [
            const Icon(Icons.bolt, size: 20, color: LearnColors.gold),
            Expanded(
              child: Text(
                'practice_hub'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: LearnColors.onSurface,
                ),
              ),
            ),
            TextButton(
              onPressed: () => showLessonsSheet(context, controller),
              style: TextButton.styleFrom(
                foregroundColor: LearnColors.gold,
                textStyle: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text('review_all'.tr),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      const _QaidaCard(),
      const SizedBox(height: 8),
      const _QuizCard(),
      const SizedBox(height: 24),
      const _HadithNote(),
    ],
  );
}

final class _QaidaCard extends GetView<LearnViewModel> {
  const _QaidaCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: LearnColors.shadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: LearnColors.primaryFixedDim.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ض',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: LearnColors.primary,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'qaida_title'.tr,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: LearnColors.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: LearnColors.goldContainer,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          'makhraj'.tr,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: LearnColors.onGoldContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'qaida_desc'.tr,
                    style: const TextStyle(fontSize: 13, height: 1.4, color: LearnColors.onVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: LearnColors.low,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Obx(
            () => GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.78,
              children: [
                for (final l in controller.letters)
                  _LetterKey(letter: l, onTap: () => controller.tapLetter(l)),
              ],
            ),
          ),
        ),
        Obx(() {
          final l = controller.letter;
          return AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: l == null
                ? const SizedBox(width: double.infinity)
                : Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: LearnColors.goldFixed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${l.glyph}  ${l.name} · ${l.makhraj}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: LearnColors.onGoldFixed,
                      ),
                    ),
                  ),
          );
        }),
      ],
    ),
  );
}

final class _LetterKey extends GetView<LearnViewModel> {
  const _LetterKey({required this.letter, required this.onTap});

  final QaidaLetter letter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Obx(() {
    final active = controller.letter == letter;
    return Material(
      color: active ? LearnColors.primaryFixed : Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 0.5,
      shadowColor: const Color(0x330F5C4A),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                letter.glyph,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 22,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: LearnColors.primary,
                ),
              ),
              Text(
                letter.name,
                maxLines: 1, // "Haa (soft)" wrapped and overflowed the cell
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: LearnColors.onVariant),
              ),
            ],
          ),
        ),
      ),
    );
  });
}

final class _QuizCard extends GetView<LearnViewModel> {
  const _QuizCard();

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: LearnColors.shadow,
      gradient: const LinearGradient(colors: [LearnColors.primaryContainer, LearnColors.primary]),
    ),
    child: Stack(
      children: [
        PositionedDirectional(
          end: -20,
          top: -10,
          bottom: -10,
          child: Icon(Icons.star, size: 140, color: Colors.white.withValues(alpha: 0.08)),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: LearnColors.gold,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'double_xp'.tr.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Icon(Icons.timer_outlined, size: 16, color: LearnColors.goldFixed),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'quiz_title'.tr,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'quiz_desc'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: LearnColors.primaryFixed.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Obx(
                () => FilledButton(
                  onPressed: controller.quizDone ? null : controller.startQuiz,
                  style: FilledButton.styleFrom(
                    backgroundColor: LearnColors.gold,
                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.15),
                    disabledForegroundColor: LearnColors.goldFixed,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: controller.quizDone
                        ? [const Icon(Icons.check, size: 18), Text('done_today'.tr)]
                        : [Text('start'.tr), const Icon(Icons.arrow_forward, size: 18)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _HadithNote extends StatelessWidget {
  const _HadithNote();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: LearnColors.low, borderRadius: BorderRadius.circular(12)),
    child: Row(
      spacing: 12,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(color: LearnColors.goldFixed, shape: BoxShape.circle),
          child: const Icon(Icons.lightbulb_outline, size: 20, color: LearnColors.onGoldFixed),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                'hadith_learn'.tr,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: LearnColors.onSurface,
                ),
              ),
              Text(
                'hadith_learn_ref'.tr,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: LearnColors.gold,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
