import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:quran_pro/core/config/env.dart';
import 'package:quran_pro/data/datasources/remote/firebase_guard.dart';
import 'package:quran_pro/data/models/app_user.dart';

final class AuthRemoteDataSource {
  AuthRemoteDataSource({FirebaseAuth? auth, GoogleSignIn? google})
    : _auth = auth ?? FirebaseAuth.instance,
      _google = google ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  Future<void>? _googleReady;

  /// userChanges (not authStateChanges) so a guest → linked upgrade is emitted too.
  Stream<AppUser?> authStateChanges() =>
      _auth.userChanges().map((u) => u == null ? null : _toModel(u));

  Future<AppUser> signInAnonymously() =>
      guard(() async => _toModel((await _auth.signInAnonymously()).user!));

  Future<AppUser> signInWithEmail(String email, String password) => guard(() async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return _toModel(cred.user!);
  });

  /// A guest is upgraded in place (same uid, progress kept); otherwise a new account is created.
  Future<AppUser> signUpWithEmail(String email, String password) => guard(() async {
    final guest = _currentGuest;
    final cred = guest != null
        ? await guest.linkWithCredential(
            EmailAuthProvider.credential(email: email, password: password),
          )
        : await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user!.sendEmailVerification();
    return _toModel(cred.user!);
  });

  Future<AppUser> signInWithGoogle() => guard(() async {
    await (_googleReady ??= _google.initialize(
      serverClientId: Env.googleServerClientId.isEmpty ? null : Env.googleServerClientId,
    ));
    final account = await _google.authenticate();
    final credential = GoogleAuthProvider.credential(idToken: account.authentication.idToken);
    return _toModel(
      await _upgradeGuestOr(
        link: (guest) => guest.linkWithCredential(credential),
        signIn: () => _auth.signInWithCredential(credential),
      ),
    );
  });

  Future<AppUser> signInWithApple() => guard(() async {
    final provider = AppleAuthProvider()..addScope('email');
    return _toModel(
      await _upgradeGuestOr(
        link: (guest) => guest.linkWithProvider(provider),
        signIn: () => _auth.signInWithProvider(provider),
      ),
    );
  });

  Future<void> sendPasswordReset(String email) =>
      guard(() => _auth.sendPasswordResetEmail(email: email));

  Future<void> signOut() => guard(() async {
    await _auth.signOut();
    if (_googleReady != null) await _google.signOut(); // next Google sign-in shows the picker
  });

  User? get _currentGuest {
    final u = _auth.currentUser;
    return u != null && u.isAnonymous ? u : null;
  }

  Future<User> _upgradeGuestOr({
    required Future<UserCredential> Function(User guest) link,
    required Future<UserCredential> Function() signIn,
  }) async {
    final guest = _currentGuest;
    if (guest == null) return (await signIn()).user!;
    try {
      return (await link(guest)).user!;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'credential-already-in-use') rethrow;
      // The account already exists: switch to it. Guest data stays with the abandoned anonymous uid.
      final existing = e.credential;
      return existing != null
          ? (await _auth.signInWithCredential(existing)).user!
          : (await signIn()).user!;
    }
  }

  AppUser _toModel(User u) =>
      AppUser(uid: u.uid, isGuest: u.isAnonymous, email: u.email, displayName: u.displayName);
}
