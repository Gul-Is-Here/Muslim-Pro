import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/network/connectivity_service.dart';
import 'package:quran_pro/core/services/audio_service.dart';
import 'package:quran_pro/core/services/learn_service.dart';
import 'package:quran_pro/core/services/settings_service.dart';
import 'package:quran_pro/data/models/learn.dart';
import 'package:quran_pro/domain/repositories/learn_repository.dart';
import 'package:quran_pro/features/learn/viewmodels/lesson_view_model.dart';
import 'package:quran_pro/features/learn/views/lesson_view.dart';

class _Player extends Mock implements AudioPlayer;

final class _FakeRepo implements LearnRepository {
  @override
  Future<Result<Curriculum>> curriculum() async => const Ok(
    Curriculum([
      LearnUnit(
        id: 'u',
        icon: 'kalimas',
        kids: false,
        title: {'en': 'Unit'},
        tag: {'en': ''},
        lessons: [
          LearnLesson(
            id: 'l',
            title: {'en': 'Lesson'},
            xp: 15,
            cards: [],
            questions: [
              LearnQuestion(
                prompt: {'en': 'What does “Shahadat” mean?'},
                options: [
                  {'en': 'Testimony'},
                  {'en': 'Glorification'},
                ],
                answer: 0,
              ),
            ],
          ),
          LearnLesson(
            id: 'recited',
            title: {'en': 'Recited'},
            xp: 10,
            cards: [
              LearnCard(
                title: {'en': 'Tashahhud'},
                body: {'en': ''},
                arabic: 'اَلتَّحِيَّاتُ لِلّٰهِ وَالصَّلَوَاتُ',
                audio: 'assets/audio/phrases/tashahhud.mp3',
              ),
            ],
            questions: [],
          ),
        ],
      ),
    ]),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = Directory.systemTemp.createTempSync('learn_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => dir.path,
    );
    await GetStorage.init();
  });

  tearDown(Get.reset);

  testWidgets('tapping an answer enables Check, and Check shows feedback', (tester) async {
    final learn = LearnService(_FakeRepo(), GetStorage());
    await learn.load();
    Get.put(
      LessonViewModel(
        learn,
        SettingsService(GetStorage()),
        AudioService(ConnectivityService(), _Player()), // no cards here, so never played
        (lessonId: 'l', review: false),
      ),
    );

    await tester.pumpWidget(const GetMaterialApp(home: LessonView()));
    await tester.pumpAndSettle();

    FilledButton checkButton() =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'check'));
    expect(checkButton().onPressed, isNull);

    await tester.tap(find.text('Testimony'));
    await tester.pumpAndSettle();
    expect(checkButton().onPressed, isNotNull, reason: 'selection must update the screen');

    await tester.tap(find.widgetWithText(FilledButton, 'check'));
    await tester.pumpAndSettle();
    expect(find.text('correct'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'continue'));
    await tester.pumpAndSettle();
    expect(find.text('lesson_complete'), findsOneWidget);
    expect(learn.progress.completed, {'l'});
  });

  test('Arabic finds its recording, also when a question quotes only part of it', () async {
    final learn = LearnService(_FakeRepo(), GetStorage());
    await learn.load();
    final vm = LessonViewModel(
      learn,
      SettingsService(GetStorage()),
      AudioService(ConnectivityService(), _Player()),
      (lessonId: 'l', review: false),
    );
    expect(vm.canPlay('اَلتَّحِيَّاتُ لِلّٰهِ وَالصَّلَوَاتُ'), isTrue);
    expect(vm.canPlay('اَلتَّحِيَّاتُ لِلّٰهِ'), isTrue);
    expect(vm.canPlay('سُبْحَانَ اللّٰهِ'), isFalse);
  });
}
