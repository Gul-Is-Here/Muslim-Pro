import 'dart:async';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:quran_pro/core/network/connectivity_service.dart';
import 'package:quran_pro/core/utils/app_log.dart';

enum AudioStatus { idle, loading, playing, paused, error }

enum AudioError { offline, unavailable }

/// Playlist repeat: none, the current track (one ayah), or the whole list (the surah).
enum AudioRepeat { off, one, all }

/// What the notification bar and lock screen show for a track.
typedef NowPlaying = ({String title, String subtitle});

/// One entry of a playlist, e.g. an ayah of a surah.
typedef Track = ({Uri url, NowPlaying info});

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
  final _index = Rxn<int>();
  final RxDouble _speed = 1.0.obs;
  final Rx<AudioRepeat> _repeat = AudioRepeat.off.obs;
  int _loadGeneration = 0;
  StreamSubscription<int?>? _indexSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<PlaybackEvent>? _eventSub;

  AudioError? get error => _error.value;
  String? get trackId => _trackId.value;

  /// State of the track [id]; every other track reads as idle.
  AudioStatus statusOf(String id) => _trackId.value == id ? _status.value : AudioStatus.idle;

  /// Position in the playlist [id] is playing, or null when [id] is not the current track.
  int? indexOf(String id) => _trackId.value == id ? _index.value : null;

  /// Emits whenever the playlist moves to another track.
  Stream<int?> get indexChanges => _index.stream;

  double get speed => _speed.value;
  AudioRepeat get repeat => _repeat.value;

  @override
  void onInit() {
    super.onInit();
    _stateSub = _player.playerStateStream.listen(_onPlayerState);
    _indexSub = _player.currentIndexStream.listen((i) => _index.value = i);
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
  /// [start] skips a spoken intro (a chapter title before the dhikr).
  Future<void> toggle(
    String id,
    Uri url, {
    required NowPlaying info,
    Duration start = Duration.zero,
  }) => _toggle(id, () => _load(id, url, info, start: start));

  /// Like [toggle], for tracks played back to back (a whole surah). The media notification
  /// gets next/previous buttons.
  Future<void> togglePlaylist(String id, List<Track> tracks) =>
      _toggle(id, () => _loadPlaylist(id, tracks, 0));

  /// Plays playlist [id] from [index]: jumps within it when it is already loaded.
  Future<void> playFrom(String id, List<Track> tracks, int index) async {
    final loaded =
        _trackId.value == id &&
        _status.value != AudioStatus.idle &&
        _status.value != AudioStatus.error;
    if (!loaded) {
      await _loadPlaylist(id, tracks, index);
      return;
    }
    await _player.seek(Duration.zero, index: index);
    if (!_player.playing) unawaited(_player.play());
  }

  Future<void> next() => _player.seekToNext();
  Future<void> previous() => _player.seekToPrevious();

  Future<void> setSpeed(double speed) async {
    _speed.value = speed;
    await _player.setSpeed(speed);
  }

  Future<void> setRepeat(AudioRepeat mode) async {
    _repeat.value = mode;
    await _player.setLoopMode(_loopMode(mode));
  }

  static LoopMode _loopMode(AudioRepeat m) => switch (m) {
    AudioRepeat.off => LoopMode.off,
    AudioRepeat.one => LoopMode.one,
    AudioRepeat.all => LoopMode.all,
  };

  Future<void> _loadPlaylist(String id, List<Track> tracks, int index) => _start(id, () async {
    await _player.setLoopMode(_loopMode(_repeat.value));
    return await _player.setAudioSources([
      for (final (i, t) in tracks.indexed)
        AudioSource.uri(t.url, tag: _mediaItem('$id#$i', t.info)),
    ], initialIndex: index);
  });

  Future<void> _toggle(String id, Future<void> Function() load) async {
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
    await load();
  }

  /// Plays from the start every time (short clips such as letter names).
  Future<void> play(String id, Uri url, {required NowPlaying info}) => _load(id, url, info);

  Future<void> stop() async {
    _loadGeneration++;
    await _player.stop();
    _status.value = AudioStatus.idle;
  }

  // The tag drives the system media notification (play/pause/seek/stop from outside the app).
  static MediaItem _mediaItem(String id, NowPlaying info) =>
      MediaItem(id: id, title: info.title, artist: info.subtitle, album: 'Noor');

  Future<void> _load(String id, Uri url, NowPlaying info, {Duration start = Duration.zero}) =>
      _start(id, () async {
        // Repeat belongs to surah playback; a letter or preview clip must never loop.
        if (_repeat.value != AudioRepeat.off) await _player.setLoopMode(LoopMode.off);
        final item = _mediaItem(id, info);
        if (start == Duration.zero) return await _player.setUrl(url.toString(), tag: item);
        return await _player.setAudioSource(
          ClippingAudioSource(start: start, child: AudioSource.uri(url), tag: item),
        );
      });

  /// Replaces whatever is loaded with [source] and plays it, unless a newer tap took over.
  Future<void> _start(String id, Future<Duration?> Function() source) async {
    final generation = ++_loadGeneration;
    _trackId.value = id;
    _error.value = null;
    _status.value = AudioStatus.loading;
    try {
      await source().timeout(_loadTimeout); // replaces any current track
      if (generation != _loadGeneration) return; // a newer tap took over
      unawaited(_player.play());
    } on PlayerInterruptedException {
      // Superseded by a newer load; that one owns the state now.
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
    unawaited(_indexSub?.cancel());
    unawaited(_eventSub?.cancel());
    unawaited(_player.dispose());
    super.onClose();
  }
}
