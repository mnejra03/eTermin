// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart' show Size;
import 'package:flutter_test/flutter_test.dart';

import 'package:etermin_admin/main.dart';

void main() {
  testWidgets('shows the admin login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ETerminAdminApp());

    expect(find.text('eTermin administracija'), findsOneWidget);
    expect(find.text('Prijavite se administratorskim računom'), findsOneWidget);
  });

  testWidgets('login screen fits short windows without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(368, 362);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ETerminAdminApp());

    expect(tester.takeException(), isNull);
  });
}
