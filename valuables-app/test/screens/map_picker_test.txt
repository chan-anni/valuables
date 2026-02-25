import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuables/screens/map_picker_screen.dart';
import 'package:geocoding/geocoding.dart';

// Prevent Google Maps platform channel errors in widget tests
void _mockMapChannel() {
  const channel = MethodChannel('plugins.flutter.io/google_maps');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async => null);
}

void main() {
  setUp(() {
    _mockMapChannel();
  });

  testWidgets('renders MapPickerScreen basic UI', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MapPickerScreen()));
    await tester.pumpAndSettle();

    // AppBar title
    expect(find.text('Pick Location'), findsOneWidget);

    // Search field hint
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search for a location...'), findsOneWidget);

    // Current location FAB exists
    expect(find.byIcon(Icons.my_location), findsOneWidget);

    // Confirm button exists
    expect(
      find.widgetWithText(FilledButton, 'Confirm Location'),
      findsOneWidget,
    );
  });

  testWidgets('confirm button is disabled when no initial location provided', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MapPickerScreen()));
    await tester.pumpAndSettle();

    final finder = find.widgetWithText(FilledButton, 'Confirm Location');
    final btn = tester.widget<FilledButton>(finder);
    // onPressed should be null when no location picked
    expect(btn.onPressed, isNull);
  });

  testWidgets(
    'confirm button enabled when initial location provided and pops route',
    (tester) async {
      // Wrap with a host that can push the MapPickerScreen so popping works
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MapPickerScreen(
                        initialLat: 47.6,
                        initialLng: -122.33,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Open the picker
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Confirm button should now be enabled because initial location was provided
      final finder = find.widgetWithText(FilledButton, 'Confirm Location');
      expect(finder, findsOneWidget);
      final btn = tester.widget<FilledButton>(finder);
      expect(btn.onPressed, isNotNull);

      // Tap confirm and ensure the route pops back to the host
      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(find.text('Open'), findsOneWidget);
    },
  );

  testWidgets('search results display and selecting one updates picked location', (
    tester,
  ) async {
    final loc = Location(
      latitude: 47.6,
      longitude: -122.33,
      timestamp: DateTime.now(),
    );

    // Build the key exactly as _getLocationName() does, using the actual
    // double values from the Location object
    final key = '${loc.latitude},${loc.longitude}';

    await tester.pumpWidget(
      MaterialApp(
        home: MapPickerScreen(
          initialSearchResults: [loc],
          initialLocationNames: {key: 'Test Place'},
        ),
      ),
    );
    await tester
        .pump(); // using pump() not pumpAndSettle() since GoogleMap never settles

    // The search result should be visible in the dropdown
    expect(find.text('Test Place'), findsOneWidget);

    // Tap the search result to select it
    await tester.tap(find.text('Test Place'));
    await tester.pump();

    expect(
      find.text(
        '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows default location prompt in bottom panel', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MapPickerScreen()));
    await tester.pump();

    expect(find.text('Tap on the map to select a location'), findsOneWidget);
  });

  testWidgets('injected search results appear in dropdown', (tester) async {
    final loc = Location(
      latitude: 47.6,
      longitude: -122.33,
      timestamp: DateTime.now(),
    );
    final key = '${loc.latitude},${loc.longitude}';

    await tester.pumpWidget(
      MaterialApp(
        home: MapPickerScreen(
          initialSearchResults: [loc],
          initialLocationNames: {key: 'Pike Place Market'},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Pike Place Market'), findsOneWidget);
  });

  testWidgets('search field accepts text input', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MapPickerScreen()));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Seattle');
    await tester.pump();

    expect(find.text('Seattle'), findsOneWidget);
  });
}
