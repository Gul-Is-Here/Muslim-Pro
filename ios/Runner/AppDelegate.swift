import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // The Maps key comes from Dart (env/<flavor>.json via --dart-define), so it is never in git.
    // Dart sends it once, before the first map is shown.
    FlutterMethodChannel(name: "app/maps", binaryMessenger: engineBridge.applicationRegistrar.messenger())
      .setMethodCallHandler { call, result in
        guard call.method == "setApiKey", let key = call.arguments as? String, !key.isEmpty else {
          return result(FlutterMethodNotImplemented)
        }
        result(GMSServices.provideAPIKey(key))
      }
  }
}
