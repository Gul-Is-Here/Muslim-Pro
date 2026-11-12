import 'dart:async';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

final class AudioService extends GetxService {
  final _player = AudioPlayer();
  final RxBool _playing = false.obs;
  StreamSubscription<PlayerState>? _sub;

  bool get isPlaying => _playing.value;

  @override
  void onInit() {
    super.onInit();
    _sub = _player.playerStateStream.listen(
      (s) => _playing.value = s.playing && s.processingState != ProcessingState.completed,
    );
  }

  Future<void> playAsset(String path) async {
    await _player.setAsset(path);
    unawaited(_player.play()); // completes when playback ends
  }

  Future<void> stop() => _player.stop();

  @override
  void onClose() {
    unawaited(_sub?.cancel());
    unawaited(_player.dispose());
    super.onClose();
  }
}
