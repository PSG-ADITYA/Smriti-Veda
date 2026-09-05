import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_veda/main.dart';

void main() {
  testWidgets('Smriti Veda app launches smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmritiVedaApp());

    // Verify app renders title
    expect(find.textContaining('Smriti Veda'), findsWidgets);
  });
}
