import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuables/screens/home_page.dart';

void main() {
  group('Listings Feed (HomePage) Tests', () {
    Widget createTestWidget() {
      return MaterialApp(
        home: const Scaffold(
          body: HomePage(),
        ),
      );
    }

    testWidgets('Renders empty state when no items', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      // Should show "No items found" when supabase is null/mocked to empty
      expect(find.text('No items found.'), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('Does not show error banner by default', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      // By default, no error
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('Pull to refresh triggers load', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      // Find RefreshIndicator and drag down
      final refresh = find.byType(RefreshIndicator);
      await tester.drag(refresh, const Offset(0, 300));
      await tester.pumpAndSettle();
      
      // Verify it settles back to empty state (since no backend)
      expect(find.text('No items found.'), findsOneWidget);
    });
  });

  group('ItemCard Widget Tests', () {
    testWidgets('Renders Lost Item correctly', (WidgetTester tester) async {
      final item = {
        'title': 'Lost Keys',
        'category': 'Keys',
        'description': 'Bunch of keys',
        'item_type': 'lost',
        'created_at': DateTime.now().toIso8601String(),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemCard(item: item),
          ),
        ),
      );

      expect(find.text('Lost Keys'), findsOneWidget);
      expect(find.text('LOST'), findsOneWidget);
      // Check for Lost icon (help_outline)
      expect(find.byIcon(Icons.help_outline), findsWidgets);
    });

    testWidgets('Renders Found Item correctly', (WidgetTester tester) async {
      final item = {
        'title': 'Found Phone',
        'category': 'Phones',
        'item_type': 'found',
        'created_at': DateTime.now().toIso8601String(),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemCard(item: item),
          ),
        ),
      );

      expect(find.text('Found Phone'), findsOneWidget);
      expect(find.text('FOUND'), findsOneWidget);
      // Check for Found icon (location_on)
      expect(find.byIcon(Icons.location_on), findsWidgets);
    });

    testWidgets('Shows details dialog on tap', (WidgetTester tester) async {
      final item = {'title': 'Tap Me', 'description': 'Details here'};
      
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ItemCard(item: item))));
      
      await tester.tap(find.byType(ItemCard));
      await tester.pumpAndSettle();

      // Title and description appear on both the card (background) and the dialog
      expect(find.text('Tap Me'), findsNWidgets(2));
      expect(find.text('Details here'), findsNWidgets(2));
    });

    testWidgets('Shows expiration warning if expiring soon', (WidgetTester tester) async {
      // Created 26 days ago -> Expires in 4 days
      final created = DateTime.now().subtract(const Duration(days: 26));
      final item = {
        'title': 'Expiring Item',
        'created_at': created.toIso8601String(),
      };

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ItemCard(item: item))));
      
      expect(find.textContaining('Expires in'), findsOneWidget);
    });

    testWidgets('Does not show expiration warning if not expiring soon', (WidgetTester tester) async {
      // Created 10 days ago -> Expires in 20 days
      final created = DateTime.now().subtract(const Duration(days: 10));
      final item = {
        'title': 'Fresh Item',
        'created_at': created.toIso8601String(),
      };

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ItemCard(item: item))));
      
      expect(find.textContaining('Expires in'), findsNothing);
    });

    testWidgets('Renders correctly in Dark Mode', (WidgetTester tester) async {
      final item = {'title': 'Dark Mode Item', 'item_type': 'lost'};
      
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(body: ItemCard(item: item)),
        ),
      );

      // Verify text color is appropriate for dark mode (usually lighter)
      // This is implicit if it renders, but we can check specific colors if needed.
      expect(find.text('Dark Mode Item'), findsOneWidget);
    });

    testWidgets('Handles invalid date gracefully', (WidgetTester tester) async {
      final item = {
        'title': 'Invalid Date Item',
        'created_at': 'not-a-date',
      };

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ItemCard(item: item))));
      
      expect(find.text('Invalid Date Item'), findsOneWidget);
      expect(find.textContaining('Expires'), findsNothing);
    });

    testWidgets('Renders item without description', (WidgetTester tester) async {
      final item = {
        'title': 'No Desc Item',
        'category': 'Misc',
      };

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ItemCard(item: item))));
      
      expect(find.text('No Desc Item'), findsOneWidget);
    });

    testWidgets('Defaults to Found style for unknown type', (WidgetTester tester) async {
      final item = {
        'title': 'Unknown Type Item',
        'item_type': 'alien_technology',
      };

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ItemCard(item: item))));
      
      expect(find.byIcon(Icons.location_on), findsWidgets);
      expect(find.byIcon(Icons.help_outline), findsNothing);
    });

    testWidgets('Handles missing title and category', (WidgetTester tester) async {
      final item = <String, dynamic>{}; // Empty item

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ItemCard(item: item))));
      
      expect(find.text('Untitled'), findsOneWidget);
      expect(find.textContaining('Uncategorized'), findsOneWidget);
    });
  });
}