import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_mobile/main.dart' as app;

void main() {
  testWidgets('launches the ScamShield home screen', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('ScamShield VN'), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
  });
}
