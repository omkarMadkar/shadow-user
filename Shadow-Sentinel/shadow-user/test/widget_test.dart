import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shadow_sentinel/main.dart';
import 'package:shadow_sentinel/providers/sentinel_provider.dart';

void main() {
  testWidgets('Shadow Sentinel app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SentinelProvider(),
        child: const ShadowSentinelApp(),
      ),
    );

    // Verify the app title is present
    expect(find.text('SHADOW'), findsOneWidget);
    expect(find.text('SENTINEL'), findsOneWidget);

    // Verify bottom navigation items exist
    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(find.text('EMAIL SENTINEL'), findsOneWidget);
    expect(find.text('NEURAL CAMERA'), findsOneWidget);
  });
}
