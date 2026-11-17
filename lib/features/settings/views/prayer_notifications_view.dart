import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/data/models/prayer.dart';
import 'package:quran_pro/data/models/prayer_alert_settings.dart';
import 'package:quran_pro/features/settings/viewmodels/prayer_notifications_view_model.dart';

const _rose50 = Color(0xFFFFF1F2);
const _rose200 = Color(0xFFFECDD3);
const _rose800 = Color(0xFF9F1239);

final class PrayerNotificationsView extends GetView<PrayerNotificationsViewModel> {
  const PrayerNotificationsView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    appBar: AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.gray900,
      centerTitle: false,
      titleSpacing: 0,
      title: Text(
        'prayer_notifications'.tr,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.gray900),
      ),
    ),
    body: Obx(
      () => ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 32),
        children: [
          const _MasterCard(),
          if (controller.showBlocked)
            _Notice(
              icon: Icons.notifications_off_outlined,
              messageKey: 'notif_blocked',
              actionKey: 'open_app_settings',
              onAction: controller.openAppSettings,
              warning: true,
            ),
          if (controller.showExactHint)
            _Notice(
              icon: Icons.schedule_rounded,
              messageKey: 'exact_alarm_hint',
              actionKey: 'allow_exact',
              onAction: controller.allowExactAlarms,
            ),
          const SizedBox(height: 24),
          const _SectionLabel('notif_prayers'),
          const _PrayerGroup(),
          const SizedBox(height: 20),
          const _Footnote(),
        ],
      ),
    ),
  );
}

/// The one switch most people need; everything below follows it.
final class _MasterCard extends GetView<PrayerNotificationsViewModel> {
  const _MasterCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 12, 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [AppColors.primaryContainer, AppColors.primary],
      ),
    ),
    child: Row(
      spacing: 14,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: const Icon(Icons.notifications_active_outlined, color: AppColors.mint, size: 22),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 3,
            children: [
              Text(
                'notif_master_title'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'prayer_notifications_sub'.tr,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        Obx(
          () => Switch(
            value: controller.masterOn,
            onChanged: (on) => unawaited(controller.setMaster(on: on)),
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.mint,
            inactiveThumbColor: Colors.white.withValues(alpha: 0.8),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
            trackOutlineColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.2)),
          ),
        ),
      ],
    ),
  );
}

final class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.messageKey,
    required this.actionKey,
    required this.onAction,
    this.warning = false,
  });

  final IconData icon;
  final String messageKey;
  final String actionKey;
  final Future<void> Function() onAction;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final fg = warning ? _rose800 : AppColors.amber800;
    return Container(
      margin: const EdgeInsetsDirectional.only(top: 12),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: warning ? _rose50 : AppColors.amber50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warning ? _rose200 : AppColors.amber200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Icon(icon, size: 20, color: fg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(messageKey.tr, style: TextStyle(fontSize: 13, height: 1.4, color: fg)),
                Semantics(
                  button: true,
                  child: InkWell(
                    onTap: () => unawaited(onAction()),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        actionKey.tr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: fg,
                          decoration: TextDecoration.underline,
                          decorationColor: fg.withValues(alpha: 0.4),
                        ),
                      ),
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
}

final class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.labelKey);

  final String labelKey;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 10),
    child: Text(
      labelKey.tr.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w800,
        color: AppColors.gray500,
      ),
    ),
  );
}

/// Five rows in one card, like the More screen's groups.
final class _PrayerGroup extends StatelessWidget {
  const _PrayerGroup();

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (final (i, p) in Prayer.obligatory.indexed) ...[
          if (i > 0) const Divider(height: 1, indent: 64, color: AppColors.gray100),
          _PrayerRow(prayer: p),
        ],
      ],
    ),
  );
}

final class _PrayerRow extends GetView<PrayerNotificationsViewModel> {
  const _PrayerRow({required this.prayer});

  final Prayer prayer;

  static IconData _icon(Prayer p) => switch (p) {
    Prayer.fajr => Icons.wb_twilight_rounded,
    Prayer.dhuhr => Icons.wb_sunny_outlined,
    Prayer.asr => Icons.light_mode_outlined,
    Prayer.maghrib => Icons.brightness_4_outlined,
    _ => Icons.nightlight_outlined,
  };

