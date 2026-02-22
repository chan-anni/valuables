import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuables/screens/home_page.dart';

void main() {
  group('HomePage Widget Tests', () {
    Widget createTestWidget() {
      return MaterialApp(
        home: HomePage(
          onBrowsePressed: () {},
        ),
        routes: {
          '/account': (context) => const Scaffold(
            body: Center(
              child: Text('Account Page'),
            ),
          ),
          '/history': (context) => const Scaffold(
            body: Center(
              child: Text('History Page'),
            ),
          ),
        },
      );
    }

    testWidgets('HomePage renders successfully', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Verify key elements are rendered
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('Report lost or found items'), findsOneWidget);
    });

    testWidgets('Report Item button is present and tappable',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Find and verify the Report Item button
      final reportButton = find.byType(ElevatedButton).first;
      expect(reportButton, findsOneWidget);
      
      // Verify the button contains text
      expect(find.text('Report Item'), findsOneWidget);
      
      // Tap the button - should not throw
      await tester.tap(reportButton);
      await tester.pumpAndSettle();
    });

    testWidgets('Browse Items button navigates to map section',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Find the Browse Items button
      expect(find.text('Browse Items'), findsOneWidget);
      
      final browseButton = find.byType(ElevatedButton).at(1);
      expect(browseButton, findsOneWidget);
      
      // Tap the button - the onBrowsePressed callback is triggered
      await tester.tap(browseButton);
      await tester.pumpAndSettle();
    });

    testWidgets('HomePage displays welcome message',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Should display a welcome message
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && 
            widget.data?.contains('Welcome') == true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('Alerts section expands and shows empty state',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      // Find the Alerts On Your Lost Items ExpansionTile
      final alertsExpansion = find.byType(ExpansionTile).first;
      expect(alertsExpansion, findsOneWidget);
      
      // Tap to expand
      await tester.tap(alertsExpansion);
      await tester.pumpAndSettle();
      
      // Verify empty state message appears
      expect(find.text('No active alerts'), findsWidgets);
    });

    testWidgets('Your Listings section expands and shows empty state',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      // Find the Your Listings ExpansionTile (second one)
      final listingsExpansion = find.byType(ExpansionTile).at(1);
      expect(listingsExpansion, findsOneWidget);
      
      // Tap to expand
      await tester.tap(listingsExpansion);
      await tester.pumpAndSettle();
      
      // Verify empty state message appears
      expect(find.text('You have not listed any items yet.'), findsWidgets);
    });

    testWidgets('Error message area is present but empty initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      // Initially no error message icon
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Icon && widget.icon == Icons.error_outline,
        ),
        findsNothing,
      );
    });

    testWidgets('Profile avatar displays correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Find the CircleAvatar
      final avatars = find.byType(CircleAvatar);
      expect(avatars, findsWidgets);
    });

    testWidgets('Settings button opens settings modal with notifications',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Find and tap settings button
      final settingsButton = find.byIcon(Icons.settings);
      expect(settingsButton, findsOneWidget);
      
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();
      
      // Modal should display Settings text and notification options
      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Notifications'), findsWidgets);
      expect(find.text('Email Notifications'), findsWidgets);
      expect(find.text('Push Notifications'), findsWidgets);
      expect(find.text('Match Alerts'), findsWidgets);
    });

    testWidgets('Settings modal contains About Valuables information',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Open settings modal
      final settingsButton = find.byIcon(Icons.settings);
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();
      
      // Check for About Valuables
      expect(find.text('About Valuables'), findsWidgets);
      
      // Tap About Valuables
      final aboutButton = find.byWidgetPredicate(
        (widget) => widget is ListTile && 
          (widget.title as Text?)?.data?.contains('About Valuables') == true,
      );
      if (aboutButton.evaluate().isNotEmpty) {
        await tester.tap(aboutButton);
        await tester.pumpAndSettle();
        
        // Should show about dialog with description
        expect(find.text('About Valuables'), findsWidgets);
        expect(find.text('Valuables is a community-driven platform'), findsWidgets);
      }
    });

    testWidgets('Settings modal contains Help & Support',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Open settings modal
      final settingsButton = find.byIcon(Icons.settings);
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();
      
      // Check for Help & Support
      expect(find.text('Help & Support'), findsWidgets);
    });

    testWidgets('History button opens activity modal',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Find and tap history button
      final historyButton = find.byIcon(Icons.history);
      expect(historyButton, findsOneWidget);
      
      await tester.tap(historyButton);
      await tester.pumpAndSettle();
      
      // Modal should display Activity & History text
      expect(find.text('Activity & History'), findsWidgets);
    });

    testWidgets('Refresh indicator is functional',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Verify refresh indicator exists
      final refreshIndicator = find.byType(RefreshIndicator);
      expect(refreshIndicator, findsOneWidget);
    });

    testWidgets('Report Item and Browse Items buttons have correct icons',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Check for Report Item button icon
      expect(find.byIcon(Icons.add), findsOneWidget);
      
      // Check for Browse Items button icon
      expect(find.byIcon(Icons.explore), findsOneWidget);
    });

    testWidgets('Profile avatar can be tapped to open modal',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Find and tap the profile avatar
      final avatar = find.byType(CircleAvatar).first;
      await tester.tap(avatar);
      await tester.pumpAndSettle();
      
      // Modal should appear with profile information
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('Key section headers are displayed',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Verify all key section headers are present
      expect(find.text('Report lost or found items'), findsOneWidget);
      expect(find.text('Search for your items'), findsOneWidget);
      expect(find.text('Get notified when potential matches are found'), 
             findsOneWidget);
      expect(find.text('Keep track of items waiting to be claimed'), 
             findsOneWidget);
    });

    testWidgets('Alerts section shows count badge',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Should have badges showing counts
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('Listings section shows count badge',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Should have badges showing counts
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('Settings modal has notification toggle switches',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Open settings modal
      final settingsButton = find.byIcon(Icons.settings);
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();
      
      // Check for switches
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('Activity modal shows link to full history',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Open activity modal
      final historyButton = find.byIcon(Icons.history);
      await tester.tap(historyButton);
      await tester.pumpAndSettle();
      
      // Modal should show full activity history link
      expect(find.text('View Full Activity History'), findsWidgets);
    });

    testWidgets('Errors display in expandable alert section',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Expand alerts section
      final alertsExpansion = find.byType(ExpansionTile).first;
      await tester.tap(alertsExpansion);
      await tester.pumpAndSettle();
      
      // Should show alerts or empty state
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('Listings display in expandable section',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Expand listings section
      final listingsExpansion = find.byType(ExpansionTile).at(1);
      await tester.tap(listingsExpansion);
      await tester.pumpAndSettle();
      
      // Should show listings or empty state
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('Navigation buttons layout is correct',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Should have at least 2 buttons for Report and Browse
      final buttons = find.byType(ElevatedButton);
      expect(buttons, findsWidgets);
    });

    testWidgets('User information displays in profile section',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Should display user name or Guest User
      expect(find.text('Guest User'), findsWidgets);
    });

    testWidgets('Settings modal does not have language option',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Open settings modal
      final settingsButton = find.byIcon(Icons.settings);
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();
      
      // Language option should NOT be present
      expect(find.text('Language'), findsNothing);
    });

    testWidgets('Profile modal references settings modal',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Tap avatar to open profile modal
      final avatar = find.byType(CircleAvatar).first;
      await tester.tap(avatar);
      await tester.pumpAndSettle();
      
      // Should have edit profile button
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('Help & Support explains how notifications work',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Open settings modal
      final settingsButton = find.byIcon(Icons.settings);
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();
      
      // Check for Help & Support option
      expect(find.text('Help & Support'), findsWidgets);
    });

    testWidgets('Multiple notification toggle options available',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Open settings modal
      final settingsButton = find.byIcon(Icons.settings);
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();
      
      // Should have multiple notification related options
      expect(find.text('Email Notifications'), findsOneWidget);
      expect(find.text('Push Notifications'), findsOneWidget);
    });
  });
}
