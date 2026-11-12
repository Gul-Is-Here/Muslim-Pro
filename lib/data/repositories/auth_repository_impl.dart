import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/data/datasources/remote/auth_remote_ds.dart';
import 'package:quran_pro/data/models/app_user.dart';
import 'package:quran_pro/data/repositories/run_catching.dart';
import 'package:quran_pro/domain/repositories/auth_repository.dart';

final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Stream<AppUser?> authStateChanges() => _remote.authStateChanges();

  @override
  Future<Result<AppUser>> signInAnonymously() => runCatching(_remote.signInAnonymously);

  @override
  Future<Result<AppUser>> signInWithEmail(String email, String password) =>
      runCatching(() => _remote.signInWithEmail(email, password));

  @override
  Future<Result<AppUser>> signUpWithEmail(String email, String password) =>
      runCatching(() => _remote.signUpWithEmail(email, password));

  @override
  Future<Result<AppUser>> signInWithGoogle() => runCatching(_remote.signInWithGoogle);

  @override
  Future<Result<AppUser>> signInWithApple() => runCatching(_remote.signInWithApple);

  @override
  Future<Result<void>> sendPasswordReset(String email) =>
      runCatching(() => _remote.sendPasswordReset(email));

  @override
  Future<Result<void>> signOut() => runCatching(_remote.signOut);
}
