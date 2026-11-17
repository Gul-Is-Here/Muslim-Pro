import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/services/quran_service.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/features/quran/viewmodels/surah_reader_view_model.dart';
import 'package:quran_pro/features/quran/views/widgets/reader_player.dart';
import 'package:quran_pro/features/quran/views/widgets/star_badge.dart';

/// ٥ instead of 5, for the ﴿ ﴾ ayah markers.
String arabicDigits(int n) => n.toString().split('').map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)]).join();

final class SurahReaderView extends GetView<SurahReaderViewModel> {
  const SurahReaderView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    bottomNavigationBar: const ReaderPlayer(),
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _TopBar(),
          Expanded(
            child: Obx(() {
              if (controller.failed) {
                return Center(
                  child: OutlinedButton(onPressed: controller.load, child: Text('retry'.tr)),
                );
              }
              if (controller.loading) return const Center(child: CircularProgressIndicator());
              return _AyahList(controller);
            }),
          ),
        ],
      ),
    ),
  );
}

final class _TopBar extends GetView<SurahReaderViewModel> {
  const _TopBar();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
    child: Row(
      children: [
        const BackButton(color: AppColors.primary),
        Expanded(
          child: Obx(() {
            final i = controller.info;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i?.name ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                if (i != null)
                  Text(
                    '${controller.surah}. ${i.meaning}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                  ),
              ],
            );
          }),
        ),
        const _DownloadButton(),
        IconButton(
          tooltip: 'quran_display'.tr,
          onPressed: () => _showDisplaySheet(context, controller),
          icon: const Icon(Icons.text_fields_rounded, color: AppColors.primary),
        ),
      ],
    ),
  );
}

/// Saves the surah for offline listening: download, progress (tap to cancel), or saved (tap to
/// remove after confirming).
final class _DownloadButton extends GetView<SurahReaderViewModel> {
  const _DownloadButton();

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('download_delete_title'.tr),
        content: Text('download_delete_body'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('cancel'.tr)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text('download_remove'.tr)),
        ],
      ),
    );
    if (ok ?? false) await controller.deleteDownload();
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final progress = controller.downloadProgress;
    if (progress != null) {
      return IconButton(
        tooltip: 'quran_downloading'.tr,
        onPressed: () => unawaited(controller.toggleDownload()),
        icon: SizedBox.square(
          dimension: 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress == 0 ? null : progress,
                strokeWidth: 2.5,
                color: AppColors.emerald700,
                backgroundColor: AppColors.emerald50,
              ),
              const Icon(Icons.stop_rounded, size: 14, color: AppColors.emerald800),
            ],
          ),
        ),
      );
    }
    final saved = controller.downloaded;
    return IconButton(
      tooltip: (saved ? 'quran_downloaded' : 'quran_download').tr,
      onPressed: saved
          ? () => unawaited(_confirmDelete(context))
          : () => unawaited(controller.toggleDownload()),
      icon: Icon(
        saved ? Icons.download_done_rounded : Icons.download_rounded,
        color: saved ? AppColors.emerald700 : AppColors.primary,
      ),
    );
  });
}

/// Every ayah in one column, so any of them can be scrolled to (recitation follow-along,
/// opening at a juz start or the last-read place).
final class _AyahList extends StatefulWidget {
  const _AyahList(this.vm);

  final SurahReaderViewModel vm;

  @override
  State<_AyahList> createState() => _AyahListState();
}

final class _AyahListState extends State<_AyahList> {
  final _scroll = ScrollController();
  final GlobalKey _viewport = GlobalKey();
  SurahReaderViewModel get vm => widget.vm;
  late final List<GlobalKey> _keys = List.generate(vm.ayahCount, (_) => GlobalKey());
  StreamSubscription<int>? _requests;

