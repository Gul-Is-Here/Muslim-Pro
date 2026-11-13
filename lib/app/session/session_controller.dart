import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/core/services/auth_service.dart';
import 'package:quran_pro/data/models/app_user.dart';

final class SessionController extends GetxService {
  SessionController(this._auth);

  /// Anything user-specific cached on device goes in this box; it is erased on session end.
  static const userCacheBox = 'user_cache';

  final AuthService _auth;
  StreamSubscription<AppUser?>? _sub;
  String? _uid;

  @override
  void onInit() {
    super.onInit();
    // Start after Firebase restores the persisted session: that first emission is not a
    // sign-in, and navigating on it would run before GetMaterialApp exists.
    unawaited(
      _auth.ready.then((_) {
        if (isClosed) return;
        _uid = _auth.user?.uid;
        _sub = _auth.userChanges.listen((u) => unawaited(_onUserChanged(u)));
      }),
    );
  }

  Future<void> _onUserChanged(AppUser? user) async {
    if (user?.uid == _uid) return; // guest upgraded in place keeps its uid: same session
    final sessionEnded = _uid != null;
    _uid = user?.uid;
    if (sessionEnded) await GetStorage(userCacheBox).erase();
    // offAllNamed removes every route; GetX then calls Get.delete on each route-bound
    // ViewModel, so no user-scoped controller or its data survives into the next session.
    unawaited(Get.offAllNamed<void>(user == null ? AppRoutes.auth : AppRoutes.home));
  }

  @override
  void onClose() {
    unawaited(_sub?.cancel());
    super.onClose();
  }
}
