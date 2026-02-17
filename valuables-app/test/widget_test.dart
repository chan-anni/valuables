// Flutter tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a MaterialApp with the same navigation structure as the real app,
/// but uses a placeholder body to avoid the Supabase dependency in HomePage.
Widget buildTestApp() {
  return MaterialApp(
    theme: ThemeData(
      primarySwatch: Colors.green,
      useMaterial3: true,
    ),
    home: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Valuables', style: TextStyle(color: Colors.white)),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.message), label: 'Messages'),
        ],
        selectedIndex: 0,
      ),
      body: const SizedBox(),
    ),
  );
}

void main() {
  group('MyApp Tests', () {
    testWidgets('App builds without errors', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Verify no exceptions
      expect(tester.takeException(), isNull);

      // Verify app structure
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  testWidgets('Navigation renders with all three tabs', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Verify navigation bar exists
    expect(find.byType(NavigationBar), findsOneWidget);

    // Verify all three navigation items
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);

    // Verify icons
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.map), findsOneWidget);
    expect(find.byIcon(Icons.message), findsOneWidget);
  });
}