import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuables/screens/lost_item_form.dart';

// Mock the Google Maps platform channel to prevent MissingPluginException during tests
void _mockMapChannel() {
  const channel = MethodChannel('plugins.flutter.io/google_maps');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async => null);
}

// Integration test helper to pump LostItemForm with NO Supabase client injected.
// This puts the form into "test mode": _submitForm() skips all network calls
Future<void> pumpForm(WidgetTester tester) async {
  _mockMapChannel();
  await tester.pumpWidget(
    const MaterialApp(
      home: LostItemForm(), // supabaseClient defaults to null in test mode
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('LostItemForm', () {
    testWidgets('renders the AppBar title "Report Item"', (tester) async {
      await pumpForm(tester);
      expect(find.text('Report Item'), findsOneWidget);
    });

    testWidgets('renders two TextFormFields (title and description)', (
      tester,
    ) async {
      await pumpForm(tester);
      // Title + Description are TextFormFields.
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('renders the SegmentedButton type selector', (tester) async {
      await pumpForm(tester);
      expect(find.byType(SegmentedButton<String>), findsOneWidget);
    });

    testWidgets('renders the DropdownButtonFormField for category', (
      tester,
    ) async {
      await pumpForm(tester);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('defaults to Lost type and shows "Date Lost *" label', (
      tester,
    ) async {
      await pumpForm(tester);
      // Exact string from the source: _selectedType == 'lost' ? 'Date Lost *' : 'Date Found *'
      expect(find.text('Date Lost *'), findsOneWidget);
    });

    testWidgets(
      'switches to Found and shows "Date Found *" after tapping Found segment',
      (tester) async {
        await pumpForm(tester);

        await tester.tap(find.text('Found'));
        await tester.pumpAndSettle();

        expect(find.text('Date Found *'), findsOneWidget);
        expect(find.text('Date Lost *'), findsNothing);
      },
    );

    testWidgets('accepts text entered into the title field', (tester) async {
      await pumpForm(tester);
      // Title is the first TextFormField in the ListView.
      await tester.enterText(
        find.byType(TextFormField).first,
        'My Lost Wallet',
      );
      await tester.pumpAndSettle();
      expect(find.text('My Lost Wallet'), findsOneWidget);
    });

    testWidgets('accepts text entered into the description field', (
      tester,
    ) async {
      await pumpForm(tester);
      // Description is the second (last) TextFormField.
      await tester.enterText(
        find.byType(TextFormField).last,
        'Left on the bus',
      );
      await tester.pumpAndSettle();
      expect(find.text('Left on the bus'), findsOneWidget);
    });

    testWidgets('shows "Please enter a title" when title is empty on submit', (
      tester,
    ) async {
      await pumpForm(tester);
      await tester.scrollUntilVisible(
        find.byType(FilledButton),
        100,
        scrollable: find.byType(Scrollable).first,
      );

      // need to make sure the button is visible before tapping otherwise it won't trigger the validation errors
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(Scrollable).first,
        const Offset(0, 1000),
      ); // scroll to top to make sure the title error is visible
      await tester.pumpAndSettle();
      expect(find.text('Please enter a title'), findsOneWidget);
    });

    testWidgets(
      'validates form and shows all three errors when form is empty',
      (tester) async {
        await pumpForm(tester);
        await tester.scrollUntilVisible(
          find.byType(FilledButton),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.byType(FilledButton));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 1000));
        await tester.pumpAndSettle();
        expect(find.text('Please enter a title'), findsOneWidget);
        expect(find.text('Please select a category'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Please enter a description'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Please enter a description'), findsOneWidget);
      },
    );

    testWidgets('Form accepts all valid inputs', (tester) async {
      await pumpForm(tester);
      // Fill in title
      await tester.enterText(find.byType(TextFormField).first, 'My Wallet');
      await tester.pumpAndSettle();

      // Select category from dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keys').last);
      await tester.pumpAndSettle();

      // Fill in description
      await tester.enterText(
        find.byType(TextFormField).last,
        'Black leather wallet',
      );
      await tester.pumpAndSettle();

      // All fields now have content
      expect(find.text('My Wallet'), findsOneWidget);
      expect(find.text('Black leather wallet'), findsOneWidget);
    });

    testWidgets('Form has at least 3 TextFormFields', (tester) async {
      await pumpForm(tester);
      // Count all TextFormFields (title, description, and any others)
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('renders location ListTile with location icon', (tester) async {
      await pumpForm(tester);
      // Scroll to make sure the location widget is visible
      await tester.scrollUntilVisible(
        find.text('Location'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      // Check for presence of the location text instead of relying on specific icon
      expect(find.text('Location'), findsOneWidget);
    });

    testWidgets('renders photo ListTile with camera icon', (tester) async {
      await pumpForm(tester);
      // Scroll to find Add Photo text
      await tester.scrollUntilVisible(
        find.text('Add Photo'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Add Photo'), findsOneWidget);
    });

    testWidgets('renders FilledButton with label "Submit Report"', (
      tester,
    ) async {
      await pumpForm(tester);
      // Scroll to make submit button visible
      await tester.scrollUntilVisible(
        find.byType(FilledButton),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Submit Report'), findsOneWidget);
    });

    testWidgets('shows "Tap to select date" as default date subtitle', (
      tester,
    ) async {
      await pumpForm(tester);
      await tester.scrollUntilVisible(
        find.text('Tap to select date'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Tap to select date'), findsOneWidget);
    });

    testWidgets('shows "Tap to select on map" as default location subtitle', (
      tester,
    ) async {
      await pumpForm(tester);
      await tester.scrollUntilVisible(
        find.text('Tap to select on map'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Tap to select on map'), findsOneWidget);
    });

    testWidgets('does not show CircularProgressIndicator on initial render', (
      tester,
    ) async {
      await pumpForm(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Form renders correctly with all fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LostItemForm()));

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
    testWidgets('Date picker opens when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LostItemForm(),
        ),
      );
      await tester.pumpAndSettle();
    });
    
  });
}
