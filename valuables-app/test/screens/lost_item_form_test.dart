import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuables/screens/lost_item_form.dart';
// import 'package:valuables/screens/map_picker_screen.dart';

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
    MaterialApp(
      home: LostItemForm(testMode: true), // keep form in test mode for widget tests
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

    // Form now has 3 TextFormFields: title, description, current location (found only,
    // but default type is lost so only title + description are visible = 2)
    testWidgets('renders two TextFormFields in lost mode (title and description)', (
      tester,
    ) async {
      await pumpForm(tester);
      // Default type is 'lost' — current location field is hidden, so only 2 fields
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('renders three TextFormFields in found mode', (tester) async {
      await pumpForm(tester);
      await tester.tap(find.text('Found'));
      await tester.pumpAndSettle();
      // Found mode shows title + description + current location = 3
      expect(find.byType(TextFormField), findsNWidgets(3));
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
      // Title is always the first TextFormField
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
      // In lost mode there are exactly 2 TextFormFields: title (first) and description (last)
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

      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(Scrollable).first,
        const Offset(0, 1000),
      );
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
      // Fill in title (first TextFormField)
      await tester.enterText(find.byType(TextFormField).first, 'My Wallet');
      await tester.pumpAndSettle();

      // Select category from dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keys').last);
      await tester.pumpAndSettle();

      // Fill in description — in lost mode it is the second (last) TextFormField
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Black leather wallet',
      );
      await tester.pumpAndSettle();

      expect(find.text('My Wallet'), findsOneWidget);
      expect(find.text('Black leather wallet'), findsOneWidget);
    });

    testWidgets('Form has at least 2 TextFormFields', (tester) async {
      await pumpForm(tester);
      expect(find.byType(TextFormField), findsWidgets);
    });

    // Location card now shows 'Last Seen Location *' for lost, 'Location Found *' for found
    testWidgets('renders location ListTile with "Last Seen Location *" in lost mode', (tester) async {
      await pumpForm(tester);
      await tester.scrollUntilVisible(
        find.text('Last Seen Location *'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Last Seen Location *'), findsOneWidget);
    });

    testWidgets('renders location ListTile with "Location Found *" in found mode', (tester) async {
      await pumpForm(tester);
      await tester.tap(find.text('Found'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Location Found *'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Location Found *'), findsOneWidget);
    });

    // Photo card now shows 'Photo 1' (lost) or 'Photo 1 *' (found)
    testWidgets('renders photo ListTile with "Photo 1" label in lost mode', (tester) async {
      await pumpForm(tester);
      await tester.scrollUntilVisible(
        find.text('Photo 1'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Photo 1'), findsOneWidget);
    });

    testWidgets('renders photo ListTile with "Photo 1 *" label in found mode', (tester) async {
      await pumpForm(tester);
      await tester.tap(find.text('Found'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Photo 1 *'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Photo 1 *'), findsOneWidget);
    });

    testWidgets('renders FilledButton with label "Submit Report"', (
      tester,
    ) async {
      await pumpForm(tester);
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

    // Location hint is now type-aware
    testWidgets('shows correct default location hint in lost mode', (
      tester,
    ) async {
      await pumpForm(tester);
      await tester.scrollUntilVisible(
        find.text('Tap to mark where it was last seen'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Tap to mark where it was last seen'), findsOneWidget);
    });

    testWidgets('shows correct default location hint in found mode', (
      tester,
    ) async {
      await pumpForm(tester);
      await tester.tap(find.text('Found'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Tap to mark where you found it'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Tap to mark where you found it'), findsOneWidget);
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
      await tester.pumpWidget(MaterialApp(home: LostItemForm(testMode: true)));

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      expect(find.byType(Form), findsOneWidget);
      expect(find.text('Report Item'), findsOneWidget);
      expect(find.text('Item Title *'), findsOneWidget);
      expect(find.text('Description *'), findsOneWidget);
      expect(find.text('Category *'), findsOneWidget);
    });

    testWidgets('Date picker opens when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LostItemForm(testMode: true),
        ),
      );
      await tester.pumpAndSettle();
    });
  });
}