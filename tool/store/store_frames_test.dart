// Composes Play Store screenshots (1080×1920) and the feature graphic (1024×500) from the screens
// rendered by store_screens_test.dart. Output: build/store/play/.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/core/widgets/star_lattice.dart';

const _screens = 'build/store/screens';
const _out = 'build/store/play';

typedef _Slide = ({String file, String eyebrow, String title, String body});

const _slides = <_Slide>[
  (
    file: '1_home',
    eyebrow: 'PRAYER TIMES',
    title: 'Never miss\na prayer',
    body: 'Live countdown to the next salah, wherever you are',
  ),
  (
    file: '2_prayer',
    eyebrow: 'AZAN ALERTS',
    title: 'Azan from\nMakkah & Madinah',
    body: 'Accurate times for your city, with a reminder for each prayer',
  ),
  (
    file: '3_quran',
    eyebrow: 'HOLY QURAN',
    title: 'Read & listen\nto the Quran',
    body: 'All 114 surahs, recited by Mishary Alafasy, saved for offline',
  ),
  (
    file: '4_reader',
    eyebrow: 'RECITE ALONG',
    title: 'Follow every\nayah',
    body: 'Arabic with English and Urdu translation, ayah by ayah',
  ),
  (
    file: '5_learn',
    eyebrow: 'LEARN ISLAM',
    title: 'Learn step\nby step',
    body: 'Arabic letters, salah and duas — made for new Muslims',
  ),
  (
    file: '6_profile',
    eyebrow: 'YOUR JOURNEY',
    title: 'Grow a little\nevery day',
    body: 'Streaks, lessons and saved ayahs in one place',
  ),
];

Future<void> _font(String family, List<String> paths) async {
  final l = FontLoader(family);
  for (final p in paths) {
    l.addFont(Future.value(ByteData.sublistView(File(p).readAsBytesSync())));
  }
  await l.load();
}

Future<ui.Image> _decode(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  return (await codec.getNextFrame()).image;
}

void main() {
  testWidgets('play store frames', (tester) async {
    final images = <String, ui.Image>{};
    await tester.runAsync(() async {
      await _font('Manrope', [
        for (final w in [400, 600, 700, 800]) 'assets/fonts/Manrope-$w.ttf',
      ]);
      await _font('Amiri', ['assets/fonts/Amiri-Regular.ttf']);
      for (final s in _slides) {
        images[s.file] = await _decode('$_screens/${s.file}.png');
      }
      images['icon'] = await _decode('build/app_icon/full.png');
    });
    Directory(_out).createSync(recursive: true);

    Future<void> render(String name, Size size, Widget child) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: MediaQueryData(size: size),
              child: DefaultTextStyle(
                style: const TextStyle(fontFamily: 'Manrope'),
                child: child,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage();
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$_out/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
      });
    }

    for (final (i, s) in _slides.indexed) {
      await render(
        'screenshot_${i + 1}_${s.file.split('_').last}',
        const Size(1080, 1920),
        _Screenshot(slide: s, screen: images[s.file]!),
      );
    }
    await render(
      'feature_graphic',
      const Size(1024, 500),
      _FeatureGraphic(icon: images['icon']!, left: images['3_quran']!, right: images['1_home']!),
    );
    addTearDown(tester.view.reset);
  });
}

/// Jewel-green backdrop shared by every store graphic.
final class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.child, this.glow = Alignment.topCenter});

  final Widget child;
  final Alignment glow;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0B3D35), Color(0xFF062A24), Color(0xFF03150F)],
      ),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        const StarLattice(cell: 96, opacity: 0.045),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: glow,
              radius: 0.9,
              colors: [AppColors.mint.withValues(alpha: 0.16), Colors.transparent],
            ),
          ),
        ),
        child,
      ],
    ),
  );
}

/// A phone: dark bezel, rounded screen, the real screenshot inside.
final class _Phone extends StatelessWidget {
  const _Phone({required this.screen, required this.width});

  final ui.Image screen;
  final double width;

  @override
  Widget build(BuildContext context) {
    final bezel = width * 0.028;
    final radius = width * 0.12;
    final h = (width - bezel * 2) * screen.height / screen.width + bezel * 2;
    return Container(
      width: width,
      height: h,
      padding: EdgeInsets.all(bezel),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F0E),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: width * 0.12,
            offset: Offset(0, width * 0.05),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - bezel),
        child: RawImage(image: screen, fit: BoxFit.cover),
      ),
    );
  }
}

final class _Screenshot extends StatelessWidget {
  const _Screenshot({required this.slide, required this.screen});

  final _Slide slide;
  final ui.Image screen;

  @override
  Widget build(BuildContext context) => _Backdrop(
    child: Stack(
      children: [
        Positioned(
          left: 80,
          right: 80,
          top: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: AppColors.amber400.withValues(alpha: 0.14),
                  border: Border.all(color: AppColors.amber300.withValues(alpha: 0.4)),
                ),
                child: Text(
                  slide.eyebrow,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w800,
                    color: AppColors.amber300,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Text(
                slide.title,
                style: const TextStyle(
                  fontSize: 84,
                  height: 1.05,
                  letterSpacing: -2,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                slide.body,
                style: TextStyle(
                  fontSize: 32,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: AppColors.emerald100.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
        // The phone runs off the bottom edge, as on most store listings.
        Positioned(
          top: 640,
          left: 0,
          right: 0,
          child: Center(child: _Phone(screen: screen, width: 760)),
        ),
      ],
    ),
  );
}

final class _FeatureGraphic extends StatelessWidget {
  const _FeatureGraphic({required this.icon, required this.left, required this.right});

  final ui.Image icon;
  final ui.Image left;
  final ui.Image right;

  @override
  Widget build(BuildContext context) => _Backdrop(
    glow: const Alignment(-0.6, -0.4),
    child: Stack(
      children: [
        Positioned(
          left: 64,
          top: 0,
          bottom: 0,
          width: 520,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: RawImage(image: icon, width: 92, height: 92),
                  ),
                  const SizedBox(width: 20),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Noor',
                        style: TextStyle(
                          fontSize: 58,
                          height: 1,
                          letterSpacing: -1.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'نور',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 34,
                          color: AppColors.amber300,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const Text(
                'Prayer Times · Quran · Qibla',
                style: TextStyle(
                  fontSize: 34,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Azan alerts, offline recitation and daily duas',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  color: AppColors.emerald100.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 150,
          top: 70,
          child: Transform.rotate(
            angle: -6 * math.pi / 180,
            child: _Phone(screen: left, width: 230),
          ),
        ),
        Positioned(
          right: 18,
          top: 40,
          child: Transform.rotate(
            angle: 5 * math.pi / 180,
            child: _Phone(screen: right, width: 250),
          ),
        ),
      ],
    ),
  );
}
