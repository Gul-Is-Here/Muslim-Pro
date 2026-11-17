import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/features/home/views/widgets/home_bottom_nav.dart';
import 'package:quran_pro/features/home/views/widgets/home_header.dart';
import 'package:quran_pro/features/quran/viewmodels/quran_view_model.dart';
import 'package:quran_pro/features/quran/views/widgets/featured_surah_card.dart';
import 'package:quran_pro/features/quran/views/widgets/quran_tiles.dart';

final class QuranView extends GetView<QuranViewModel> {
  const QuranView({super.key});

  static const _gutter = EdgeInsets.symmetric(horizontal: 16);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    extendBody: true, // the list scrolls under the floating nav
    bottomNavigationBar: const HomeBottomNav(current: NavTab.quran),
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const HomeHeader(),
          Expanded(
            child: GestureDetector(
              onTap: FocusScope.of(context).unfocus, // tapping the list closes the keyboard
              behavior: HitTestBehavior.translucent,
              child: Obx(() {
                if (controller.loading) return const Center(child: CircularProgressIndicator());
                if (controller.failed) return const _LoadFailed();
                final searching = controller.query.trim().isNotEmpty;
                return CustomScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                      sliver: SliverToBoxAdapter(child: _TitleRow()),
                    ),
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverToBoxAdapter(child: _SearchField()),
                    ),
                    if (!searching && controller.lastRead != null)
                      const SliverPadding(
                        padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                        sliver: SliverToBoxAdapter(child: _ContinueReading()),
                      ),
                    if (!searching)
                      const SliverPadding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                        sliver: SliverToBoxAdapter(child: FeaturedSurahCard()),
                      ),
                    if (!searching)
                      const SliverPadding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                        sliver: SliverToBoxAdapter(child: _DownloadAllCard()),
                      ),
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                      sliver: SliverToBoxAdapter(child: _Tabs()),
                    ),
                    ..._results(),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)), // clear of the nav
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    ),
  );

  List<Widget> _results() {
    if (controller.tab == QuranTab.surah) {
      final list = controller.surahs;
      if (list.isEmpty) return const [SliverToBoxAdapter(child: _NoResults())];
      return [
        SliverPadding(
          padding: _gutter,
          sliver: SliverList.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => SurahTile(list[i]),
          ),
        ),
      ];
    }
    final list = controller.juz;
    if (list.isEmpty) return const [SliverToBoxAdapter(child: _NoResults())];
    return [
      SliverPadding(
        padding: _gutter,
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 96,
          ),
          itemCount: list.length,
          itemBuilder: (_, i) => JuzTile(list[i]),
        ),
      ),
    ];
  }
}

final class _TitleRow extends StatelessWidget {
  const _TitleRow();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'quran_eyebrow'.tr.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'quran_title'.tr,
              style: const TextStyle(
                fontSize: 26,
                height: 1.25,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'الْقُرْآنُ الْكَرِيمُ',
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: 'Amiri', fontSize: 20, color: AppColors.primary),
          ),
          Text(
            'quran_riwayah'.tr.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
              color: AppColors.amber700,
            ),
          ),
        ],
      ),
    ],
  );
}

/// Where the reader stopped last time, one tap away.
final class _ContinueReading extends GetView<QuranViewModel> {
  const _ContinueReading();

  @override
  Widget build(BuildContext context) {
    final r = controller.lastRead!;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => controller.openSurah(r.surah, ayah: r.ayah),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.emerald100),
          ),
          child: Row(
            spacing: 12,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history_rounded, color: AppColors.emerald700),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'quran_continue'.tr.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                        color: AppColors.amber700,
                      ),
                    ),
                    Text(
                      'quran_continue_at'.trParams({
                        'name': controller.surahName(r.surah),
                        'n': '${r.ayah}',
                      }),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
            ],
          ),
        ),
      ),
    );
  }
}

