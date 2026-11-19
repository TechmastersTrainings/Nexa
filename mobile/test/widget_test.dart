import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_safety/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('NexaSafetyApp renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const NexaSafetyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify app renders with root navigation and auth gate
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(AuthGate), findsOneWidget);
  });
}
