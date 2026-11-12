/// Values from `--dart-define-from-file=env/<flavor>.json`.
/// They are compiled into the app binary: public client identifiers only, never server secrets.
abstract final class Env {
  static const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  static const appCheckDebugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');
  static const useEmulators = bool.fromEnvironment('USE_EMULATORS');
}
