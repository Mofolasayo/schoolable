import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:schoolable/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches', (tester) async {
    await app.main();
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
