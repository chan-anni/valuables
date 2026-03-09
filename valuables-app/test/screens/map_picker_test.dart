import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuables/screens/map_picker_screen.dart';
import 'package:valuables/app_config.dart';

// Prevent Google Maps platform channel errors in widget tests
void _mockMapChannel() {
  const channel = MethodChannel('plugins.flutter.io/google_maps');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async => null);
}

void main() {
  setUp(() {
    try {
      AppConfig.placesApiKey = 'test-api-key';
    } catch (_) {
      // AppConfig just needs to be set to something
    }
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

  testWidgets('shows default location prompt in bottom panel', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MapPickerScreen()));
    await tester.pump();

    expect(find.text('Tap on the map to select a location'), findsOneWidget);
  });

  testWidgets('search field accepts text input', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MapPickerScreen()));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Seattle');
    await tester.pump();

    expect(find.text('Seattle'), findsOneWidget);
  });
}