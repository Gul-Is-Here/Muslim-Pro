import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_pro/app/routes/app_routes.dart';
import 'package:quran_pro/core/errors/failure.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/core/localization/app_translations.dart';
import 'package:quran_pro/core/utils/validators.dart';
import 'package:quran_pro/core/utils/view_state.dart';
import 'package:quran_pro/data/models/app_user.dart';
import 'package:quran_pro/domain/repositories/auth_repository.dart';
import 'package:quran_pro/features/auth/bindings/auth_binding.dart';
import 'package:quran_pro/features/auth/viewmodels/forgot_password_view_model.dart';
import 'package:quran_pro/features/auth/viewmodels/sign_up_view_model.dart';
import 'package:quran_pro/features/auth/views/auth_view.dart';
import 'package:quran_pro/features/auth/views/forgot_password_view.dart';
import 'package:quran_pro/features/auth/views/sign_up_view.dart';

class _Repo extends Mock implements AuthRepository;

void main() {
  tearDown(Get.reset);

  test('password strength', () {
    expect(Validators.passwordStrength(''), 0);
    expect(Validators.passwordStrength('Ab1!'), 1, reason: 'short never rates above weak');
    expect(Validators.passwordStrength('abcdefgh'), 1);
    expect(Validators.passwordStrength('abcdefg1'), 2);
    expect(Validators.passwordStrength('Abcdefg1'), 3);
    expect(Validators.passwordStrength('Salam*2024'), 4);
  });

  test('sign-up rates the password as it is typed', () async {
    final repo = _Repo();
    when(() => repo.signUpWithEmail(any(), any(), name: any(named: 'name')))
        .thenAnswer((_) async => const Ok(AppUser(uid: 'u', isGuest: false)));
    final vm = SignUpViewModel(repo)..onInit();
    vm.passwordCtrl.text = 'Salam*2024';
    expect(vm.strength, 4);
    expect(vm.strengthKey, 'pw_strong');
    vm.onClose();
  });

  test('reset: success remembers the address; failure stays on the form', () async {
    final repo = _Repo();
    when(() => repo.sendPasswordReset('a@b.co')).thenAnswer((_) async => const Ok(null));
    when(() => repo.sendPasswordReset('x@y.co'))
        .thenAnswer((_) async => const Err(Failure('too-many-requests')));
    final vm = ForgotPasswordViewModel(repo, email: 'a@b.co');
    expect(await vm.run(() => repo.sendPasswordReset('a@b.co')), isTrue);
    expect(await vm.run(() => repo.sendPasswordReset('x@y.co')), isFalse);
    expect(vm.state, isA<ViewError<String>>());
    vm.useAnotherEmail();
    expect(vm.state, isA<Idle<String>>());
    vm.onClose();
  });

  for (final (name, size, ratio) in [
    ('Pixel 7 Pro', const Size(1080, 2340), 2.625),
    ('small phone', const Size(720, 1280), 2.0),
  ]) {
    testWidgets('sign in → forgot password (email carried over) → sent; sign up on $name', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      final repo = _Repo();
      when(() => repo.sendPasswordReset(any())).thenAnswer((_) async => const Ok(null));
      Get.put<AuthRepository>(repo);
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          initialRoute: AppRoutes.auth,
          getPages: [
            GetPage(name: AppRoutes.auth, page: () => const AuthView(), binding: AuthBinding()),
            GetPage(
              name: AppRoutes.signUp,
              page: () => const SignUpView(),
              binding: SignUpBinding(),
            ),
            GetPage(
              name: AppRoutes.forgotPassword,
              page: () => const ForgotPasswordView(),
              binding: ForgotPasswordBinding(),
            ),
          ],
        ),
      );
      expect(find.text('Welcome to Noor'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextFormField).first, 'a@b.co');
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.text('Forgot your password?'), findsOneWidget);
      expect(find.text('a@b.co'), findsOneWidget, reason: 'email carried over');
      await tester.tap(find.byKey(const Key('reset_submit')));
      await tester.pumpAndSettle();
      expect(find.text('Check your inbox'), findsOneWidget);
      verify(() => repo.sendPasswordReset('a@b.co')).called(1);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Back to sign in'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Sign up'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();
      expect(find.text('Begin your journey'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('sign_up_submit')));
      await tester.tap(find.byKey(const Key('sign_up_submit')));
      await tester.pump();
      expect(find.text('Enter your name.'), findsOneWidget);
      verifyNever(() => repo.signUpWithEmail(any(), any(), name: any(named: 'name')));

      when(() => repo.signUpWithEmail(any(), any(), name: any(named: 'name')))
          .thenAnswer((_) async => const Ok(AppUser(uid: 'u', isGuest: false)));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '  Zayd ');
      await tester.enterText(fields.at(1), 'z@y.co');
      await tester.enterText(fields.at(2), 'Salam*2024');
      await tester.pump();
      expect(find.text('Strong'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('sign_up_submit')));
      await tester.tap(find.byKey(const Key('sign_up_submit')));
      await tester.pump();
      verify(() => repo.signUpWithEmail('z@y.co', 'Salam*2024', name: 'Zayd')).called(1);
      expect(tester.takeException(), isNull);
    });
  }
}
