import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

final class ConnectivityService extends GetxService {
  ConnectivityService([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final RxBool _online = true.obs;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  /// A network interface is up. Not proof of internet access — use as a UI hint only.
  bool get isOnline => _online.value;

  @override
  void onInit() {
    super.onInit();
    _sub = _connectivity.onConnectivityChanged.listen(_update);
    unawaited(_connectivity.checkConnectivity().then(_update));
  }

  void _update(List<ConnectivityResult> results) =>
      _online.value = results.any((r) => r != ConnectivityResult.none);

  @override
  void onClose() {
    unawaited(_sub?.cancel());
    super.onClose();
  }
}
