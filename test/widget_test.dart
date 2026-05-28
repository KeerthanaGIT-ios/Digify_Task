import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_discovery/main.dart';

void main() {
  testWidgets('MovieDiscoveryApp compilation and render smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MovieDiscoveryApp(),
      ),
    );

    // Verify that the MovieDiscoveryApp runs and builds the Material Router
    expect(find.byType(MovieDiscoveryApp), findsOneWidget);
  });
}
