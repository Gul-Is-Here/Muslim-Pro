import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/data/models/prayer.dart';
import 'package:quran_pro/data/models/prayer_alert_settings.dart';
import 'package:quran_pro/features/settings/viewmodels/prayer_notifications_view_model.dart';

final class PrayerNotificationsView extends GetView<PrayerNotificationsViewModel> {
  const PrayerNotificationsView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('prayer_notifications'.tr)),
    body: Obx(
      () => ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 32),
        children: [
          const _MasterCard(),
          if (controller.showBlocked)
            _Banner(
              icon: Icons.notifications_off_outlined,
              messageKey: 'notif_blocked',
              actionKey: 'open_app_settings',
              onAction: controller.openAppSettings,
              warning: true,
            ),
          if (controller.showExactHint)
            _Banner(
              icon: Icons.schedule,
              messageKey: 'exact_alarm_hint',
              actionKey: 'allow_exact',
              onAction: controller.allowExactAlarms,
            ),
          const SizedBox(height: 8),
          for (final p in Prayer.obligatory) _PrayerCard(prayer: p),
          const _Footnote(),
        ],
      ),
    ),
  );
}

final class _MasterCard extends GetView<PrayerNotificationsViewModel> {
  const _MasterCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.primaryContainer,
      margin: const EdgeInsetsDirectional.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Obx(
        () => SwitchListTile(
          contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 10, 12, 10),
          secondary: Icon(Icons.notifications_active_outlined, color: scheme.onPrimaryContainer),
          title: Text(
            'prayer_notifications'.tr,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer),
          ),
          subtitle: Text(
            'prayer_notifications_sub'.tr,
            style: TextStyle(color: scheme.onPrimaryContainer.withValues(alpha: 0.8)),
          ),
          value: controller.masterOn,
          onChanged: (on) => unawaited(controller.setMaster(on: on)),
        ),
      ),
    );
  }
}

final class _Banner extends StatelessWidget {
  const _Banner({
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
    final scheme = Theme.of(context).colorScheme;
    final bg = warning ? scheme.errorContainer : scheme.secondaryContainer;
    final fg = warning ? scheme.onErrorContainer : scheme.onSecondaryContainer;
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 12),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Icon(icon, color: fg),
              Expanded(
                child: Text(messageKey.tr, style: TextStyle(color: fg, height: 1.4)),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => unawaited(onAction()),
              style: TextButton.styleFrom(foregroundColor: fg),
              child: Text(actionKey.tr),
            ),
          ),
        ],
      ),
    );
  }
}

final class _PrayerCard extends GetView<PrayerNotificationsViewModel> {
  const _PrayerCard({required this.prayer});

  final Prayer prayer;

  static IconData _icon(Prayer p) => switch (p) {
    Prayer.fajr => Icons.wb_twilight,
    Prayer.dhuhr => Icons.wb_sunny_outlined,
    Prayer.asr => Icons.light_mode_outlined,
    Prayer.maghrib => Icons.brightness_4_outlined,
    _ => Icons.nightlight_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: const EdgeInsetsDirectional.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Obx(() {
        final master = controller.masterOn;
        final on = controller.isOn(prayer);
        final active = master && on;
        return Column(
          children: [
            SwitchListTile(
              contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 6, 12, 6),
              secondary: CircleAvatar(
                backgroundColor: active ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                foregroundColor: active ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                child: Icon(_icon(prayer)),
              ),
              title: Text(
                prayer.labelKey.tr,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(controller.nextTimeLabel(prayer) ?? 'no_location_times'.tr),
              value: on,
              onChanged: master ? (v) => unawaited(controller.setPrayerOn(prayer, on: v)) : null,
            ),
            Divider(height: 1, indent: 16, endIndent: 16, color: scheme.outlineVariant),
            ListTile(
              enabled: active,
              contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 12, 0),
              leading: const Icon(Icons.music_note_outlined),
              title: Text('azan_sound'.tr),
              subtitle: Text(controller.soundOf(prayer).labelKey.tr),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => unawaited(
                showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  builder: (_) => _SoundSheet(prayer: prayer),
                ).whenComplete(controller.stopPreview), // previews never outlive the sheet
              ),
            ),
          ],
        );
      }),
    );
  }
}

final class _SoundSheet extends GetView<PrayerNotificationsViewModel> {
  const _SoundSheet({required this.prayer});

  final Prayer prayer;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Obx(() {
      final selected = controller.soundOf(prayer);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 8),
            child: Text(
              'azan_sound_for'.trParams({'prayer': prayer.labelKey.tr}),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          RadioGroup<AzanSound>(
            groupValue: selected,
            onChanged: (s) => unawaited(controller.setSound(prayer, s!)),
            child: Column(
              children: [
                for (final s in AzanSound.values)
                  RadioListTile<AzanSound>(
                    value: s,
                    title: Text(s.labelKey.tr),
                    subtitle: s == AzanSound.fallback ? Text('default_badge'.tr) : null,
                    secondary: s.isBundled ? _PreviewButton(sound: s) : null,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
            child: OutlinedButton.icon(
              onPressed: () => unawaited(controller.sendTest(selected)),
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text('send_test'.tr),
            ),
          ),
        ],
      );
    }),
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
      icon: status == AudioStatus.loading
          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(switch (status) {
              AudioStatus.playing => Icons.pause_circle_outline,
              AudioStatus.error => Icons.error_outline,
              _ => Icons.play_circle_outline,
            }),
    );
  });
}

final class _Footnote extends GetView<PrayerNotificationsViewModel> {
  const _Footnote();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Icon(Icons.info_outline, size: 18, color: muted),
              Expanded(
                child: Text(
                  [
                    'azan_limits_note'.tr,
                    if (controller.isAndroid) 'android_channel_note'.tr,
                  ].join('\n\n'),
                  style: TextStyle(color: muted, fontSize: 13, height: 1.45),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () => unawaited(
              showDialog<void>(context: context, builder: (_) => const _CreditsDialog()),
            ),
            child: Text('sound_credits'.tr),
          ),
        ],
      ),
    );
  }
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
