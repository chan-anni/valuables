import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuables/screens/lost_item_form.dart';

// testing
void main() {
  group('LostItemForm Basic Tests', () {
    testWidgets('Form renders correctly with all fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LostItemForm(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Verify form renders without errors
      expect(tester.takeException(), isNull);
      
      // Verify form elements exist
      expect(find.byType(Form), findsOneWidget);
      expect(find.text('Report Item'), findsOneWidget);
      expect(find.text('Item Title *'), findsOneWidget);
      expect(find.text('Description *'), findsOneWidget);
      expect(find.text('Category *'), findsOneWidget);
    });

    testWidgets('Type selector switches between Lost and Found', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LostItemForm(),
        ),
      );
      await tester.pumpAndSettle();
      
      // Initially shows "Date Lost"
      expect(find.text('Date Lost *'), findsOneWidget);
      
      // Switch to Found
      await tester.tap(find.text('Found'));
      await tester.pumpAndSettle();
      
      // Should now show "Date Found"
      expect(find.text('Date Found *'), findsOneWidget);
    });

    testWidgets('All categories are available in dropdown', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LostItemForm(),
        ),
      );
      await tester.pumpAndSettle();
      
      // Open the category dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      
      // Verify key categories exist
      expect(find.text('Phones'), findsWidgets);
      expect(find.text('Laptops'), findsWidgets);
      expect(find.text('Keys'), findsWidgets);
      expect(find.text('Wallets'), findsWidgets);
      expect(find.text('Other'), findsWidgets);
    });
  });

    testWidgets('Category field validates when not selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LostItemForm(),
        ),
      );
      await tester.pumpAndSettle();
      
      // Fill title and description but not category
      final titleField = find.widgetWithText(TextFormField, 'Item Title *');
      await tester.enterText(titleField, 'Test Item');
      await tester.pumpAndSettle();
      
      final descriptionField = find.widgetWithText(TextFormField, 'Description *');
      await tester.enterText(descriptionField, 'Test description');
      await tester.pumpAndSettle();
      
      // Scroll to and tap submit
      await tester.dragUntilVisible(
        find.text('Submit Report'),
        find.byType(ListView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Submit Report'));
      await tester.pumpAndSettle();
      
      // Should show category validation error
      expect(find.text('Please select a category'), findsOneWidget);
    });

    testWidgets('Description field validates empty input', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LostItemForm(),
        ),
      );
      await tester.pumpAndSettle();
      
      // Fill title and select category
      final titleField = find.widgetWithText(TextFormField, 'Item Title *');
      await tester.enterText(titleField, 'Test Item');
      await tester.pumpAndSettle();
      
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phones').last);
      await tester.pumpAndSettle();
      
      // Scroll to and tap submit
      await tester.dragUntilVisible(
        find.text('Submit Report'),
        find.byType(ListView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Submit Report'));
      await tester.pumpAndSettle();
      
      // Should show description validation error
      expect(find.text('Please enter a description'), findsOneWidget);
    });


  group('LostItemForm Interaction Tests', () {
    testWidgets('Date picker opens when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LostItemForm(),
        ),
      );
      await tester.pumpAndSettle();
      
      // Initial state shows "Tap to select date"
      expect(find.text('Tap to select date'), findsOneWidget);
      
      // Tap the date field
      await tester.tap(find.text('Date Lost *'));
      await tester.pumpAndSettle();
      
      // Date picker dialog should open
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });
    
  });
}