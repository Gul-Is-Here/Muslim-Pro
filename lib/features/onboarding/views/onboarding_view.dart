import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/core/widgets/star_lattice.dart';
import 'package:quran_pro/features/onboarding/viewmodels/onboarding_view_model.dart';
import 'package:quran_pro/features/qibla/views/widgets/qibla_painters.dart';
import 'package:quran_pro/features/quran/views/widgets/star_badge.dart';

/// Jewel panel on top shows what each step unlocks (the app, the Qibla, an azan alert);
/// the copy and the one action sit underneath.
final class OnboardingView extends GetView<OnboardingViewModel> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.surface,
    body: Column(
      children: [
        Expanded(flex: 11, child: _Stage()),
        Expanded(
          flex: 9,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(child: _Copy()),
                _Footer(),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

const _switch = Duration(milliseconds: 320);

Widget _fadeUp(Widget child, Animation<double> a) => FadeTransition(
  opacity: a,
  child: SlideTransition(
    position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(a),
    child: child,
  ),
);

final class _Stage extends GetView<OnboardingViewModel> {
  const _Stage();

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
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
          const Positioned.fill(child: StarLattice()),
          // Soft light behind the artwork.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.1),
                  radius: 0.7,
                  colors: [AppColors.mint.withValues(alpha: 0.16), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const _Brand(),
                Expanded(
                  // Short phones: the artwork shrinks rather than clipping.
                  child: LayoutBuilder(
                    builder: (_, box) => FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: box.maxWidth,
                        child: Center(
                          child: Obx(
                            () => AnimatedSwitcher(
                              duration: _switch,
                              transitionBuilder: (child, a) => FadeTransition(
                                opacity: a,
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 0.94, end: 1).animate(a),
                                  child: child,
                                ),
                              ),
                              child: switch (controller.step) {
                                OnboardingStep.welcome => const _WelcomeArt(key: ValueKey(0)),
                                OnboardingStep.location => const _QiblaArt(key: ValueKey(1)),
                                OnboardingStep.alerts => const _AlertArt(key: ValueKey(2)),
                              },
                            ),
                          ),
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
    ),
  );
}

final class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(24, 14, 24, 0),
    child: Row(
      spacing: 8,
      children: [
        const StarBadge(label: '', color: AppColors.amber300, size: 22),
        Text(
          'onboarding_brand'.tr,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

/// Rub el Hizb with the name in Amiri, inside a fainter, turned star.
final class _WelcomeArt extends StatelessWidget {
  const _WelcomeArt({super.key});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 230,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: math.pi / 8,
          child: CustomPaint(
            size: const Size.square(230),
            painter: StarPainter(
              Colors.transparent,
              stroke: AppColors.amber300.withValues(alpha: 0.22),
            ),
          ),
        ),
        CustomPaint(
          size: const Size.square(180),
          painter: StarPainter(
            AppColors.amber300.withValues(alpha: 0.1),
            stroke: AppColors.amber300.withValues(alpha: 0.55),
          ),
        ),
        const Text(
          'نُور',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 60,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: AppColors.amber300,
          ),
        ),
      ],
    ),
  );
}

/// The real compass card from the Qibla screen, with a Kaaba marker on its bearing.
final class _QiblaArt extends StatelessWidget {
  const _QiblaArt({super.key});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 220,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.18),
          ),
        ),
        CustomPaint(
          size: const Size.square(220),
          painter: CompassDialPainter(
            heading: 0,
            ring: Colors.white.withValues(alpha: 0.35),
            muted: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const CustomPaint(size: Size.square(220), painter: _QiblaNeedlePainter(bearing: 62)),
      ],
    ),
  );
}

final class _QiblaNeedlePainter extends CustomPainter {
  const _QiblaNeedlePainter({required this.bearing});

  final double bearing;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final a = bearing * math.pi / 180;
    final dir = Offset(math.sin(a), -math.cos(a));
    final tip = c + dir * (size.width / 2 - 58);
    canvas
      ..drawLine(
        c,
        tip,
        Paint()
          ..color = AppColors.amber300
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(c, 6, Paint()..color = Colors.white)
      ..drawCircle(c, 3, Paint()..color = AppColors.primaryContainer);
    // Kaaba: black cube with its gold band.
    final k = c + dir * (size.width / 2 - 44);
    final cube = RRect.fromRectAndRadius(
      Rect.fromCenter(center: k, width: 22, height: 22),
      const Radius.circular(3),
    );
    canvas
      ..drawCircle(k, 20, Paint()..color = AppColors.amber300.withValues(alpha: 0.18))
      ..drawRRect(cube, Paint()..color = const Color(0xFF151515))
      ..drawLine(
        Offset(k.dx - 11, k.dy - 4),
        Offset(k.dx + 11, k.dy - 4),
        Paint()
          ..color = AppColors.amber400
          ..strokeWidth = 2.5,
      );
  }

