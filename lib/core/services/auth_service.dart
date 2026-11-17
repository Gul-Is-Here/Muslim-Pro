import 'dart:async';

import 'package:get/get.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/data/models/app_user.dart';
import 'package:quran_pro/domain/repositories/auth_repository.dart';

final class AuthService extends GetxService {
  AuthService(this._repo);

  final AuthRepository _repo;
  final _user = Rxn<AppUser>();
  final _ready = Completer<void>();
  StreamSubscription<AppUser?>? _sub;

  AppUser? get user => _user.value;
  bool get isSignedIn => _user.value != null;
  Stream<AppUser?> get userChanges => _user.stream;

  /// Completes once Firebase has restored the persisted session (or found none).
  Future<void> get ready => _ready.future;

  @override
  void onInit() {
    super.onInit();
    _sub = _repo.authStateChanges().listen((u) {
      _user.value = u; // Equatable: token refreshes with identical data do not re-emit
      if (!_ready.isCompleted) _ready.complete();
    });
  }

  Future<Result<void>> signOut() => _repo.signOut(); // SessionController handles the rest

  @override
  void onClose() {
    unawaited(_sub?.cancel());
    super.onClose();
  }
}
