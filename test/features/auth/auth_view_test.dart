import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_pro/core/localization/app_translations.dart';
import 'package:quran_pro/core/localization/en.dart';
import 'package:quran_pro/domain/repositories/auth_repository.dart';
import 'package:quran_pro/features/auth/viewmodels/auth_view_model.dart';
import 'package:quran_pro/features/auth/views/auth_view.dart';

class _MockAuthRepository extends Mock implements AuthRepository;

void main() {
  tearDown(Get.reset);

  testWidgets('empty submit shows validation errors and never calls the repository', (
    tester,
  ) async {
    final repo = _MockAuthRepository();
    Get.put(AuthViewModel(repo));
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: AppTranslations.fallback,
        home: const AuthView(),
      ),
    );

    await tester.tap(find.byKey(const Key('auth_submit')));
    await tester.pump();

    expect(find.text(en['err_invalid_email']!), findsOneWidget);
    expect(find.text(en['err_weak_password']!), findsOneWidget);
    verifyNever(() => repo.signInWithEmail(any(), any()));
  });
}
