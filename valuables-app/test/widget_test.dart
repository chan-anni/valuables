// Flutter tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuables/main.dart';

void main() {
  group('MyApp Tests', () {
    testWidgets('App builds without errors', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify no exceptions
      expect(tester.takeException(), isNull);
      
      // Verify app structure
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Navigation), findsOneWidget);
    });
  });

  testWidgets('Navigation renders with all three tabs', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
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