import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_pro/core/errors/failure.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/utils/view_state.dart';
import 'package:quran_pro/data/models/app_user.dart';
import 'package:quran_pro/domain/repositories/auth_repository.dart';
import 'package:quran_pro/features/auth/viewmodels/auth_view_model.dart';

class _MockAuthRepository extends Mock implements AuthRepository;

void main() {
  const guest = AppUser(uid: 'u1', isGuest: true);
  late _MockAuthRepository repo;
  late AuthViewModel vm;

  setUp(() {
    repo = _MockAuthRepository();
    vm = AuthViewModel(repo);
  });
  tearDown(() => vm.onClose());

  test('guest sign-in success returns to Idle', () async {
    when(() => repo.signInAnonymously()).thenAnswer((_) async => const Ok(guest));
    await vm.continueAsGuest();
    expect(vm.state, isA<Idle<String>>());
  });

  test('failure exposes a translation key', () async {
    when(() => repo.signInWithGoogle())
        .thenAnswer((_) async => const Err(Failure('network-request-failed')));
    await vm.signInWithGoogle();
    expect(vm.state, isA<ViewError<String>>().having((s) => s.messageKey, 'key', 'err_network'));
  });

  test('cancelled Google sign-in shows no error', () async {
    when(() => repo.signInWithGoogle()).thenAnswer((_) async => const Err(Failure('cancelled')));
    await vm.signInWithGoogle();
    expect(vm.state, isA<Idle<String>>());
  });

  test('double tap sends one request', () async {
    final pending = Completer<Result<AppUser>>();
    when(() => repo.signInAnonymously()).thenAnswer((_) => pending.future);
    final first = vm.continueAsGuest();
    final second = vm.continueAsGuest();
    pending.complete(const Ok(guest));
    await Future.wait([first, second]);
    verify(() => repo.signInAnonymously()).called(1);
  });
}
