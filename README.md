# Valuables

Valuables is a location-based lost and found platform designed to connect item owners with finders through an intuitive visual map interface. By anchoring discovery to specific locations, Valuables makes it easier to report found items, search for lost belongings, and coordinate safe item returns.

## Project Goals
- **Simplify the lost and found process:** Streamline the finding process by having everything in one place, ready to check in your hand.
- **Visual Discovery:** Replace text and image-heavy lists with an easy-to-use map-based interface, allowing users to instantly see what has been found in their vicinity.
- **Safe Retrieval:** Allow secure communication between an item finder and its original owner without exposing private details.

For more detailed documentation and requirements, please refer to this document: [Living Document](https://docs.google.com/document/d/13QQbWXSVayHq30wGUSwdVvV63Vgm0ihH9rF6P2hdlEw/edit?usp=sharing)

## Repository Layout
Developer's note: our main code lies in the 'developing' branch, while code for releases will be pulled in from 'developing' to 'main'.
```text
valuables/
├── .github/workflows        # CI workflow 
├── Status-Reports/          # Weekly progress updates
│
├── valuables-app/           # Main Flutter application source code
│   ├── android/             # Android-specific configuration
│   ├── ios/                 # iOS-specific configuration
│   ├── lib/                 # Main application logic (Dart code)
|   |    ├── screens/         # Individual screens (form, map, etc.)
│   ├── test/                # Unit and widget tests
|   |    ├── screens/         # Specific tests for individual screens (form screen, map, etc.)
│   ├── web/                 # Web build configuration
│   ├── macos/               # macOS build configuration
│   ├── pubspec.yaml         # Project dependencies and settings            
│
└── README.md                # Top-level project overview

```
## Developer's Guide

* [Prerequisites](#prerequisites)
* [Environment Setup](#environment-setup)
* [Repo Setup](#repo-setup)
    * [iOS Configuration](#iOS)
    * [Android Configuration](#android)
* [Running the App](#running-the-app)
* [Testing](#testing)
* [CI/CD & Coverage](#ci)

### Prerequisites

Install the following before cloning the repository.

Install Flutter from the official docs: https://docs.flutter.dev/get-started/install

This project requires:

|      Tool            | Required Version |
|----------------------|------------------|
|Dart SDK              |           ^3.10.7|
|Flutter               |               ---|
|XCode (ios/macOS      |             15.0+|
|CocoaPods (ios/macOS) |           1.14.0+|

After installing flutter, you can verify your environment is healthy using
```
flutter doctor
```

### Environment Setup

This project uses flutter_dotenv to manage secrets. A .env file is required at the project root.

Add the following keys (get values from a team member):
```
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

Google Maps — platform-level key registration

google_maps_flutter requires the API key to be registered natively on each platform, in addition to .env.
#### Android
Add inside <application> in android/app/src/main/AndroidManifest.xml:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="valuables"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <meta-data 
            android:name="com.google.android.geo.API_KEY"
            android:value="API_KEY_HERE"
            />
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>

```
DO NOT commit this file. It should already be in the .gitignore. 
### iOS
Add/Create ios/Runner/AppDelegate.swift
```swift

import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain 
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GMSServices.provideAPIKey("Google Maps API Key here")
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```
DO NOT commit this file. It should already be in the .gitignore. 
### Repo Setup

Run the following:
```
git clone https://github.com/chan-anni/valuables.git
cd valuables-app
```
Then, run the following flutter command. This reads pubspec.yaml and fetches all packages needed.
```
flutter pub get
```
For iOS native setup (macOS only) you will also need to use 'pod' for running. Use the following commands
```
cd ios
pod install
```
### Running the App
Copy the following command into the terminal. Make sure you are in the valuables-app folder.
```
flutter run
```
### Testing 
All tests live in test/, mirroring the structure of lib/. Test files must end in _test.dart.

Run all tests
```
flutter test
```
Run a specific test file
```
flutter test test/services/location_service_test.dart
```
Run tests will code coverage
```
flutter test --coverage
```
This creates/overwrites coverage/lcov.info. 

### CI
Every push to main or developing, and every PR targeting those branches, triggers our GitHub Actions pipeline. Our CI does the following:

Checks out the code
Sets up Flutter (stable channel, Dart ^3.10.7)
Creates the .env file from GitHub Secrets
Runs flutter pub get
Runs flutter analyze — static analysis and lint
Runs flutter test --coverage — full test suite with coverage output
Uploads coverage/lcov.info to Codecov

Viewing results
Go to your PR on GitHub -> scroll to Checks -> click any job name to see full logs. A Codecov comment is also posted automatically on each PR to show information.


## Use Case

As of the Beta version, the current app can perform the core feature of submitting a 'found item' claim. 
The use case would be the following:

**User Goal**: A finder wants to quickly report someone's lost accessory that they found so the owner can locate it on the map.
**Success Conditions**: The item is logged into the database, and it shows on the map interface.
**Step by Step Flow**
1. User clicks on the 'Report Item' form and clicks on the 'Found' item type.
2. System loads up the form.
3. User fills out the form with a title, corresponding category, and chooses a date for when they found the item. The user then clicks the location button.
4. System loads up a map screen where the user can type in an address in the search bar, use their current location, or click on the map to place a pin.
5. User clicks on a location and then confirms the location.
6. System loads back to the form page with the location now chosen.
7. User clicks on the upload image button and uploads an image.
8. User clicks submit to the form.
9. System confirms and takes the user back to the home page. Item information is loaded into the backend database. An item marker appears on the map page.
