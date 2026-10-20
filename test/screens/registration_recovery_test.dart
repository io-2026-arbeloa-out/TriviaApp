import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/screens/registration_screen.dart';
import 'package:triviaapp/services/auth_register_service.dart';

import '../fakes.dart';

class _PendingRegistration extends FakeRegisterAuthService {
  final result = Completer<ProfileData>();

  @override
  Future<ProfileData> register(
    String email,
    String password,
    String username,
  ) => result.future;
}

Future<void> _submit(
  WidgetTester tester,
  FakeRegisterAuthService service,
) async {
  tester.view.physicalSize = const Size(430, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(home: RegistrationScreen(authService: service)),
  );
  await tester.pumpAndSettle();
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'User');
  await tester.enterText(fields.at(1), 'user@example.com');
  await tester.enterText(fields.at(2), 'password123');
  await tester.enterText(fields.at(3), 'password123');
  final button = find.widgetWithText(ElevatedButton, 'Zarejestruj');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pump();
}

void main() {
  testWidgets('explains how to retry incomplete registration', (tester) async {
    final service = FakeRegisterAuthService()
      ..registerError = IncompleteRegistrationException(
        Exception('Write failed'),
      );
    await _submit(tester, service);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Konto zostało utworzone. Nie udało się dokończyć rejestracji. '
        'Ponów próbę z tym samym adresem email.',
      ),
      findsOneWidget,
    );
    expect(find.byType(RegistrationScreen), findsOneWidget);
  });

  testWidgets('ignores registration failure after leaving', (tester) async {
    final service = _PendingRegistration();
    await _submit(tester, service);
    await tester.pumpWidget(const SizedBox());
    service.result.completeError(
      IncompleteRegistrationException(Exception('Write failed')),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
