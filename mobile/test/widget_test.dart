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
    await tester.pumpAndSettle();

    // Verify initial auth screen displays Nexa brand
    expect(find.text('NEXA AI SAFETY'), findsOneWidget);
  });
}
