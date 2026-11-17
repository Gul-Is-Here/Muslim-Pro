import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_pro/core/network/connectivity_service.dart';
import 'package:quran_pro/core/services/adhkar_service.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/data/datasources/local/adhkar_local_ds.dart';
import 'package:quran_pro/data/datasources/local/quran_local_ds.dart';
import 'package:quran_pro/data/models/adhkar.dart';
import 'package:quran_pro/data/repositories/adhkar_repository_impl.dart';
import 'package:quran_pro/features/adhkar/viewmodels/adhkar_view_model.dart';
import 'package:quran_pro/features/adhkar/views/adhkar_view.dart';
import 'package:quran_pro/features/home/viewmodels/home_view_model.dart';

class _Player extends Mock implements AudioPlayer;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = Directory.systemTemp.createTempSync('adhkar_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => dir.path,
    );
    await GetStorage.init();
  });

  setUp(() => GetStorage().erase());
  tearDown(Get.reset);

  Future<AdhkarService> service() async {
    final s = AdhkarService(const AdhkarRepositoryImpl(AdhkarLocalDataSource()), GetStorage());
    await s.load();
    return s;
  }

  test('bundled adhkar: every list filled, every dhikr has text and a repeat count', () async {
    final book = (await service()).book!;
    for (final c in AdhkarCategory.values) {
      expect(book.of(c), isNotEmpty, reason: '$c');
      for (final d in book.of(c)) {
        expect(d.arabic, isNotEmpty);
        expect(d.repeat, greaterThanOrEqualTo(1));
        expect(d.audioUrl.scheme, 'https');
      }
    }
    expect(book.of(AdhkarCategory.morningEvening), hasLength(24));
  });

  test('counting stops at the repeat count, survives a restart, and resets per list', () async {
    final s = await service();
    final thrice = s.book!.of(AdhkarCategory.morningEvening).firstWhere((d) => d.repeat == 3);
    expect(s.count(thrice), isFalse);
    expect(s.count(thrice), isFalse);
    expect(s.count(thrice), isTrue, reason: 'third tap completes it');
    expect(s.count(thrice), isFalse, reason: 'no counting past done');
    expect(s.countOf(thrice), 3);
    expect(s.doneIn(AdhkarCategory.morningEvening), 1);
    await Future<void>.delayed(Duration.zero);

    final again = await service();
    expect(again.isDone(thrice), isTrue);
    again.reset(again.book!.of(AdhkarCategory.morningEvening));
    expect(again.countOf(thrice), 0);
  });

  test(
    'ayah of the day: one per day, cycling, and every verse exists in the bundled text',
    () async {
      final a = HomeViewModel.dailyAyahOn(DateTime(2026, 11, 13));
      expect(HomeViewModel.dailyAyahOn(DateTime(2026, 11, 13, 23, 59)), a);
      expect(HomeViewModel.dailyAyahOn(DateTime(2026, 11, 14)), isNot(a));
      for (final r in HomeViewModel.dailyAyahs) {
        final text = await const QuranLocalDataSource().surah(r.surah);
        expect(r.ayah, lessThanOrEqualTo(text.length), reason: '${r.surah}:${r.ayah}');
      }
    },
  );

  testWidgets('adhkar screen: switch lists and count a dhikr to done; nothing overflows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    // Assets over 50 KB decode on an isolate, which needs real time, not the test clock.
    final s = (await tester.runAsync(service))!;
    Get.put(
      AdhkarViewModel(s, AudioService(ConnectivityService(), _Player()), AdhkarCategory.waking),
    );
    await tester.pumpWidget(const GetMaterialApp(home: AdhkarView()));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('adhkar_tap').first);
    await tester.pump();
    expect(s.doneIn(AdhkarCategory.waking), 1, reason: 'waking adhkar are said once');
    expect(find.text('adhkar_done'), findsOneWidget);

    await tester.tap(find.text('adhkar_cat_sleep'));
    await tester.pump();
    expect(find.text('adhkar_progress'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