final class _SearchField extends GetView<QuranViewModel> {
  const _SearchField();

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller.searchController,
    onChanged: controller.search,
    textInputAction: TextInputAction.search,
    style: const TextStyle(fontSize: 15, color: AppColors.gray900),
    decoration: InputDecoration(
      hintText: 'quran_search_hint'.tr,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.gray400),
      prefixIcon: const Icon(Icons.search, color: AppColors.gray500),
      suffixIcon: Obx(
        () => controller.query.isEmpty
            ? const _ReciterChip()
            : IconButton(
                tooltip: 'clear'.tr,
                onPressed: controller.clearSearch,
                icon: const Icon(Icons.close, color: AppColors.gray500),
              ),
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.gray200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.gray200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.emerald500, width: 1.5),
      ),
    ),
  );
}

/// Which recitation the play buttons use. Information only: there is one reciter for now.
final class _ReciterChip extends StatelessWidget {
  const _ReciterChip();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 8),
    child: Tooltip(
      message: 'quran_reciter_full'.tr,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.emerald50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 5,
          children: [
            const Icon(Icons.graphic_eq, size: 16, color: AppColors.amber700),
            Text(
              'quran_reciter_short'.tr,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

final class _Tabs extends GetView<QuranViewModel> {
  const _Tabs();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(14)),
    child: Obx(
      () => Row(
        children: [
          for (final (tab, key, count) in [
            (QuranTab.surah, 'quran_tab_surah', controller.surahs.length),
            (QuranTab.juz, 'quran_tab_juz', controller.juz.length),
          ])
            Expanded(
              child: _TabButton(
                label: '${key.tr}  $count',
                selected: controller.tab == tab,
                onTap: () => controller.selectTab(tab),
              ),
            ),
        ],
      ),
    ),
  );
}

final class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? AppColors.primary : AppColors.gray500,
          ),
        ),
      ),
    ),
  );
}

final class _NoResults extends GetView<QuranViewModel> {
  const _NoResults();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
    child: Column(
      spacing: 8,
      children: [
        const Icon(Icons.search_off, size: 36, color: AppColors.gray400),
        Text(
          'quran_no_results'.trParams({'q': controller.query.trim()}),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.gray500),
        ),
      ],
    ),
  );
}

final class _LoadFailed extends GetView<QuranViewModel> {
  const _LoadFailed();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        Text('quran_load_failed'.tr, style: const TextStyle(color: AppColors.gray500)),
        OutlinedButton(onPressed: controller.load, child: Text('retry'.tr)),
      ],
    ),
  );
}

/// One place to save the whole Quran for offline listening, with its progress.
final class _DownloadAllCard extends GetView<QuranViewModel> {
  const _DownloadAllCard();

  Future<void> _confirm(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('download_all_confirm_title'.tr),
        content: Text('download_all_confirm_body'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('cancel'.tr)),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text('download_all_start'.tr),
          ),
        ],
      ),
    );
    if (ok ?? false) unawaited(controller.downloadAll());
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final running = controller.downloadingAll;
    final done = controller.allDownloaded;
    final current = controller.currentDownload;
    final total = controller.surahCount;
    final fraction = running
        ? ((controller.downloadedCount + (current?.progress ?? 0)) / total).clamp(0.0, 1.0)
        : controller.downloadedCount / total;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: 12,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  done ? Icons.offline_pin_rounded : Icons.download_for_offline_outlined,
                  size: 21,
                  color: AppColors.emerald800,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      done ? 'download_all_done'.tr : 'download_all'.tr,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gray900,
                      ),
                    ),
                    if (!done)
                      Text(
                        running
                            ? 'download_all_progress'.trParams({
                                'done': '${controller.downloadedCount}',
                                'total': '$total',
                              })
                            : 'download_all_sub'.tr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                      ),
                  ],
                ),
              ),
              if (!done && running)
                TextButton(onPressed: controller.cancelDownloadAll, child: Text('stop'.tr))
              else if (!done)
                IconButton(
                  tooltip: 'download_all'.tr,
                  onPressed: () => unawaited(_confirm(context)),
                  icon: const Icon(Icons.download_rounded, color: AppColors.primary),
                ),
            ],
          ),
          if (running || (controller.downloadedCount > 0 && !done)) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: AppColors.emerald50,
                color: AppColors.emerald500,
              ),
            ),
          ],
        ],
      ),
    );
  });
}
