import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_mobile/main.dart' as app;

void main() {
  testWidgets('launches the ScamShield home screen', (tester) async {
    await tester.runAsync(app.main);
    await tester.pumpAndSettle();

    expect(find.text('ScamShield'), findsOneWidget);
    expect(find.byIcon(Icons.verified_user_outlined), findsOneWidget);
  });
}
