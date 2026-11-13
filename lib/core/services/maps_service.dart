import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/config/env.dart';
import 'package:quran_pro/core/utils/app_log.dart';

/// Google Maps needs an API key. Android reads it from the manifest (build.gradle.kts injects it);
/// iOS gets it here once, through AppDelegate's `app/maps` channel, before the first map.
final class MapsService extends GetxService {
  static const _channel = MethodChannel('app/maps');
  Future<bool>? _ready;

  bool get configured => Env.googleMapsApiKey.isNotEmpty;

  Future<bool> ensureReady() => _ready ??= _init();

  Future<bool> _init() async {
    if (!configured) return false;
    if (!GetPlatform.isIOS) return true;
    try {
      return await _channel.invokeMethod<bool>('setApiKey', Env.googleMapsApiKey) ?? false;
    } on PlatformException catch (e, s) {
      AppLog.e(e, s);
      return false;
    }
  }
}