  @override
  void initState() {
    super.initState();
    _requests = vm.scrollRequests.listen((a) => _bringIntoView(a, animate: true));
    final first = vm.initialAyah;
    if (first != null && first > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _bringIntoView(first, animate: false));
    }
  }

  void _bringIntoView(int ayah, {required bool animate}) {
    final ctx = _keys.elementAtOrNull(ayah - 1)?.currentContext;
    if (ctx == null || !mounted) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.12,
      duration: animate ? const Duration(milliseconds: 450) : Duration.zero,
      curve: Curves.easeOutCubic,
    );
  }

  /// Reports the first ayah whose card reaches the top of the screen.
  bool _onScrollEnd(ScrollEndNotification _) {
    final top = (_viewport.currentContext?.findRenderObject() as RenderBox?)
        ?.localToGlobal(Offset.zero)
        .dy;
    if (top == null) return false;
    for (var i = 0; i < _keys.length; i++) {
      final box = _keys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      if (box.localToGlobal(Offset.zero).dy + box.size.height > top + 8) {
        vm.readingAt(i + 1);
        break;
      }
    }
    return false;
  }

  @override
  void dispose() {
    unawaited(_requests?.cancel());
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NotificationListener<ScrollEndNotification>(
    onNotification: _onScrollEnd,
    child: SingleChildScrollView(
      key: _viewport,
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SurahHeader(),
          for (var a = 1; a <= vm.ayahCount; a++) ...[
            if (vm.juzStartsAt(a)) _JuzDivider(juz: vm.juzOf(a)),
            _AyahCard(key: _keys[a - 1], ayah: a),
          ],
        ],
      ),
    ),
  );
}

final class _SurahHeader extends GetView<SurahReaderViewModel> {
  const _SurahHeader();

  @override
  Widget build(BuildContext context) {
    final i = controller.info!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.jewelTop, AppColors.primaryContainer, AppColors.jewelBottom],
              ),
            ),
            child: Stack(
              children: [
                const PositionedDirectional(
                  start: -40,
                  top: -40,
                  child: SizedBox.square(
                    dimension: 160,
                    child: CustomPaint(painter: StarPainter(Color(0x129CD1C7))),
                  ),
                ),
                const PositionedDirectional(
                  end: -50,
                  bottom: -50,
                  child: SizedBox.square(
                    dimension: 180,
                    child: CustomPaint(painter: StarPainter(Color(0x129CD1C7))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  child: Column(
                    children: [
                      Text(
                        'سُورَةُ ${i.arabic}',
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 34,
                          height: 1.5,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        i.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        i.meaning,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.emerald200.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HeaderPill(
                            icon: i.makki ? Icons.mosque_outlined : Icons.location_city_outlined,
                            label: (i.makki ? 'quran_makki' : 'quran_madani').tr,
                          ),
                          _HeaderPill(
                            icon: Icons.format_list_numbered_rounded,
                            label: 'quran_ayahs'.trParams({'n': '${i.ayahs}'}),
                          ),
                          _HeaderPill(
                            icon: Icons.menu_book_outlined,
                            label: 'quran_juz_n'.trParams({'n': '${controller.juzOf(1)}'}),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (controller.showBismillah)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 26,
                height: 1.8,
                color: AppColors.primary.withValues(alpha: 0.9),
              ),
            ),
          )
        else
          const SizedBox(height: 16),
      ],
    );
  }
}

final class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [
        Icon(icon, size: 14, color: AppColors.mint),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ],
    ),
  );
}

final class _JuzDivider extends StatelessWidget {
  const _JuzDivider({required this.juz});

  final int juz;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
    child: Row(
      spacing: 10,
      children: [
        const Expanded(child: Divider(color: AppColors.amber200)),
        Text(
          'quran_juz_begins'.trParams({'n': '$juz'}).toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: FontWeight.w800,
            color: AppColors.amber700,
          ),
        ),
        const Expanded(child: Divider(color: AppColors.amber200)),
      ],
    ),
  );
}

final class _AyahCard extends GetView<SurahReaderViewModel> {
  const _AyahCard({required this.ayah, super.key});

