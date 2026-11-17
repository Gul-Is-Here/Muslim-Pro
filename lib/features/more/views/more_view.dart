import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/core/widgets/star_lattice.dart';
import 'package:quran_pro/data/models/adhkar.dart';
import 'package:quran_pro/features/home/views/widgets/home_bottom_nav.dart';
import 'package:quran_pro/features/more/viewmodels/more_view_model.dart';

/// The profile tab: who is signed in, their progress, tools, settings and sources.
final class MoreView extends GetView<MoreViewModel> {
  const MoreView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    extendBody: true,
    bottomNavigationBar: const HomeBottomNav(current: NavTab.more),
    body: SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 4, 16),
            child: Text(
              'more_profile_title'.tr,
              style: const TextStyle(
                fontSize: 26,
                height: 1.25,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: AppColors.primary,
              ),
            ),
          ),
          _ProfileCard(onSignIn: () => unawaited(_confirmSignOut(context))),
          const SizedBox(height: 14),
          const _JourneyCard(),
          const SizedBox(height: 28),
          _Section(title: 'more_tools'.tr),
          const _ToolsGrid(),
          const SizedBox(height: 28),
          _Section(title: 'more_settings'.tr),
          _Group(
            children: [
              Obx(
                () => _Row(
                  icon: Icons.translate_rounded,
                  title: 'more_language'.tr,
                  value: controller.languageLabel,
                  onTap: () => _languageSheet(context),
                ),
              ),
              _Row(
                icon: Icons.notifications_active_outlined,
                title: 'prayer_notifications'.tr,
                onTap: controller.openPrayerAlerts,
              ),
              Obx(
                () => _Row(
                  icon: Icons.download_for_offline_outlined,
                  title: 'downloads_title'.tr,
                  value: controller.downloadsLabel,
                  onTap: () => unawaited(_confirmDeleteDownloads(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _Section(title: 'more_about'.tr),
          _Group(
            children: [
              _Row(
                icon: Icons.menu_book_outlined,
                title: 'more_sources'.tr,
                onTap: () => _sourcesSheet(context),
              ),
            ],
          ),
          if (!controller.isGuest) ...[
            const SizedBox(height: 12),
            _Group(
              children: [
                _Row(
                  icon: Icons.logout_rounded,
                  title: 'more_sign_out'.tr,
                  color: _danger,
                  onTap: () => unawaited(_confirmSignOut(context)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 36),
          const _Footer(),
        ],
      ),
    ),
  );

  void _languageSheet(BuildContext context) => unawaited(
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final l in MoreViewModel.languages)
              ListTile(
                title: Text(l.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: l.code == controller.languageCode
                    ? const Icon(Icons.check_rounded, color: AppColors.emerald700)
                    : null,
                onTap: () {
                  Navigator.pop(c);
                  unawaited(controller.setLanguage(l.code));
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );

  Future<void> _confirmDeleteDownloads(BuildContext context) async {
    if (controller.downloadedSurahs == 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('downloads_delete_all_title'.tr),
        content: Text('download_delete_body'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('cancel'.tr)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text('download_remove'.tr)),
        ],
      ),
    );
    if (ok ?? false) await controller.deleteAllDownloads();
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text((controller.isGuest ? 'more_sign_in' : 'more_sign_out').tr),
        content: Text((controller.isGuest ? 'more_sign_in_body' : 'more_sign_out_body').tr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('cancel'.tr)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text('continue'.tr)),
        ],
      ),
    );
    if (ok ?? false) await controller.signOut();
  }

  void _sourcesSheet(BuildContext context) => unawaited(
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Text(
              'more_sources'.tr,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            for (final (title, body) in const [
              ('Quran text', 'Tanzil Project, Uthmani script'),
              ('Translations', 'Saheeh International (English) · Fateh Muhammad Jalandhry (Urdu)'),
              ('Recitation', 'Mishary Rashid Alafasy, via EveryAyah.com'),
              ('Adhkar and duas', 'Hisn al-Muslim by Sa‘id ibn Wahf al-Qahtani, hisnmuslim.com'),
              ('Prayer times', 'Calculated on the device with the adhan library'),
              ('Letter sounds', 'Al-Bustan Seeds'),
              ('Kalima recitations', 'nooresunnat.com'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gray900),
                    ),
                    Text(body, style: const TextStyle(height: 1.5, color: AppColors.gray500)),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

const _danger = Color(0xFFB42318);

/// Who is signed in, on the app's jewel green with a faint star lattice.
final class _ProfileCard extends GetView<MoreViewModel> {
  const _ProfileCard({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [AppColors.jewelTop, AppColors.primaryContainer, AppColors.jewelBottom],
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.emerald950.withValues(alpha: 0.2),
          blurRadius: 28,
          offset: const Offset(0, 12),
          spreadRadius: -10,
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        children: [
          const Positioned.fill(child: StarLattice(cell: 46, opacity: 0.055)),
          PositionedDirectional(
            top: -90,
            end: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.mint.withValues(alpha: 0.16), Colors.transparent],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  spacing: 14,
                  children: [
                    const _Avatar(),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'السَّلَامُ عَلَيْكُم',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 15,
                              height: 1.3,
                              color: AppColors.amber300.withValues(alpha: 0.95),
                            ),
                          ),
                          Text(
                            controller.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            controller.email ?? 'more_guest_body'.tr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: AppColors.emerald100.withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
                  ),
                  child: Obx(
                    () => IntrinsicHeight(
                      child: Row(
                        children: [
                          _Stat(value: controller.lessonsDone, labelKey: 'more_stat_lessons'),
                          const _StatDivider(),
                          _Stat(value: controller.savedAyahs, labelKey: 'more_stat_saved'),
                          const _StatDivider(),
                          _Stat(value: controller.totalXp, labelKey: 'more_stat_xp'),
                        ],
                      ),
                    ),
                  ),
                ),
                if (controller.isGuest) ...[
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: onSignIn,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(46),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    child: Text('more_sign_in'.tr),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Streak, the last seven days and the level, from the Learn progress kept on this phone.
final class _JourneyCard extends GetView<MoreViewModel> {
  const _JourneyCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.gray100),
    ),
    child: Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'more_journey'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gray900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 10, 4),
                decoration: BoxDecoration(
                  color: AppColors.amber50,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.amber200.withValues(alpha: 0.7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 3,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 15,
                      color: AppColors.amber600,
                    ),
                    Text(
                      'more_streak_days'.trParams({'n': '${controller.streakDays}'}),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.amber800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [for (final d in controller.lastSevenDays) Expanded(child: _Day(day: d))],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'more_level'.trParams({'n': '${controller.level}'}),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'more_xp_to_next'.trParams({
                    'xp': '${controller.xpToNextLevel}',
                    'next': '${controller.level + 1}',
                  }),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: controller.levelProgress,
              minHeight: 8,
              backgroundColor: AppColors.emerald50,
              color: AppColors.emerald500,
            ),
          ),
        ],
      ),
    ),
  );
}

final class _Day extends StatelessWidget {
  const _Day({required this.day});

  final ({String label, bool active, bool today}) day;

  @override
  Widget build(BuildContext context) => Column(
    spacing: 6,
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: day.active ? AppColors.emerald700 : AppColors.gray100,
          border: day.today && !day.active ? Border.all(color: AppColors.amber400, width: 2) : null,
        ),
        child: day.active ? const Icon(Icons.check_rounded, size: 17, color: Colors.white) : null,
      ),
      Text(
        day.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: day.today ? FontWeight.w800 : FontWeight.w600,
          color: day.today ? AppColors.emerald800 : AppColors.gray500,
        ),
      ),
    ],
  );
}

