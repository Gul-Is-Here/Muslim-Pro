import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_pro/core/network/connectivity_service.dart';
import 'package:quran_pro/core/services/audio_service.dart';

class _Player extends Mock implements AudioPlayer;

class _Connectivity extends Mock implements Connectivity;

void main() {
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
    when(() => player.setUrl(any())).thenAnswer((_) async => const Duration(seconds: 10));
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

  test('tap plays, tap pauses, tap resumes; other tracks stay idle', () async {
    await audio.toggle('a', a);
    expect(audio.statusOf('a'), AudioStatus.playing);
    expect(audio.statusOf('b'), AudioStatus.idle);
    verify(() => player.setUrl(a.toString())).called(1);

    await audio.toggle('a', a);
    expect(audio.statusOf('a'), AudioStatus.paused);
    await audio.toggle('a', a);
    expect(audio.statusOf('a'), AudioStatus.playing);
    verifyNever(() => player.setUrl(any())); // resume reuses the loaded track
  });

  test('shows loading while preparing and ignores repeated taps', () async {
    final load = Completer<Duration?>();
    when(() => player.setUrl(any())).thenAnswer((_) => load.future);

    final first = audio.toggle('a', a);
    emit(ProcessingState.loading, playing: false);
    expect(audio.statusOf('a'), AudioStatus.loading);
    await audio.toggle('a', a);
    await audio.toggle('a', a);
    load.complete(const Duration(seconds: 10));
    await first;

    verify(() => player.setUrl(any())).called(1);
    verify(() => player.play()).called(1);
    expect(audio.statusOf('a'), AudioStatus.playing);
  });

  test('finishing returns to idle and the next tap plays again', () async {
    await audio.toggle('a', a);
    emit(ProcessingState.completed, playing: true);
    expect(audio.statusOf('a'), AudioStatus.idle);
    await audio.toggle('a', a);
    verify(() => player.setUrl(any())).called(2);
    expect(audio.statusOf('a'), AudioStatus.playing);
  });

  test('a new track replaces the current one on the single player', () async {
    await audio.toggle('a', a);
    await audio.toggle('b', b);
    expect(audio.statusOf('a'), AudioStatus.idle);
    expect(audio.statusOf('b'), AudioStatus.playing);
  });

  test('a superseded load never starts playing', () async {
    final slow = Completer<Duration?>();
    when(() => player.setUrl(a.toString())).thenAnswer((_) => slow.future);
    final first = audio.toggle('a', a);
    await audio.toggle('b', b);
    slow.complete(const Duration(seconds: 1));
    await first;
    verify(() => player.play()).called(1); // only b
    expect(audio.statusOf('b'), AudioStatus.playing);
  });

  test('load failure reports unavailable when online, offline otherwise', () async {
    when(() => player.setUrl(any())).thenThrow(PlayerException(404, 'not found', null));
    await audio.toggle('a', a);
    expect(audio.statusOf('a'), AudioStatus.error);
    expect(audio.error, AudioError.unavailable);

    network.add([ConnectivityResult.none]);
    await audio.toggle('a', a); // retry
    expect(audio.error, AudioError.offline);
    verify(() => player.setUrl(any())).called(2);
  });

  test('a stream error during playback becomes an error state', () async {
    await audio.toggle('a', a);
    events.addError(PlayerException(0, 'connection lost', null));
    await Future<void>.delayed(Duration.zero);
    expect(audio.statusOf('a'), AudioStatus.error);
  });
}
