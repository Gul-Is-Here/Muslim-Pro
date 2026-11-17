import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/data/models/learn.dart';
import 'package:quran_pro/features/learn/viewmodels/learn_view_model.dart';
import 'package:quran_pro/features/learn/views/widgets/learn_colors.dart';

/// Every lesson (or one [unit]'s) with its status; finished ones open for review.
void showLessonsSheet(BuildContext context, LearnViewModel vm, {LearnUnit? unit}) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: LearnColors.surface,
      builder: (ctx) {
        final units = unit == null ? vm.allUnits : [unit];
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.8),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              children: [
                Text(
                  unit == null ? 'all_lessons'.tr : vm.text(unit.title),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: LearnColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'review_hint'.tr,
                  style: const TextStyle(fontSize: 13, color: LearnColors.onVariant),
                ),
                for (final u in units) ...[
                  if (unit == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 4),
                      child: Text(
                        vm.text(u.title).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: LearnColors.gold,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                  for (final (i, l) in u.lessons.indexed)
                    _LessonTile(
                      number: i + 1,
                      title: vm.text(l.title),
                      done: vm.isDone(l),
                      open: vm.isUnlocked(u),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        vm.openLesson(l);
                      },
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );

final class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.number,
    required this.title,
    required this.done,
    required this.open,
    required this.onTap,
  });

  final int number;
  final String title;
  final bool done;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    enabled: open,
    onTap: onTap,
    leading: CircleAvatar(
      radius: 18,
      backgroundColor: done
          ? LearnColors.gold
          : (open ? LearnColors.primaryFixed : LearnColors.high),
      child: done
          ? const Icon(Icons.check, size: 18, color: Colors.white)
          : open
          ? Text(
              '$number',
              style: const TextStyle(fontWeight: FontWeight.w700, color: LearnColors.primary),
            )
          : const Icon(Icons.lock, size: 16, color: LearnColors.outline),
    ),
    title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    trailing: open
        ? Text(
            (done ? 'review' : 'start').tr,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: LearnColors.primary,
            ),
          )
        : null,
  );
}
