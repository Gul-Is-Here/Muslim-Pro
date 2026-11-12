import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/data/models/app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> authStateChanges();
  Future<Result<AppUser>> signInAnonymously();
  Future<Result<AppUser>> signInWithEmail(String email, String password);
  Future<Result<AppUser>> signUpWithEmail(String email, String password);
  Future<Result<AppUser>> signInWithGoogle();
  Future<Result<AppUser>> signInWithApple();
  Future<Result<void>> sendPasswordReset(String email);
  Future<Result<void>> signOut();
}
