import 'dart:async';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran_pro/core/network/connectivity_service.dart';
import 'package:quran_pro/core/utils/app_log.dart';

enum AudioStatus { idle, loading, playing, paused, error }

enum AudioError { offline, unavailable }

/// App-wide player: one track at a time, so audio never overlaps, and its state outlives
/// any screen (a ViewModel that comes back reads the current state from here).
final class AudioService extends GetxService {
  AudioService(this._connectivity, [AudioPlayer? player]) : _player = player ?? AudioPlayer();

  static const _loadTimeout = Duration(seconds: 20);

  final ConnectivityService _connectivity;
  final AudioPlayer _player;
  final Rx<AudioStatus> _status = AudioStatus.idle.obs;
  final _trackId = RxnString();
  final _error = Rxn<AudioError>();
  int _loadGeneration = 0;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<PlaybackEvent>? _eventSub;

  AudioError? get error => _error.value;
  String? get trackId => _trackId.value;

  /// State of the track [id]; every other track reads as idle.
  AudioStatus statusOf(String id) => _trackId.value == id ? _status.value : AudioStatus.idle;

  @override
  void onInit() {
    super.onInit();
    _stateSub = _player.playerStateStream.listen(_onPlayerState);
    // Failures after loading (e.g. the network drops mid-stream) arrive here.
    _eventSub = _player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace _) {
        if (_status.value != AudioStatus.loading) unawaited(_fail(e)); // _load reports its own
      },
    );
  }

  /// Play [id], or pause/resume it if it is already the current track.
  /// Taps while it is preparing are ignored, so repeated taps never start it twice.
  Future<void> toggle(String id, Uri url) async {
    if (_trackId.value == id) {
      switch (_status.value) {
        case AudioStatus.loading:
          return;
        case AudioStatus.playing:
          await _player.pause();
          return;
        case AudioStatus.paused:
          unawaited(_player.play()); // completes when playback ends
          return;
        case AudioStatus.idle || AudioStatus.error:
          break; // finished or failed: load again
      }
    }
    await _load(id, url);
  }

  Future<void> stop() async {
    _loadGeneration++;
    await _player.stop();
    _status.value = AudioStatus.idle;
  }

  Future<void> _load(String id, Uri url) async {
    final generation = ++_loadGeneration;
    _trackId.value = id;
    _error.value = null;
    _status.value = AudioStatus.loading;
    try {
      await _player.setUrl(url.toString()).timeout(_loadTimeout); // replaces any current track
      if (generation != _loadGeneration) return; // a newer tap took over
      unawaited(_player.play());
    } on PlayerInterruptedException {
      // Superseded by a newer setUrl; that load owns the state now.
    } on Object catch (e) {
      if (generation == _loadGeneration) await _fail(e);
    }
  }

  Future<void> _fail(Object e) async {
    AppLog.w('Audio failed: ${e.runtimeType}');
    await _player.stop();
    _error.value = _connectivity.isOnline ? AudioError.unavailable : AudioError.offline;
    _status.value = AudioStatus.error;
  }

  void _onPlayerState(PlayerState s) {
    // While _load prepares a track it owns the state; playback starting hands it back.
    if (_status.value == AudioStatus.loading && !s.playing) return;
    _status.value = switch (s.processingState) {
      ProcessingState.completed => AudioStatus.idle,
      ProcessingState.loading || ProcessingState.buffering => AudioStatus.loading,
      ProcessingState.ready => s.playing ? AudioStatus.playing : AudioStatus.paused,
      ProcessingState.idle => _status.value, // stopped or failed: set by stop()/_fail()
    };
  }

  @override
  void onClose() {
    unawaited(_stateSub?.cancel());
    unawaited(_eventSub?.cancel());
    unawaited(_player.dispose());
    super.onClose();
  }
}
