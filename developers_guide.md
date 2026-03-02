# Developer Guidelines
**Important:** The following set up instructions and development environment are intended strictly for iOS and Android mobile platforms. Desktop or web configurations are not supported for this specific project.
These guidelines are intended for developers who wish to contribute to the Valuables project. For easier navigation, use the table of contents below:

* [Setting Up](#setting-up)
    * [Directory Layout](#directory-layout)
    * [Environment Setup](#environment-setup)
* [Repo Setup](#repo-setup)
    * [iOS Configuration](#ios)
    * [Android Configuration](#android)
* [Running the App](#running-the-app)
* [Testing](#testing)
    * [Running Tests](#running-tests)
    * [Adding New Tests](#adding-tests)
* [Release Procedures](#release-procedures)
* [CI/CD & Coverage](#continuous-integration-ci)

      
## Setting Up
Install the following before cloning the repository.

Install Flutter from the official docs: https://docs.flutter.dev/get-started/install

This project requires:

|      Tool            | Required Version |
|----------------------|------------------|
|Dart SDK              |           ^3.10.7|
|Flutter               |               ---|
|XCode (ios/macOS      |             15.0+|
|CocoaPods (ios/macOS) |           1.14.0+|
|Android Studio        |    Latest version|
|Android Emulator      |Android Virtual Device API 33+|

After installing flutter, you can verify your environment is healthy using
```
flutter doctor
```

The project is hosted in a single repository. Clone it and navigate to the application directory
```
git clone https://github.com/chan-anni/valuables.git
cd valuables-app
```
### Directory Layout
When developing you will mostly work in valuables-app/lib/
```
valuables/
├── .github/workflows/       # Automated CI/CD (Testing & Coverage)
├── Status-Reports/          # Project management & weekly updates
│
├── valuables-app/           # Root of the Flutter project
│   ├── lib/                 # MAIN SOURCE CODE
│   │    ├── screens/        # UI: Maps, Forms, Lists
│   │    ├── models/         # Data logic & Supabase structures
│   │    └── main.dart       # App entry point
│   ├── test/                # TEST SUITE (Mirrors 'lib' structure)
│   │    ├── screens/        # Widget tests for UI components
│   │    └── unit/           # Logic and helper tests
|   ├── ios/                 # iOS specific files -- AppDelegate goes in here
|   ├── android/             # Android specific files -- AndroidManifest goes in here
│   ├── pubspec.yaml         # Dependencies (Supabase, Dotenv, etc.)
│   └── .env                 # Local secrets (not tracked in Git)
│
└── README.md                # Entry point for documentation
```
All contributions should be made onto a new branch which later gets merged into the developing branch. Main holds release code only.
### Environment Setup

This project uses flutter_dotenv to manage secrets. A .env file is required at the project root.

Add the following keys (get values from a team member):
```
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
GOOGLE_MAP_KEY=ios_or_android_key
GOOGLE_CLIENT_ID=client_id
GOOGLE_SERVER_CLIENT_ID=server_client_id
```

Google Maps — platform-level key registration

google_maps_flutter requires the API key to be registered natively on each platform, in addition to .env.
#### Android
Add inside <application> in android/app/src/main/AndroidManifest.xml (you may have to make this file). Replace the API key in the file in on the line "android:value="API_KEY_HERE":
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
Add ios/Runner/AppDelegate.swift (you may have to make this file). Replace the API key where it says "Google Maps API Key here":
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

## Building the Project

Run the following command fetch all packages needed from the pubspec.yaml.
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
Every time packages change, you should run the following to keep updated:
```
flutter clean
flutter pub get
```
There are two options to where you can run the app:

### Using an Emmulator

**iOS emmulator**

Ensure you already have XCode installed on your computer and set up. For detailed instructions, we recommend you follow the [Flutter docs for iOS development](https://docs.flutter.dev/platform-integration/ios/setup). Then run the following command: 
```
open -a Simulator
```
This starts the simmulator. From there you should be able to pick which type of device you want to use. Then, when running the flutter project you should be able to have choose the emmulator.

### Using Your Physical Device

To run the app on a physical device, you need a data transfer cable (USB) that connects to your phone and computer.

**Android:**
1. On your Android device, [enable developer options](https://stackoverflow.com/questions/54444538/how-do-i-run-test-my-flutter-app-on-a-real-device). This may vary slightly across Android versions, but should involve pressing the **Build Number** option seven times.
2. A "Developer Options" option should come up, allowing you to "enable USB Debugging.
3. Plug in your device to the computer using the USB cable. You may see a pop-up that tells you the device is connected.
4. Run the following command to check your devices for Flutter to run on:
```
   flutter devices
```
Then, when you run your app, it should allow you to select your specific Android app to run on. 

Another way you can configure your app is by installing the Flutter, the Flutter extension for VS Code and Android SDK. 
**iOS**

Similarily to when running the iOS simmulator, you want to have Xcode installed and set up. For detailed instructions, we recommend you follow the [Flutter docs for iOS development](https://docs.flutter.dev/platform-integration/ios/setup). You will need an Apple ID or sign up with a developer accound. Once you have configured Xcode's iOS tooling, do the following.

In Xcode: 
1. Open ios/Runner .xcworkspace
2. Select the Runner project in the left sidebar and go to the Signing & Capabilities tab, and select a "Team" (select your Apple ID)

Then on your phone:
1. Connect your iOS device to the computer using a USB cable. This should cause a pop-up to appear asking to trust the computer. Click **Trust**.
2. Apple requires developer mode to run the app. Navigate to on Settings > Privacy & Security > Developer Mode. 
3. Tap to toggle Developer Mode to On.
4. Restart the device
5. When the prompt to turn on developer mode appears, tap Turn On.


## Testing 
### Running Tests
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

### Adding Tests
All tests files must end in _test.dart (e.g main_test.dart) for the runner to recognize them. 
The test folder should mirror the lib/ directory. 
In test files themselves, use test() for logic and testWidgets() for UI components. 
Tests requiring Supabase interaction may require a valid .env file or will use mocked responses defined in the test/ directory.

## Release Procedures
Update Versioning: Increment the version and build number in pubspec.yaml (e.g., version: 1.0.1+2) and tag the release as well in git.

Documentation: Ensure any new features are updated in the user-facing documentation.

Formatting: Run the following to ensure the code is formatted properly and readable:
```flutter format <you file path here>```

## Continuous Integration (CI)
We use GitHub Actions to automate the validation of every pull request and push to the main and developing branches.

**Automated Checks**

Whenever you submit a Pull Request, the following checks are triggered automatically:

Static Analysis: The pipeline runs flutter analyze to catch potential bugs, style issues, and type mismatches.

Unit & Widget Tests: All tests in the test/ directory are executed using flutter test.

Test Coverage: A coverage report is generated to ensure that new code is adequately tested.
