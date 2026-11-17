import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_pro/core/network/connectivity_service.dart';
import 'package:quran_pro/core/services/audio_service.dart';

class _Player extends Mock implements AudioPlayer;

class _Connectivity extends Mock implements Connectivity;

const NowPlaying _info = (title: 'Al-Fatiha (1:1)', subtitle: 'Alafasy');

void main() {
  setUpAll(() {
    registerFallbackValue(<AudioSource>[]);
    registerFallbackValue(LoopMode.off);
  });

  final a = Uri.parse('https://example.test/a.mp3');
  final b = Uri.parse('https://example.test/b.mp3');
  late _Player player;
  late StreamController<List<ConnectivityResult>> network;
  late StreamController<PlayerState> states;
  late StreamController<PlaybackEvent> events;
  late AudioService audio;

  void emit(ProcessingState s, {required bool playing}) => states.add(PlayerState(playing, s));

  setUp(() {
    player = _Player();
    network = StreamController<List<ConnectivityResult>>.broadcast(sync: true);
    final connectivity = _Connectivity();
    when(() => connectivity.onConnectivityChanged).thenAnswer((_) => network.stream);
    when(connectivity.checkConnectivity).thenAnswer((_) async => [ConnectivityResult.wifi]);
    states = StreamController<PlayerState>.broadcast(sync: true);
    events = StreamController<PlaybackEvent>.broadcast(sync: true);
    when(() => player.playerStateStream).thenAnswer((_) => states.stream);
    when(() => player.playbackEventStream).thenAnswer((_) => events.stream);
    when(() => player.currentIndexStream).thenAnswer((_) => const Stream.empty());
    when(() => player.setLoopMode(any())).thenAnswer((_) async {});
    when(() => player.setUrl(any(), tag: any<dynamic>(named: 'tag')))
        .thenAnswer((_) async => const Duration(seconds: 10));
    when(() => player.play()).thenAnswer((_) async => emit(ProcessingState.ready, playing: true));
    when(() => player.pause()).thenAnswer((_) async => emit(ProcessingState.ready, playing: false));
    when(() => player.stop()).thenAnswer((_) async => emit(ProcessingState.idle, playing: false));
    audio = AudioService(ConnectivityService(connectivity)..onInit(), player)..onInit();
  });

  tearDown(() async {
    await states.close();
    await events.close();
    await network.close();
  });

  test('play() restarts a short clip instead of pausing it', () async {
    await audio.play('letter', a, info: _info);
    expect(audio.statusOf('letter'), AudioStatus.playing);
    await audio.play('letter', a, info: _info); // tapping the same letter again replays it
    verify(() => player.setUrl(a.toString(), tag: any<dynamic>(named: 'tag'))).called(2);
    verifyNever(() => player.pause());
  });

  test('tap plays, tap pauses, tap resumes; other tracks stay idle', () async {
    await audio.toggle('a', a, info: _info);
    expect(audio.statusOf('a'), AudioStatus.playing);
    expect(audio.statusOf('b'), AudioStatus.idle);
    verify(() => player.setUrl(a.toString(), tag: any<dynamic>(named: 'tag'))).called(1);

    await audio.toggle('a', a, info: _info);
    expect(audio.statusOf('a'), AudioStatus.paused);
    await audio.toggle('a', a, info: _info);
    expect(audio.statusOf('a'), AudioStatus.playing);
    verifyNever(
      () => player.setUrl(any(), tag: any<dynamic>(named: 'tag')),
    ); // resume reuses the loaded track
  });

  test('shows loading while preparing and ignores repeated taps', () async {
    final load = Completer<Duration?>();
    when(() => player.setUrl(any(), tag: any<dynamic>(named: 'tag')))
        .thenAnswer((_) => load.future);

    final first = audio.toggle('a', a, info: _info);
    emit(ProcessingState.loading, playing: false);
    expect(audio.statusOf('a'), AudioStatus.loading);
    await audio.toggle('a', a, info: _info);
    await audio.toggle('a', a, info: _info);
    load.complete(const Duration(seconds: 10));
    await first;

    verify(() => player.setUrl(any(), tag: any<dynamic>(named: 'tag'))).called(1);
    verify(() => player.play()).called(1);
    expect(audio.statusOf('a'), AudioStatus.playing);
  });

  test('finishing returns to idle and the next tap plays again', () async {
    await audio.toggle('a', a, info: _info);
    emit(ProcessingState.completed, playing: true);
    expect(audio.statusOf('a'), AudioStatus.idle);
    await audio.toggle('a', a, info: _info);
    verify(() => player.setUrl(any(), tag: any<dynamic>(named: 'tag'))).called(2);
    expect(audio.statusOf('a'), AudioStatus.playing);
  });

  test('a new track replaces the current one on the single player', () async {
    await audio.toggle('a', a, info: _info);
    await audio.toggle('b', b, info: _info);
    expect(audio.statusOf('a'), AudioStatus.idle);
    expect(audio.statusOf('b'), AudioStatus.playing);
  });

  test('a superseded load never starts playing', () async {
    final slow = Completer<Duration?>();
    when(() => player.setUrl(a.toString(), tag: any<dynamic>(named: 'tag')))
        .thenAnswer((_) => slow.future);
    final first = audio.toggle('a', a, info: _info);
    await audio.toggle('b', b, info: _info);
    slow.complete(const Duration(seconds: 1));
    await first;
    verify(() => player.play()).called(1); // only b
    expect(audio.statusOf('b'), AudioStatus.playing);
  });

  test('load failure reports unavailable when online, offline otherwise', () async {
    when(() => player.setUrl(any(), tag: any<dynamic>(named: 'tag')))
        .thenThrow(PlayerException(404, 'not found', null));
    await audio.toggle('a', a, info: _info);
    expect(audio.statusOf('a'), AudioStatus.error);
    expect(audio.error, AudioError.unavailable);

    network.add([ConnectivityResult.none]);
    await audio.toggle('a', a, info: _info); // retry
    expect(audio.error, AudioError.offline);
    verify(() => player.setUrl(any(), tag: any<dynamic>(named: 'tag'))).called(2);
  });

  test('a stream error during playback becomes an error state', () async {
    await audio.toggle('a', a, info: _info);
    events.addError(PlayerException(0, 'connection lost', null));
    await Future<void>.delayed(Duration.zero);
    expect(audio.statusOf('a'), AudioStatus.error);
  });

  test('each track carries what the notification bar shows', () async {
    await audio.toggle('quran:1:1', a, info: _info);
    final tag =
        verify(() => player.setUrl(a.toString(), tag: captureAny<dynamic>(named: 'tag')))
                .captured
                .single
            as MediaItem;
    expect((tag.id, tag.title, tag.artist), ('quran:1:1', 'Al-Fatiha (1:1)', 'Alafasy'));
  });

  test('a playlist loads every track once and pauses/resumes as one', () async {
    when(
      () => player.setAudioSources(
        any<List<AudioSource>>(),
        initialIndex: any(named: 'initialIndex'),
      ),
    ).thenAnswer((_) async => null);
    final tracks = [(url: a, info: _info), (url: b, info: _info)];
    await audio.togglePlaylist('quran:1', tracks);
    final sources =
        verify(
              () => player.setAudioSources(
                captureAny<List<AudioSource>>(),
                initialIndex: any(named: 'initialIndex'),
              ),
            ).captured.single
            as List<AudioSource>;
    expect(sources, hasLength(2));
    expect(audio.statusOf('quran:1'), AudioStatus.playing);

    await audio.togglePlaylist('quran:1', tracks);
    expect(audio.statusOf('quran:1'), AudioStatus.paused);
    verifyNever(
      () => player.setAudioSources(
        any<List<AudioSource>>(),
        initialIndex: any(named: 'initialIndex'),
      ),
    );
  });
}