final class _Avatar extends GetView<MoreViewModel> {
  const _Avatar();

  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 64,
    padding: const EdgeInsets.all(2.5),
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.mint, AppColors.amber300],
      ),
    ),
    child: Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryContainer),
      child: controller.initials.isEmpty
          ? const Icon(Icons.person_rounded, color: AppColors.mint, size: 30)
          : Text(
              controller.initials,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.mint,
              ),
            ),
    ),
  );
}

final class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.labelKey});

  final int value;
  final String labelKey;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      spacing: 2,
      children: [
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          labelKey.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
      ],
    ),
  );
}

final class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) =>
      VerticalDivider(width: 1, thickness: 1, color: Colors.white.withValues(alpha: 0.1));
}

final class _ToolsGrid extends GetView<MoreViewModel> {
  const _ToolsGrid();

  @override
  Widget build(BuildContext context) {
    final tools = [
      (Icons.explore_outlined, 'qibla_finder'.tr, controller.openQibla, AppColors.emerald800),
      (Icons.fingerprint, 'digital_tasbeeh'.tr, controller.openTasbeeh, AppColors.primaryContainer),
      (Icons.wb_twilight_rounded, 'hisnul_muslim'.tr, controller.openAdhkar, AppColors.teal800),
      (
        Icons.bedtime_outlined,
        'adhkar_cat_sleep'.tr,
        () => controller.openAdhkar(AdhkarCategory.sleep),
        AppColors.teal900,
      ),
      (Icons.nightlight_round, 'ramadan_title'.tr, controller.openRamadan, AppColors.amber800),
      (
        Icons.mosque_outlined,
        'adhkar_cat_afterSalah'.tr,
        () => controller.openAdhkar(AdhkarCategory.afterSalah),
        AppColors.emerald700,
      ),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      padding: EdgeInsets.zero, // else it inherits the floating nav's inset as a gap
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.98,
      children: [
        for (final (icon, label, onTap, color) in tools)
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppColors.gray100),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(icon, size: 21, color: color),
                    ),
                    Text(
                      label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

final class _Section extends StatelessWidget {
  const _Section({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 10),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w800,
        color: AppColors.gray500,
      ),
    ),
  );
}

final class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.gray100),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (final (i, c) in children.indexed) ...[
          if (i > 0) const Divider(height: 1, indent: 62, color: AppColors.gray100),
          c,
        ],
      ],
    ),
  );
}

final class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;

  /// Set for a destructive row (sign out); otherwise the app's green.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.emerald800;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 10, 12),
        child: Row(
          spacing: 14,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: tint),
            ),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color ?? AppColors.gray900,
                ),
              ),
            ),
            if (value != null)
              Text(value!, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
            if (color == null) const Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}

/// A short dua, the brand and the request, quietly closing the page.
final class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      spacing: 4,
      children: [
        const Text(
          'رَبَّنَا تَقَبَّلْ مِنَّا',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontFamily: 'Amiri', fontSize: 22, color: AppColors.primary),
        ),
        Text(
          'more_footer_dua'.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.gray500),
        ),
        const SizedBox(height: 14),
        Text(
          'Noor  ·  ${'more_dua_request_body'.tr}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11.5, height: 1.5, color: AppColors.gray400),
        ),
      ],
    ),
  );
}