  final int ayah;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Obx(() {
      final active = controller.playingAyah == ayah;
      final playing = active && controller.status == AudioStatus.playing;
      final bookmarked = controller.isBookmarked(ayah);
      final translation = controller.translation(ayah);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
        decoration: BoxDecoration(
          color: active ? AppColors.emerald50 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? AppColors.emerald300 : const Color(0x0F042F2E)),
          boxShadow: active
              ? null
              : const [BoxShadow(color: Color(0x08042F2E), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                StarBadge(label: '$ayah', color: AppColors.primaryContainer, size: 34),
                const SizedBox(width: 8),
                Text(
                  '${controller.surah}:$ayah',
                  style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                ),
                if (controller.hasSajda(ayah)) ...[const SizedBox(width: 8), _SajdaChip()],
                const Spacer(),
                IconButton(
                  tooltip: 'quran_play_from'.tr,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => playing ? controller.togglePlay() : controller.playAyah(ayah),
                  icon: Icon(
                    playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_outline_rounded,
                    color: active ? AppColors.emerald700 : AppColors.gray500,
                  ),
                ),
                IconButton(
                  tooltip: 'quran_bookmark'.tr,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => controller.toggleBookmark(ayah),
                  icon: Icon(
                    bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: bookmarked ? AppColors.amber600 : AppColors.gray500,
                  ),
                ),
                IconButton(
                  tooltip: 'quran_copy'.tr,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => controller.copyAyah(ayah),
                  icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.gray500),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${controller.arabic(ayah)} ﴿${arabicDigits(ayah)}﴾',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: controller.arabicSize,
                height: 2.1,
                color: AppColors.gray900,
              ),
            ),
            if (translation != null) ...[
              const SizedBox(height: 10),
              Text(
                translation,
                textAlign: controller.translationIsUrdu ? TextAlign.right : TextAlign.left,
                textDirection: controller.translationIsUrdu ? TextDirection.rtl : TextDirection.ltr,
                style: controller.translationIsUrdu
                    ? const TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: 16,
                        height: 2.1,
                        color: AppColors.gray700,
                      )
                    : const TextStyle(fontSize: 15, height: 1.6, color: AppColors.gray700),
              ),
            ],
          ],
        ),
      );
    }),
  );
}

final class _SajdaChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: AppColors.amber100, borderRadius: BorderRadius.circular(6)),
    child: Text(
      'quran_sajdah'.tr,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.amber800),
    ),
  );
}

void _showDisplaySheet(BuildContext context, SurahReaderViewModel vm) => unawaited(
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'quran_display'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'quran_arabic_size'.tr,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.gray700),
              ),
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontFamily: 'Amiri', fontSize: vm.arabicSize, height: 1.9),
                ),
              ),
              Row(
                children: [
                  const Text('ا', style: TextStyle(fontFamily: 'Amiri', fontSize: 16)),
                  Expanded(
                    child: Slider(
                      value: vm.arabicSize,
                      min: QuranService.minArabicSize,
                      max: QuranService.maxArabicSize,
                      divisions: 9,
                      activeColor: AppColors.emerald700,
                      onChanged: (v) => vm.arabicSize = v,
                    ),
                  ),
                  const Text('ا', style: TextStyle(fontFamily: 'Amiri', fontSize: 28)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'quran_translation'.tr,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.gray700),
              ),
              const SizedBox(height: 8),
              SegmentedButton<QuranTranslation>(
                showSelectedIcon: false,
                segments: [
                  const ButtonSegment(value: QuranTranslation.english, label: Text('English')),
                  const ButtonSegment(value: QuranTranslation.urdu, label: Text('اردو')),
                  ButtonSegment(
                    value: QuranTranslation.off,
                    label: Text('quran_translation_off'.tr),
                  ),
                ],
                selected: {vm.translationMode},
                onSelectionChanged: (s) => vm.translationMode = s.first,
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