  void _pickSound(BuildContext context) => unawaited(
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _SoundSheet(prayer: prayer),
    ).whenComplete(controller.stopPreview), // previews never outlive the sheet
  );

  @override
  Widget build(BuildContext context) => Obx(() {
    final master = controller.masterOn;
    final active = master && controller.isOn(prayer);
    final time = controller.timeLabel(prayer);
    return Opacity(
      opacity: master ? 1 : 0.5,
      child: InkWell(
        onTap: active ? () => _pickSound(context) : null,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 8, 12),
          child: Row(
            spacing: 12,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: active ? AppColors.emerald50 : AppColors.gray100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _icon(prayer),
                  size: 20,
                  color: active ? AppColors.emerald800 : AppColors.gray400,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        Flexible(
                          child: Text(
                            prayer.labelKey.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray900,
                            ),
                          ),
                        ),
                        if (time != null)
                          Text(
                            time,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray500,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                      ],
                    ),
                    Row(
                      spacing: 4,
                      children: [
                        Icon(
                          Icons.music_note_rounded,
                          size: 13,
                          color: active ? AppColors.emerald700 : AppColors.gray400,
                        ),
                        Flexible(
                          child: Text(
                            active ? controller.soundOf(prayer).labelKey.tr : 'notif_off'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: active ? AppColors.emerald700 : AppColors.gray400,
                            ),
                          ),
                        ),
                        if (active)
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.emerald700,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Switch(
                value: controller.isOn(prayer),
                onChanged: master ? (v) => unawaited(controller.setPrayerOn(prayer, on: v)) : null,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.emerald700,
              ),
            ],
          ),
        ),
      ),
    );
  });
}

final class _SoundSheet extends GetView<PrayerNotificationsViewModel> {
  const _SoundSheet({required this.prayer});

  final Prayer prayer;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Obx(() {
      final selected = controller.soundOf(prayer);
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 14),
              child: Text(
                'azan_sound_for'.trParams({'prayer': prayer.labelKey.tr}),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gray900,
                ),
              ),
            ),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (i, s) in AzanSound.values.indexed) ...[
                    if (i > 0) const Divider(height: 1, indent: 52, color: AppColors.gray100),
                    _SoundOption(
                      sound: s,
                      selected: s == selected,
                      onTap: () => unawaited(controller.setSound(prayer, s)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => unawaited(controller.sendTest(selected)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.emerald800,
                side: const BorderSide(color: AppColors.emerald200),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              icon: const Icon(Icons.notifications_active_outlined, size: 18),
              label: Text('send_test'.tr),
            ),
          ],
        ),
      );
    }),
  );
}

final class _SoundOption extends StatelessWidget {
  const _SoundOption({required this.sound, required this.selected, required this.onTap});

  final AzanSound sound;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    inMutuallyExclusiveGroup: true,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 8, 10),
        child: Row(
          spacing: 14,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.emerald700 : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.emerald700 : AppColors.gray400,
                  width: 1.5,
                ),
              ),
              child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    sound.labelKey.tr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                  ),
                  if (sound == AzanSound.fallback)
                    Text(
                      'default_badge'.tr,
                      style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                    ),
                ],
              ),
            ),
            if (sound.isBundled) _PreviewButton(sound: sound) else const SizedBox(height: 48),
          ],
        ),
      ),
    ),
  );
}

final class _PreviewButton extends GetView<PrayerNotificationsViewModel> {
  const _PreviewButton({required this.sound});

  final AzanSound sound;

  @override
  Widget build(BuildContext context) => Obx(() {
    final status = controller.previewStatus(sound);
    final playing = status == AudioStatus.playing;
    return IconButton(
      tooltip: '${(playing ? 'pause' : 'preview').tr} · ${sound.labelKey.tr}',
      onPressed: () => unawaited(controller.togglePreview(sound)),
      style: IconButton.styleFrom(
        backgroundColor: playing ? AppColors.emerald700 : AppColors.emerald50,
        foregroundColor: playing ? Colors.white : AppColors.emerald800,
      ),
      icon: status == AudioStatus.loading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.emerald700),
            )
          : Icon(switch (status) {
              AudioStatus.playing => Icons.pause_rounded,
              AudioStatus.error => Icons.error_outline_rounded,
              _ => Icons.play_arrow_rounded,
            }, size: 20),
    );
  });
}

final class _Footnote extends GetView<PrayerNotificationsViewModel> {
  const _Footnote();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        for (final key in ['azan_limits_note', if (controller.isAndroid) 'android_channel_note'])
          Text(
            key.tr,
            style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.gray500),
          ),
        InkWell(
          onTap: () =>
              unawaited(showDialog<void>(context: context, builder: (_) => const _CreditsDialog())),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'sound_credits'.tr,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.emerald800,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

final class _CreditsDialog extends StatelessWidget {
  const _CreditsDialog();

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('sound_credits'.tr),
    content: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          for (final s in AzanSound.values)
            if (s.credit case final credit?)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(s.labelKey.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                  SelectableText(credit),
                ],
              ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(MaterialLocalizations.of(context).closeButtonLabel),
      ),
    ],
  );
}