  @override
  bool shouldRepaint(_QiblaNeedlePainter old) => old.bearing != bearing;
}

/// What the alert will look like: a notification on the lock screen, with one behind it.
final class _AlertArt extends StatelessWidget {
  const _AlertArt({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'حَيَّ عَلَى ٱلصَّلَاةِ',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 30,
              height: 1.4,
              color: AppColors.amber300,
            ),
          ),
          const SizedBox(height: 22),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: -10,
                left: 18,
                right: 18,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const StarBadge(label: '', color: AppColors.amber300, size: 22),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'onboarding_brand'.tr,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.gray500,
                                  ),
                                ),
                              ),
                              Text(
                                'onboarding_notif_now'.tr,
                                style: const TextStyle(fontSize: 11.5, color: AppColors.gray400),
                              ),
                            ],
                          ),
                          Text(
                            'onboarding_notif_title'.tr,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.gray900,
                            ),
                          ),
                          Text(
                            'onboarding_notif_body'.tr,
                            style: const TextStyle(fontSize: 13, color: AppColors.gray500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

final class _Copy extends GetView<OnboardingViewModel> {
  const _Copy();

  @override
  Widget build(BuildContext context) => Obx(() {
    final step = controller.step;
    final (title, body) = switch (step) {
      OnboardingStep.welcome => ('onboarding_title_1', 'onboarding_body_1'),
      OnboardingStep.location => ('onboarding_title_location', 'onboarding_body_location'),
      OnboardingStep.alerts => ('onboarding_title_2', 'onboarding_body_2'),
    };
    final granted = switch (step) {
      OnboardingStep.welcome => false,
      OnboardingStep.location => controller.locationGranted,
      OnboardingStep.alerts => controller.alertsGranted,
    };
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Progress(page: controller.page, count: controller.pageCount),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: _switch,
            transitionBuilder: _fadeUp,
            layoutBuilder: (current, previous) => Stack(children: [...previous, ?current]),
            child: Column(
              key: ValueKey(step),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.tr,
                  style: const TextStyle(
                    fontSize: 27,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  body.tr,
                  style: const TextStyle(fontSize: 15.5, height: 1.55, color: AppColors.gray500),
                ),
                if (step == OnboardingStep.welcome) ...[
                  const SizedBox(height: 18),
                  const _Features(),
                ],
                if (step == OnboardingStep.location) ...[
                  const SizedBox(height: 16),
                  _Note(icon: Icons.lock_outline_rounded, text: 'onboarding_privacy_location'.tr),
                ],
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: granted
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _Note(icon: Icons.check_circle_rounded, text: 'allowed'.tr),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  });
}

/// One segment per step; done and current segments are filled.
final class _Progress extends StatelessWidget {
  const _Progress({required this.page, required this.count});

  final int page;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 6,
    children: [
      for (var i = 0; i < count; i++)
        Expanded(
          child: AnimatedContainer(
            duration: _switch,
            height: 4,
            decoration: BoxDecoration(
              color: i <= page ? AppColors.emerald700 : AppColors.gray200,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
    ],
  );
}

final class _Features extends StatelessWidget {
  const _Features();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final (icon, key) in const [
        (Icons.schedule_rounded, 'prayer_times'),
        (Icons.menu_book_rounded, 'nav_quran'),
        (Icons.wb_twilight_rounded, 'hisnul_muslim'),
        (Icons.explore_outlined, 'qibla_finder'),
        (Icons.school_outlined, 'nav_learn'),
      ])
        Container(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 7, 12, 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Icon(icon, size: 16, color: AppColors.emerald700),
              Text(
                key.tr,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray800,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

final class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(14)),
    child: Row(
      spacing: 8,
      children: [
        Icon(icon, size: 18, color: AppColors.emerald700),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.emerald800,
            ),
          ),
        ),
      ],
    ),
  );
}

final class _Footer extends GetView<OnboardingViewModel> {
  const _Footer();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
    child: Obx(
      () => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: controller.busy ? null : controller.primary,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                disabledBackgroundColor: AppColors.primaryContainer.withValues(alpha: 0.7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                textStyle: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              child: controller.busy
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 8,
                      children: [
                        Flexible(child: Text(controller.primaryLabelKey.tr)),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
            ),
          ),
          SizedBox(
            height: 44,
            child: controller.canSkip
                ? TextButton(
                    onPressed: controller.skip,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.gray500,
                      textStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    child: Text('not_now'.tr),
                  )
                : null,
          ),
        ],
      ),
    ),
  );
}

/// Faint tiled eight-point stars: Islamic geometry without an image asset.
